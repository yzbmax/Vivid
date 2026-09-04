/**
 * EXIF 参数纯格式化与计算工具（无设备依赖，纯逻辑）。
 */

/** 解析 EXIF 数值（支持浮点数以及如 "85/1" 或 "267/100" 的有理数分数） */
export function parseExifNumber(val: string): number | null {
  if (!val || val.trim().length === 0) {
    return null;
  }
  const clean = val.trim();
  if (clean.includes('/')) {
    const parts = clean.split('/');
    if (parts.length === 2) {
      const num = parseFloat(parts[0]);
      const den = parseFloat(parts[1]);
      if (!isNaN(num) && !isNaN(den) && den !== 0) {
        return num / den;
      }
    }
  }
  const direct = parseFloat(clean);
  return isNaN(direct) ? null : direct;
}

/** 格式化焦距：优先采用 35mm 等效焦距（行业标准）；若无等效焦距才回退物理焦距 */
export function formatFocalLength(focal35: string, focalPhysical: string): string {
  const num35 = parseExifNumber(focal35);
  if (num35 !== null && num35 > 0) {
    return `${Math.round(num35)}mm`;
  }
  const numPhys = parseExifNumber(focalPhysical);
  if (numPhys !== null && numPhys > 0) {
    if (numPhys >= 20) {
      return `${Math.round(numPhys)}mm`;
    }
    const rounded = Math.round(numPhys * 10) / 10;
    return `${rounded}mm`;
  }
  return '';
}

/** 格式化光圈值（如 "2.67", "267/100" -> "f/2.67"） */
export function formatFNumber(fNumber: string): string {
  const num = parseExifNumber(fNumber);
  if (num !== null && num > 0) {
    const str = num.toFixed(2).replace(/\.?0+$/, '');
    return `f/${str}`;
  }
  const clean = fNumber.trim();
  if (clean.length > 0) {
    return clean.startsWith('f/') ? clean : `f/${clean}`;
  }
  return '';
}

/** 格式化快门时间（如 "1/10", "0.1", "2" -> "1/10s", "2s"） */
export function formatExposureTime(expTime: string): string {
  let clean = expTime.trim();
  if (clean.length === 0) {
    return '';
  }
  // 清理可能自带的 sec. 或 sec 或 s，避免出现 1/1000 sec.s
  clean = clean.replace(/\s*sec\.?s?/gi, '').replace(/\s*s$/gi, '').trim();
  if (clean.includes('/')) {
    return `${clean}s`;
  }
  const sec = parseExifNumber(clean);
  if (sec !== null && sec > 0) {
    if (sec >= 1) {
      const sStr = sec.toFixed(1).replace(/\.0$/, '');
      return `${sStr}s`;
    }
    const reciprocal = Math.round(1 / sec);
    return `1/${reciprocal}s`;
  }
  return `${clean}s`;
}

/** 格式化 ISO 感光度（如 "10492" -> "ISO10492"） */
export function formatIso(iso: string): string {
  const clean = iso.trim();
  if (clean.length === 0) {
    return '';
  }
  return clean.toUpperCase().startsWith('ISO') ? clean.toUpperCase() : `ISO${clean}`;
}

/** 格式化 EXIF 原始时间（如 "2026:09:03 16:30:00" -> "2026.09.03 16:30"） */
export function formatExifDateTime(dateTime: string): string {
  const clean = dateTime.trim();
  if (clean.length === 0) {
    return '';
  }
  const parts = clean.split(' ');
  if (parts.length >= 2) {
    const datePart = parts[0].replace(/:/g, '.');
    const timeParts = parts[1].split(':');
    const timePart = timeParts.length >= 2 ? `${timeParts[0]}:${timeParts[1]}` : parts[1];
    return `${datePart} ${timePart}`;
  }
  return clean;
}
