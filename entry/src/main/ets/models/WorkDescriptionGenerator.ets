import { AdjustParams } from './EditModels';

/**
 * 作品描述（案卷批注）自动生成器。
 *
 * 根据调色参数 + 图片尺寸生成古风描述文字。
 * 纯函数，无副作用。
 */

/** 曝光/亮度 → 光影描述 */
function describeLightness(exposure: number, brightness: number): string {
  const combined = exposure * 0.6 + brightness * 0.4;
  if (combined > 30) {
    return '光影明快，通篇透亮';
  } else if (combined > 10) {
    return '光影柔和，层次分明';
  } else if (combined > -10) {
    return '光影均衡，不偏不倚';
  } else if (combined > -30) {
    return '明暗含蓄，氛围沉郁';
  } else {
    return '暗调浓厚，深沉厚重';
  }
}

/** 对比度 → 反差描述 */
function describeContrast(contrast: number): string {
  if (contrast > 30) {
    return '反差强烈，棱角分明';
  } else if (contrast > 10) {
    return '对比适度，层次清晰';
  } else if (contrast > -10) {
    return '反差平和，过渡均匀';
  } else if (contrast > -30) {
    return '层次柔和，边界模糊';
  } else {
    return '色调绵软，浑然一体';
  }
}

/** 饱和度 → 色彩描述 */
function describeSaturation(saturation: number): string {
  if (saturation > 30) {
    return '色彩浓郁，鲜艳夺目';
  } else if (saturation > 10) {
    return '色泽饱满，富有生气';
  } else if (saturation > -10) {
    return '色彩自然，不事雕琢';
  } else if (saturation > -30) {
    return '素雅清淡，意趣幽远';
  } else {
    return '近于水墨，素净空灵';
  }
}

/** 宽高比 → 构图描述 */
function describeComposition(width: number, height: number): string {
  if (width <= 0 || height <= 0) {
    return '';
  }
  const ratio = width / height;
  if (ratio > 1.6) {
    return '长卷形制，气势开阔';
  } else if (ratio > 1.2) {
    return '横幅构图，视野舒展';
  } else if (ratio > 0.85) {
    return '方帧端正，稳重大方';
  } else if (ratio > 0.6) {
    return '竖幅构图，适宜细观';
  } else {
    return '窄长竖帧，别具一格';
  }
}

/**
 * 生成作品描述。
 *
 * @param adjustments 调色参数
 * @param width 图片宽度（0 表示未知）
 * @param height 图片高度（0 表示未知）
 * @returns 古风案卷批注文字
 */
export function generateWorkDescription(
  adjustments: AdjustParams,
  width: number,
  height: number
): string {
  const parts: string[] = [];

  // 光影描述
  parts.push(describeLightness(adjustments.exposure, adjustments.brightness));

  // 反差描述
  parts.push(describeContrast(adjustments.contrast));

  // 色彩描述
  parts.push(describeSaturation(adjustments.saturation));

  // 构图描述
  const composition = describeComposition(width, height);
  if (composition.length > 0) {
    parts.push(composition);
  }

  // 组合为一句
  let result = '此帧' + parts[0] + '，' + parts[1] + '，' + parts[2] + '。';
  if (parts.length > 3) {
    result += parts[3] + '。';
  }

  return result;
}
