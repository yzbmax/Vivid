import { BorderState } from '../../../models/SharedContracts';
import { BorderGeometry } from './BorderLayoutResolver';
import { sanitizeBorderState } from './BorderState';
import { Theme } from '../../../components/common/Theme';

/** 在 Canvas 上绘制圆角矩形闭合路径（供裁剪、描边或填充）。 */
export function drawRoundedRectPath(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  x: number, y: number, w: number, h: number, r: number
): void {
  const radius = Math.max(0, Math.min(r, w / 2, h / 2));
  if (radius <= 0) {
    context.rect(x, y, w, h);
    return;
  }
  context.beginPath();
  context.moveTo(x + radius, y);
  context.arcTo(x + w, y, x + w, y + h, radius);
  context.arcTo(x + w, y + h, x, y + h, radius);
  context.arcTo(x, y + h, x, y, radius);
  context.arcTo(x, y, x + w, y, radius);
  context.closePath();
}

/** 预览与导出共用像素单位绘制过程；不绘制照片，不覆盖已有调色、贴纸或文字。 */
export function paintBorder(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry, border: BorderState, scale: number = 1
): void {
  if (geometry.templateId === 'none' || scale <= 0) {
    return;
  }
  const safe = sanitizeBorderState(border);
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const spread = geometry.shadowSpread * scale;
  context.save();
  // 实色衬底使 JPEG 与 PNG 的阴影区域保持一致；画中画、同调画报与悬浮水印不填充不透明实色底。
  if (geometry.templateId !== 'watermark_blur_pip' &&
      geometry.templateId !== 'watermark_centered_specs' &&
      geometry.templateId !== 'watermark_harmonic_editorial' &&
      geometry.templateId !== 'watermark_minimal_keyvalue' &&
      geometry.templateId !== 'watermark_overlay') {
    context.fillStyle = Theme.PAPER_SURFACE;
    context.fillRect(0, 0, w, h);
    if (spread > 0) {
      context.shadowColor = 'rgba(36,25,24,' + (safe.shadowStrength * 0.6) + ')';
      context.shadowBlur = spread;
      context.shadowOffsetY = spread * 0.3;
    }
    context.fillStyle = 'rgba(' + ((safe.colorArgb >>> 16) & 255) + ',' + ((safe.colorArgb >>> 8) & 255)
      + ',' + (safe.colorArgb & 255) + ',' + ((safe.colorArgb >>> 24) / 255) + ')';
    context.fillRect(spread, spread, w - 2 * spread, h - 2 * spread);
  }
  context.shadowBlur = 0;
  context.shadowOffsetY = 0;
  context.shadowColor = 'rgba(0,0,0,0)';
  for (const decoration of geometry.decorations) {
    const r = decoration.rect;
    // 卷轴装饰的原点是外框内缘；投影在其外围扩展。
    const offset = geometry.templateId === 'scroll_mount' ? spread : 0;
    const x = r.x * scale + offset;
    const y = r.y * scale + offset;
    if (decoration.kind === 'filmNumber') {
      context.fillStyle = Theme.PAPER_SURFACE;
      context.font = Math.max(1, r.height * scale) + 'px monospace';
      context.textAlign = 'center';
      context.textBaseline = 'middle';
      context.fillText('VIVID 01', x + r.width * scale / 2, y + r.height * scale / 2);
    } else {
      context.fillStyle = decoration.kind === 'sprocket' ? Theme.PAPER_SURFACE : Theme.SEAL_RED;
      context.fillRect(x, y, r.width * scale, r.height * scale);
    }
  }
  if (geometry.templateId === 'camera_watermark') {
    paintWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_centered_specs') {
    paintCenteredSpecsWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_harmonic_editorial') {
    paintHarmonicEditorialWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_minimal_keyvalue') {
    paintMinimalKeyvalueWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_master_grid') {
    paintMasterGridWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_blur_pip') {
    paintBlurPipWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_cinematic') {
    paintCinematicWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_retro_film') {
    paintRetroFilmWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_overlay') {
    paintOverlayWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_nordic_gallery') {
    paintNordicGalleryWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_editorial_mag') {
    paintEditorialMagWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_contact_sheet') {
    paintContactSheetWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_oriental_seal') {
    paintOrientalSealWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_travel_stamp') {
    paintTravelStampWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_travel_postcard') {
    paintTravelPostcardWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_gradient_frame') {
    paintGradientFrameWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_leather_badge') {
    paintLeatherBadgeWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_mint_film') {
    paintMintFilmWatermark(context, geometry, safe, scale);
  } else if (geometry.templateId === 'watermark_slim_white') {
    paintSlimWhiteWatermark(context, geometry, safe, scale);
  }
  context.restore();
}

/** 计算 Logo 徽标宽度 */
function getLogoBadgeWidth(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  logo: string,
  size: number
): number {
  if (logo === 'zeiss') {
    const badgeH = Math.round(size * 1.15);
    return badgeH;
  }
  if (logo === 'leica') {
    const radius = Math.round(size * 0.6);
    return radius * 2;
  }
  if (logo === 'nikon') {
    const badgeH = Math.round(size * 1.05);
    return Math.round(badgeH * 1.6);
  }
  if (logo === 'sony') {
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('SONY').width;
  }
  if (logo === 'apple') {
    return Math.round(size * 0.85);
  }
  if (logo === 'canon') {
    context.font = `bold ${Math.round(size * 0.9)}px serif`;
    return context.measureText('Canon').width;
  }
  if (logo === 'hasselblad') {
    context.font = `bold italic ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('HASSELBLAD').width + Math.round(size * 0.5);
  }
  if (logo === 'fujifilm') {
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    const fujiW = context.measureText('FUJI').width;
    const filmW = context.measureText('FILM').width;
    return fujiW + Math.round(size * 0.45) + filmW;
  }
  if (logo === 'xiaomi') {
    const badgeH = Math.round(size * 1.1);
    return badgeH;
  }
  if (logo === 'samsung') {
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('SAMSUNG').width;
  }
  if (logo === 'vivo') {
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('vivo').width;
  }
  if (logo === 'oppo') {
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('oppo').width;
  }
  if (logo === 'honor') {
    context.font = `bold ${Math.round(size * 0.8)}px sans-serif`;
    return Math.round(size * 0.85) + context.measureText('HONOR').width + 4;
  }
  if (logo === 'master') {
    context.font = `italic 600 ${Math.round(size * 0.85)}px sans-serif`;
    return context.measureText('Master Series').width;
  }
  return 0;
}

/**
 * 检测指定的 Logo 标识是否与机型文本产生品牌名称冲突/重复。
 * 例如：机型为 "SONY ILCE-7"，Logo 为 "sony"，则判定为重复；
 * 此时应保留机型文本（留住和机型字体一样的那一个），去掉独立绘制的 Logo（去掉另一个）。
 */
export function isLogoDuplicatedWithDevice(
  logo: string | null | undefined,
  deviceModel: string | null | undefined
): boolean {
  if (!logo || logo === 'none' || !deviceModel || deviceModel.trim().length === 0) {
    return false;
  }
  const devLower = deviceModel.trim().toLowerCase();
  const logoLower = logo.trim().toLowerCase();

  // Apple 徽标为经典  矢量咬口苹果图标，与 iPhone/iPad 机型天然互补，仅当机型文本仅为 "Apple" 时才判定去重
  if (logoLower === 'apple') {
    return devLower === 'apple' || devLower === '苹果';
  }

  // 映射各 Logo 对应的品牌特征关键词
  const brandKeywords: Record<string, string[]> = {
    'sony': ['sony', '索尼'],
    'canon': ['canon', '佳能'],
    'nikon': ['nikon', '尼康'],
    'fujifilm': ['fujifilm', 'fuji', '富士'],
    'leica': ['leica', '徕卡'],
    'hasselblad': ['hasselblad', '哈苏'],
    'zeiss': ['zeiss', '蔡司'],
    'xiaomi': ['xiaomi', 'redmi', '小米', '红米'],
    'samsung': ['samsung', 'galaxy', '三星'],
    'vivo': ['vivo', 'iqoo'],
    'oppo': ['oppo', 'oneplus', '一加'],
    'honor': ['honor', '荣耀']
  };

  const keywords = brandKeywords[logoLower];
  if (keywords) {
    for (let i = 0; i < keywords.length; i++) {
      if (devLower.includes(keywords[i])) {
        return true;
      }
    }
  } else if (devLower.includes(logoLower)) {
    return true;
  }
  return false;
}

/** 规范化用于水印呈现的机型文本（如在展示 Apple 徽标时规整 "Apple iPhone 15 Pro" 为经典的 "iPhone 15 Pro"） */
function formatWatermarkDeviceText(rawDevice: string, logo: string, hasLogo: boolean): string {
  if (!rawDevice || rawDevice.length === 0) {
    return '';
  }
  if (hasLogo && logo === 'apple' && rawDevice.toLowerCase().startsWith('apple ')) {
    return rawDevice.substring(6).trim();
  }
  return rawDevice;
}

/** 绘制相机水印信息（机型、Logo、拍摄参数、时间）。 */
function paintWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;
  if (bannerH <= 0) {
    return;
  }
  const centerY = photoBottom + bannerH * 0.5;

  const r = (safe.colorArgb >>> 16) & 255;
  const g = (safe.colorArgb >>> 8) & 255;
  const b = safe.colorArgb & 255;
  const luminance = 0.299 * r + 0.587 * g + 0.114 * b;
  const isDark = luminance < 140;

  const textColorPrimary = isDark ? '#F5F5F7' : '#111111';
  const textColorSecondary = isDark ? '#9E9E9E' : '#666666';
  const dividerColor = isDark ? '#555555' : '#D0D0D0';

  const marginX = Math.max(10 * scale, Math.min(24 * scale, w * 0.04));
  const availW = w - 2 * marginX;

  const hasDevice = !!(wm.showDevice && wm.deviceModel && wm.deviceModel.trim().length > 0);
  const deviceModel = hasDevice ? wm.deviceModel.trim() : '';

  // 冲突去重：若机型文本已自带品牌名（如 SONY ILCE-7），留住机型字体文本，去掉重复的独立 Logo 与分隔竖线
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, deviceModel);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const hasParams = !!(wm.showParams && wm.paramsText && wm.paramsText.trim().length > 0);
  const hasTime = !!(wm.showTime && wm.timeText && wm.timeText.trim().length > 0);

  if (!hasDevice && !hasLogo && !hasParams && !hasTime) {
    return;
  }

  // 整理参数文本（统一去除多余空格与可能的冗余 "sec.s"）
  const paramsText = hasParams ? wm.paramsText.trim().replace(/\s*sec\.?s?/gi, 's').replace(/\s+/g, ' ') : '';
  const timeText = hasTime ? wm.timeText.trim() : '';
  const logo = hasLogo ? wm.logo : 'none';
  const displayDevice = formatWatermarkDeviceText(deviceModel, logo, hasLogo);

  const basePrimary = Math.max(9, Math.round(bannerH * 0.22));
  const baseSecondary = Math.max(8, Math.round(bannerH * 0.16));

  // 1. 预估单行左侧与右侧宽度
  context.font = `600 ${basePrimary}px sans-serif`;
  const singleLineDeviceW = hasDevice ? context.measureText(displayDevice).width : 0;
  context.font = `300 ${basePrimary * 0.9}px sans-serif`;
  const singleLineDividerW = (hasDevice && hasLogo) ? (context.measureText('|').width + Math.max(6 * scale, basePrimary * 0.35)) : 0;
  const singleLineLogoW = hasLogo ? getLogoBadgeWidth(context, logo, basePrimary) : 0;
  const singleLineLeftW = singleLineDeviceW + singleLineDividerW + singleLineLogoW;

  context.font = `500 ${baseSecondary}px monospace, sans-serif`;
  const paramsW = hasParams ? context.measureText(paramsText).width : 0;
  context.font = `400 ${Math.max(7, Math.round(baseSecondary * 0.85))}px sans-serif`;
  const timeW = hasTime ? context.measureText(timeText).width : 0;
  const singleLineRightW = Math.max(paramsW, timeW);

  const minGap = Math.max(12 * scale, 12);
  const singleLineNeededW = singleLineLeftW + minGap + singleLineRightW;

  // 2. 决策：是否需要换为双行折叠排版（竖屏/狭窄宽度）
  const isStackedLayout = (singleLineNeededW > availW && bannerH >= 28);

  context.textBaseline = 'middle';

  if (isStackedLayout && (hasDevice || hasLogo)) {
    // ── 竖屏紧凑双行排版 ──
    // 左侧：上行为机型，下行为 Logo；右侧：上行为参数，下行为时间
    // 这样左侧宽度仅为 max(deviceW, logoW)，宽度大幅节省，彻底消除中间重叠！
    const stackPrimary = Math.max(8, Math.round(bannerH * 0.20));
    const stackSecondary = Math.max(7, Math.round(bannerH * 0.15));

    // 计算实际双行最大宽度
    context.font = `600 ${stackPrimary}px sans-serif`;
    const stackDeviceW = hasDevice ? context.measureText(displayDevice).width : 0;
    const stackLogoW = hasLogo ? getLogoBadgeWidth(context, logo, stackPrimary) : 0;
    const stackLeftW = Math.max(stackDeviceW, stackLogoW);

    context.font = `500 ${stackSecondary}px monospace, sans-serif`;
    const stackParamsW = hasParams ? context.measureText(paramsText).width : 0;
    context.font = `400 ${Math.max(7, Math.round(stackSecondary * 0.85))}px sans-serif`;
    const stackTimeW = hasTime ? context.measureText(timeText).width : 0;
    const stackRightW = Math.max(stackParamsW, stackTimeW);

    // 检查是否仍需微缩字号
    let shrinkFactor = 1.0;
    if (stackLeftW + minGap + stackRightW > availW) {
      shrinkFactor = Math.max(0.70, (availW - minGap) / (stackLeftW + stackRightW));
    }

    const curPrimary = Math.max(7, Math.round(stackPrimary * shrinkFactor));
    const curSecondary = Math.max(6, Math.round(stackSecondary * shrinkFactor));

    const topY = centerY - bannerH * 0.18;
    const bottomY = centerY + bannerH * 0.20;

    // 左侧上行：机型
    if (hasDevice) {
      context.fillStyle = textColorPrimary;
      context.font = `600 ${curPrimary}px sans-serif`;
      context.textAlign = 'left';
      context.fillText(displayDevice, marginX, hasLogo ? topY : centerY);
    }

    // 左侧下行：Logo
    if (hasLogo) {
      paintLogoBadge(context, logo, marginX, hasDevice ? bottomY : centerY, curPrimary, textColorPrimary);
    }

    // 右侧
    const rightX = w - marginX;
    context.textAlign = 'right';

    if (hasParams && hasTime) {
      context.fillStyle = textColorPrimary;
      context.font = `500 ${curSecondary}px monospace, sans-serif`;
      context.fillText(paramsText, rightX, topY);

      context.fillStyle = textColorSecondary;
      context.font = `400 ${Math.max(6, Math.round(curSecondary * 0.88))}px sans-serif`;
      context.fillText(timeText, rightX, bottomY);
    } else if (hasParams) {
      context.fillStyle = textColorPrimary;
      context.font = `500 ${curSecondary}px monospace, sans-serif`;
      context.fillText(paramsText, rightX, centerY);
    } else if (hasTime) {
      context.fillStyle = textColorSecondary;
      context.font = `400 ${curSecondary}px sans-serif`;
      context.fillText(timeText, rightX, centerY);
    }
  } else {
    // ── 常规单行水平排版（横屏或宽度充裕） ──
    // 如果单行轻度超出，按比例微缩字号与间距，避免任何重叠
    let shrinkFactor = 1.0;
    if (singleLineNeededW > availW) {
      shrinkFactor = Math.max(0.72, (availW - minGap) / (singleLineLeftW + singleLineRightW));
    }

    const curPrimary = Math.max(8, Math.round(basePrimary * shrinkFactor));
    const curSecondary = Math.max(7, Math.round(baseSecondary * shrinkFactor));
    const curGap = Math.max(4 * scale, Math.round(8 * shrinkFactor));

    let curX = marginX;

    // 1. 设备型号
    if (hasDevice) {
      context.fillStyle = textColorPrimary;
      context.font = `600 ${curPrimary}px sans-serif`;
      context.textAlign = 'left';
      context.fillText(displayDevice, curX, centerY);
      curX += context.measureText(displayDevice).width + curGap;

      // 2. 竖线分割
      if (hasLogo) {
        context.fillStyle = dividerColor;
        context.font = `300 ${curPrimary * 0.9}px sans-serif`;
        context.fillText('|', curX, centerY - curPrimary * 0.05);
        curX += context.measureText('|').width + curGap;
      }
    }

    // 3. Logo 徽标
    if (hasLogo) {
      paintLogoBadge(context, logo, curX, centerY, curPrimary, textColorPrimary);
    }

    // 4. 右侧参数与时间
    const rightX = w - marginX;
    context.textAlign = 'right';

    if (hasParams && hasTime) {
      context.fillStyle = textColorPrimary;
      context.font = `500 ${curSecondary}px monospace, sans-serif`;
      context.fillText(paramsText, rightX, centerY - curSecondary * 0.6);

      context.fillStyle = textColorSecondary;
      context.font = `400 ${Math.max(6, Math.round(curSecondary * 0.85))}px sans-serif`;
      context.fillText(timeText, rightX, centerY + curSecondary * 0.7);
    } else if (hasParams) {
      context.fillStyle = textColorPrimary;
      context.font = `500 ${curSecondary}px monospace, sans-serif`;
      context.fillText(paramsText, rightX, centerY);
    } else if (hasTime) {
      context.fillStyle = textColorSecondary;
      context.font = `400 ${curSecondary}px sans-serif`;
      context.fillText(timeText, rightX, centerY);
    }
  }
}

// 蔡司 ZEISS 官方经典透镜徽标（德国卡尔·蔡司标准矢量路径，viewBox: 0 0 566.929 566.929）
const ZEISS_SHIELD_SVG = 'M566.929,566.929c-180.312-80.927-386.617-80.927-566.929,0V0h566.929V566.929z';
const ZEISS_WORDMARK_SVG =
  'M67.233,172.985c-15.194,0.09-27.751,11.876-28.801,27.034H25.709v-40.022h99.215' +
  'c0,0,0.795,30.922-28.536,63.699c0,0-27.918,32.424-28.625,46.648h16.079' +
  'c23.059,0,25.444-27.034,25.444-27.034h13.252v40.11H21.115' +
  'c0,0-3.711-30.392,31.452-67.233c0,0,21.645-24.207,26.681-43.291L67.233,172.985z' +
  'M240.483,283.42v-40.11h-13.252c0,0-2.474,27.034-25.533,27.034h-13.252v-42.054h4.682' +
  'c5.477-0.037,9.947,4.374,9.983,9.851c0,0.044,0,0.089,0,0.133v4.947h13.076V200.02' +
  'h-13.076v5.036c0.037,5.477-4.374,9.947-9.851,9.983c-0.044,0-0.089,0-0.133,0h-4.682' +
  'v-42.054h13.252c23.059,0,25.533,27.034,25.533,27.034h13.252v-40.11H135.968v13.164' +
  'h3.004c5.456-0.009,9.886,4.407,9.895,9.862c0,0.011,0,0.022,0,0.033v77.393' +
  'c0.009,5.456-4.407,9.886-9.862,9.895c-0.011,0-0.022,0-0.033,0h-3.004v13.075L240.483,283.42z' +
  'M319.908,283.332v-13.075h-3.004c-5.456,0.009-9.886-4.407-9.895-9.862' +
  'c0-0.011,0-0.022,0-0.033v-77.393c-0.009-5.456,4.407-9.886,9.862-9.895' +
  'c0.011,0,0.022,0,0.033,0h3.004v-13.075h-65.819v13.076h3.004' +
  'c5.466-0.047,9.936,4.346,9.983,9.813c0,0.027,0,0.055,0,0.082v77.393' +
  'c-0.002,5.467-4.434,9.897-9.901,9.895c-0.027,0-0.055,0-0.082,0h-3.004v13.076L319.908,283.332z' +
  'M388.996,172.985c15.199,0.038,27.761,11.865,28.713,27.034h12.81v-40.022h-94.797' +
  'c0,0-15.019,19.613,24.207,63.699c0,0,27.83,32.424,28.536,46.648h-15.991' +
  'c-23.059,0-25.533-27.034-25.533-27.034h-13.341v40.11h95.593' +
  'c0,0,17.405-18.73-25.621-67.233c0,0-22.529-23.147-26.681-43.291L388.996,172.985z' +
  'M499.873,172.985c15.182,0.08,27.72,11.884,28.713,27.034h12.722v-40.022h-94.709' +
  'c0,0-15.019,19.613,24.207,63.699c0,0,27.83,32.424,28.536,46.648h-15.991' +
  'c-23.059,0-25.533-27.034-25.533-27.034h-13.252v40.11h95.592' +
  'c0,0,17.316-18.73-25.621-67.233c0,0-22.529-23.147-26.593-43.291L499.873,172.985z';

let zeissShieldPath: Path2D | null = null;
let zeissWordmarkPath: Path2D | null = null;

function getZeissShieldPath(): Path2D {
  if (!zeissShieldPath) {
    zeissShieldPath = new Path2D(ZEISS_SHIELD_SVG);
  }
  return zeissShieldPath;
}

function getZeissWordmarkPath(): Path2D {
  if (!zeissWordmarkPath) {
    zeissWordmarkPath = new Path2D(ZEISS_WORDMARK_SVG);
  }
  return zeissWordmarkPath;
}

/** 官方 Apple 经典咬口苹果与叶片矢量图标 SVG 路径 */
const APPLE_ICON_SVG =
  'M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56' +
  '-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17' +
  '-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08' +
  '-3.7-3.04-7.7-7.91-12-14.61-5.87-9.02-10.4-18.91-13.6-29.67-3.2-10.76-4.8-21.05-4.8-30.87' +
  '0-14.78 3.82-26.69 11.46-35.73 7.64-9.04 16.99-13.67 28.05-13.88 5.43 0 11.36 1.41 17.78 4.23' +
  '6.42 2.83 10.44 4.35 12.06 4.56 2.17-.33 6.64-2 13.41-5.01 6.77-3.01 12.59-4.32 17.46-3.93' +
  '13.59.87 24.32 5.54 32.2 14.02-11.74 7.17-17.4 17.07-16.98 29.7.43 9.78 4.24 17.83 11.43 24.13' +
  '7.19 6.3 15.65 9.9 25.38 10.8-2.61 7.82-5.76 15.43-9.44 22.84zm-30.85-116.89c.11 2.39-.33 4.88-1.33 7.47' +
  '-1 2.59-2.49 5.09-4.47 7.5-2.28 2.83-4.99 5.09-8.13 6.78-3.14 1.69-6.3 2.72-9.48 3.09' +
  '-.11-2.07.33-4.33 1.33-6.78 1-2.45 2.5-4.9 4.5-7.35 2.28-2.72 5.02-4.92 8.22-6.6' +
  '3.2-1.69 6.32-2.73 9.36-3.11z';

let appleIconPath: Path2D | null = null;

function getAppleIconPath(): Path2D {
  if (!appleIconPath) {
    appleIconPath = new Path2D(APPLE_ICON_SVG);
  }
  return appleIconPath;
}

/** 绘制各品牌/影像联名徽标 */
function paintLogoBadge(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  logo: string,
  x: number,
  centerY: number,
  size: number,
  defaultTextColor: string
): void {
  if (logo === 'zeiss') {
    // 经典蔡司正统光学透镜蓝标（1:1 正方形，底部凸透镜上拱弧线，纯白粗衬线 ZEISS 矢量字模）
    const badgeSize = Math.round(size * 1.15);
    const scale = badgeSize / 566.929;
    const topY = centerY - badgeSize * 0.5;

    context.save();
    context.translate(x, topY);
    context.scale(scale, scale);

    // 1. 蔡司官方深蓝光学透镜外廓
    context.fillStyle = '#002DB4';
    context.fill(getZeissShieldPath());

    // 2. 纯白粗衬线 ZEISS 字模
    context.fillStyle = '#FFFFFF';
    context.fill(getZeissWordmarkPath());

    context.restore();
  } else if (logo === 'leica') {
    // 经典徕卡红圆标
    const radius = Math.round(size * 0.6);
    context.fillStyle = '#E4002B';
    context.beginPath();
    context.arc(x + radius, centerY, radius, 0, 2 * Math.PI);
    context.fill();
    context.fillStyle = '#FFFFFF';
    context.font = `italic bold ${Math.round(radius * 0.8)}px sans-serif`;
    context.textAlign = 'center';
    context.fillText('Leica', x + radius, centerY);
  } else if (logo === 'hasselblad') {
    // 哈苏：斜体 + 橙色小圆点
    const dotR = Math.max(2, Math.round(size * 0.18));
    context.fillStyle = '#FF6600';
    context.beginPath();
    context.arc(x + dotR, centerY, dotR, 0, 2 * Math.PI);
    context.fill();
    context.fillStyle = defaultTextColor;
    context.font = `italic bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('HASSELBLAD', x + dotR * 2 + 3, centerY);
  } else if (logo === 'apple') {
    // 经典 Apple 官方咬口苹果与飞叶纯矢量图标（自适应当前主题文字颜色）
    const scale = size / 170;
    context.save();
    context.translate(x - 18.7 * scale, centerY - 91.65 * scale);
    context.scale(scale, scale);
    context.fillStyle = defaultTextColor;
    context.fill(getAppleIconPath());
    context.restore();
  } else if (logo === 'sony') {
    context.fillStyle = defaultTextColor;
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('SONY', x, centerY);
  } else if (logo === 'canon') {
    context.fillStyle = '#C8102E';
    context.font = `bold ${Math.round(size * 0.9)}px serif`;
    context.textAlign = 'left';
    context.fillText('Canon', x, centerY);
  } else if (logo === 'nikon') {
    const badgeH = Math.round(size * 1.05);
    const badgeW = Math.round(badgeH * 1.6);
    context.fillStyle = '#FFE600';
    context.fillRect(x, centerY - badgeH * 0.5, badgeW, badgeH);
    context.fillStyle = '#000000';
    context.font = `italic bold ${Math.round(badgeH * 0.55)}px sans-serif`;
    context.textAlign = 'center';
    context.fillText('Nikon', x + badgeW * 0.5, centerY);
  } else if (logo === 'fujifilm') {
    // 富士胶片：FUJI + 红色小方块 + FILM
    context.fillStyle = defaultTextColor;
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('FUJI', x, centerY);
    const fujiW = context.measureText('FUJI').width;
    const dotW = Math.round(size * 0.32);
    context.fillStyle = '#E4002B';
    context.fillRect(x + fujiW + 2, centerY - dotW * 0.5, dotW, dotW);
    context.fillStyle = defaultTextColor;
    context.fillText('FILM', x + fujiW + dotW + 4, centerY);
  } else if (logo === 'xiaomi') {
    // 小米经典橙色圆角方块 mi 标
    const badgeH = Math.round(size * 1.1);
    const badgeW = badgeH;
    context.fillStyle = '#FF6900';
    const radius = Math.round(badgeH * 0.28);
    context.beginPath();
    context.moveTo(x + radius, centerY - badgeH * 0.5);
    context.arcTo(x + badgeW, centerY - badgeH * 0.5, x + badgeW, centerY + badgeH * 0.5, radius);
    context.arcTo(x + badgeW, centerY + badgeH * 0.5, x, centerY + badgeH * 0.5, radius);
    context.arcTo(x, centerY + badgeH * 0.5, x, centerY - badgeH * 0.5, radius);
    context.arcTo(x, centerY - badgeH * 0.5, x + badgeW, centerY - badgeH * 0.5, radius);
    context.closePath();
    context.fill();
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${Math.round(badgeH * 0.55)}px sans-serif`;
    context.textAlign = 'center';
    context.fillText('mi', x + badgeW * 0.5, centerY);
  } else if (logo === 'samsung') {
    context.fillStyle = '#0C4DA2';
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('SAMSUNG', x, centerY);
  } else if (logo === 'vivo') {
    context.fillStyle = '#0055FF';
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('vivo', x, centerY);
  } else if (logo === 'oppo') {
    context.fillStyle = '#008855';
    context.font = `bold ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('oppo', x, centerY);
  } else if (logo === 'honor') {
    const ringR = Math.round(size * 0.42);
    context.strokeStyle = '#0077FF';
    context.lineWidth = Math.max(1.5, Math.round(size * 0.12));
    context.beginPath();
    context.arc(x + ringR, centerY, ringR, 0, 2 * Math.PI);
    context.stroke();
    context.fillStyle = defaultTextColor;
    context.font = `bold ${Math.round(size * 0.8)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('HONOR', x + ringR * 2 + 4, centerY);
  } else if (logo === 'master') {
    context.fillStyle = '#003366';
    context.font = `italic 600 ${Math.round(size * 0.85)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('Master Series', x, centerY);
  }
}

interface MasterGridColumn {
  val: string;
  lbl: string;
}

/** 影展四栏矩阵水印（参考图 5） */
function paintMasterGridWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;
  if (bannerH <= 0) {
    return;
  }

  const r = (safe.colorArgb >>> 16) & 255;
  const g = (safe.colorArgb >>> 8) & 255;
  const b = safe.colorArgb & 255;
  const isDark = (0.299 * r + 0.587 * g + 0.114 * b) < 140;

  const textColor = isDark ? '#FFFFFF' : '#111111';
  const labelColor = isDark ? '#888888' : '#666666';
  const dividerColor = isDark ? '#333333' : '#E5E5E5';

  // 1. 上半部：品牌 Logo 与机型型号（或艺术手写签）
  const topCenterY = photoBottom + bannerH * 0.28;
  const scriptSize = Math.max(10, Math.round(bannerH * 0.16));
  context.textBaseline = 'middle';

  const hasDevice = !!(wm.showDevice && wm.deviceModel && wm.deviceModel.trim().length > 0);
  const rawDevice = hasDevice ? wm.deviceModel.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, rawDevice);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && wm.logo !== 'master' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';
  const displayDevice = formatWatermarkDeviceText(rawDevice, logo, hasLogo);

  context.font = `600 ${scriptSize}px sans-serif`;
  const devW = hasDevice ? context.measureText(displayDevice).width : 0;
  const logoW = hasLogo ? getLogoBadgeWidth(context, logo, scriptSize) : 0;
  const gap = (hasLogo && hasDevice) ? Math.max(6 * scale, 8) : 0;
  const totalHeaderW = logoW + gap + devW;

  if (hasLogo && hasDevice) {
    const startX = (w - totalHeaderW) * 0.5;
    paintLogoBadge(context, logo, startX, topCenterY, scriptSize, textColor);
    context.fillStyle = textColor;
    context.font = `600 ${scriptSize}px sans-serif`;
    context.textAlign = 'left';
    context.fillText(displayDevice, startX + logoW + gap, topCenterY);
  } else if (hasDevice) {
    context.fillStyle = textColor;
    context.font = `600 ${scriptSize}px sans-serif`;
    context.textAlign = 'center';
    context.fillText(displayDevice, w * 0.5, topCenterY);
  } else if (hasLogo) {
    context.textAlign = 'center';
    paintLogoBadge(context, logo, w * 0.5 - logoW * 0.5, topCenterY, scriptSize, textColor);
  } else {
    // 经典 Just shoot photos · MASTER SERIES 签名
    context.textAlign = 'center';
    context.fillStyle = isDark ? '#E5E5E5' : '#0B3B60';
    context.font = `italic 600 ${scriptSize}px serif, cursive`;
    context.fillText('Just shoot photos', w * 0.5, topCenterY - scriptSize * 0.35);

    context.fillStyle = labelColor;
    context.font = `500 ${Math.max(7, Math.round(scriptSize * 0.55))}px monospace, sans-serif`;
    context.fillText('MASTER SERIES', w * 0.5, topCenterY + scriptSize * 0.55);
  }

  // 2. 下半部：四栏矩阵 [ISO] | [F] | [mm] | [S]
  const botCenterY = photoBottom + bannerH * 0.72;
  const numFontSize = Math.max(10, Math.round(bannerH * 0.18));
  const lblFontSize = Math.max(8, Math.round(bannerH * 0.11));

  // 解析参数
  const p = wm.paramsText || '';
  const isoMatch = p.match(/ISO\s*(\d+)/i);
  const fMatch = p.match(/f\/?\s*([\d\.]+)/i);
  const mmMatch = p.match(/(\d+(\.\d+)?)\s*mm/i);
  // 快门速度：优先匹配分数（如 1/48s 或 1/48），次选秒数（如 0.5s 或 2s），避免误匹配焦距中的数字（如 48mm）
  let sVal = '1/2787';
  const fracMatch = p.match(/(\d+\/\d+)\s*s?/i);
  if (fracMatch) {
    sVal = fracMatch[1];
  } else {
    const secMatch = p.match(/(\d+(\.\d+)?)\s*s(?:ec)?(?!\w)/i);
    if (secMatch) {
      sVal = secMatch[1];
    }
  }

  const colData: MasterGridColumn[] = [
    { val: isoMatch ? isoMatch[1] : '400', lbl: 'ISO' },
    { val: fMatch ? fMatch[1] : '2.1', lbl: 'F' },
    { val: mmMatch ? mmMatch[1] : '140', lbl: 'mm' },
    { val: sVal, lbl: 'S' }
  ];

  const marginX = Math.max(16 * scale, w * 0.08);
  const colW = (w - 2 * marginX) / 4;
  const divH = Math.round(bannerH * 0.22);

  for (let i = 0; i < 4; i++) {
    const cx = marginX + colW * (i + 0.5);
    // 数字大字加粗
    context.fillStyle = textColor;
    context.font = `600 ${numFontSize}px monospace, sans-serif`;
    context.textAlign = 'center';
    context.fillText(colData[i].val, cx, botCenterY - lblFontSize * 0.6);

    // 标签小字居下
    context.fillStyle = labelColor;
    context.font = `400 ${lblFontSize}px monospace, sans-serif`;
    context.fillText(colData[i].lbl, cx, botCenterY + numFontSize * 0.65);

    // 分割竖线
    if (i < 3) {
      const divX = marginX + colW * (i + 1);
      context.strokeStyle = dividerColor;
      context.lineWidth = Math.max(1, 1 * scale);
      context.beginPath();
      context.moveTo(divX, botCenterY - divH * 0.5);
      context.lineTo(divX, botCenterY + divH * 0.5);
      context.stroke();
    }
  }
}

/**
 * 居中全参水印（原图 1 风格）：
 * 1. 底部暗调微渐变保护层（高度约 20% 照片高度），确保白字在浅色背景上依然醒目；
 * 2. 五层垂直阶梯居中对齐：
 *    - 品牌徽标（圆形徕卡红标、蔡司、索尼、苹果等或关闭）
 *    - 机型名称（xiaomi 15 Ultra / iPhone 16 Pro 等）
 *    - 光学参数（70mm f/1.8 1/5058s ISO50）
 *    - GPS 经纬度（39°58'59"N 116°29'27"E，若有）
 *    - 拍摄时间（2026.06.07 14:41）
 */
function paintCenteredSpecsWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;

  const overlayH = Math.max(80 * scale, h * 0.22);
  const grad = context.createLinearGradient(0, h - overlayH, 0, h);
  grad.addColorStop(0, 'rgba(0, 0, 0, 0)');
  grad.addColorStop(0.3, 'rgba(0, 0, 0, 0.25)');
  grad.addColorStop(1, 'rgba(0, 0, 0, 0.70)');
  context.fillStyle = grad;
  context.fillRect(0, h - overlayH, w, overlayH);

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const gps = wm.gpsText ? wm.gpsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';
  const displayDevice = formatWatermarkDeviceText(device, logo, hasLogo);

  let lineCount = 0;
  if (hasLogo) { lineCount++; }
  if (displayDevice.length > 0) { lineCount++; }
  if (params.length > 0) { lineCount++; }
  if (gps.length > 0) { lineCount++; }
  if (time.length > 0) { lineCount++; }
  if (lineCount === 0) {
    return;
  }

  const primarySize = Math.max(10, Math.round(overlayH * 0.16));
  const secondarySize = Math.max(8, Math.round(overlayH * 0.11));
  const lineSpacing = Math.max(secondarySize * 1.35, overlayH / (lineCount + 2));

  let curY = h - (lineCount + 0.5) * lineSpacing * 0.5 - overlayH * 0.1;
  if (curY < h - overlayH + primarySize) {
    curY = h - overlayH + primarySize;
  }

  context.textAlign = 'center';
  context.textBaseline = 'middle';

  // 1. Logo
  if (hasLogo) {
    const logoSize = Math.round(primarySize * 1.3);
    const logoW = getLogoBadgeWidth(context, logo, logoSize);
    paintLogoBadge(context, logo, w * 0.5 - logoW * 0.5, curY, logoSize, '#FFFFFF');
    curY += lineSpacing * 1.1;
  }

  // 2. 设备名
  if (displayDevice.length > 0) {
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${primarySize}px sans-serif`;
    context.fillText(displayDevice, w * 0.5, curY);
    curY += lineSpacing;
  }

  // 3. 拍摄参数
  if (params.length > 0) {
    context.fillStyle = 'rgba(255, 255, 255, 0.92)';
    context.font = `500 ${secondarySize}px monospace, sans-serif`;
    context.fillText(params, w * 0.5, curY);
    curY += lineSpacing * 0.95;
  }

  // 4. GPS 坐标
  if (gps.length > 0) {
    context.fillStyle = 'rgba(255, 255, 255, 0.80)';
    context.font = `400 ${Math.max(7, Math.round(secondarySize * 0.9))}px monospace, sans-serif`;
    context.fillText(gps, w * 0.5, curY);
    curY += lineSpacing * 0.9;
  }

  // 5. 拍摄时间
  if (time.length > 0) {
    context.fillStyle = 'rgba(255, 255, 255, 0.75)';
    context.font = `400 ${Math.max(7, Math.round(secondarySize * 0.85))}px sans-serif`;
    context.fillText(time, w * 0.5, curY);
  }
}

/**
 * 同调画报边框（原图 3 风格）：
 * 上下宽留白艺术装裱，背景色联动画面基调，顶部经典花体题签，底部机型与中文人文副标。
 */
function paintHarmonicEditorialWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const topH = geometry.photoRect.y * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;

  // 1. 顶部艺术题签 (致敬布列松「决定性瞬间」策展文印)
  if (topH >= 32 * scale) {
    const topCenterY = topH * 0.5;
    const titleSize = Math.max(10, Math.round(topH * 0.22));

    context.textAlign = 'center';
    context.textBaseline = 'middle';

    // Line 1: IDEATED BY ...
    context.fillStyle = 'rgba(255, 255, 255, 0.70)';
    context.font = `600 ${Math.max(7, Math.round(titleSize * 0.52))}px monospace, sans-serif`;
    const devicePreview = (wm && wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
    const isTopDuplicated = isLogoDuplicatedWithDevice(wm?.logo, devicePreview);
    const brandName = (wm && wm.showLogo && wm.logo && wm.logo !== 'none' && wm.logo !== 'master' && !isTopDuplicated)
      ? wm.logo.toUpperCase()
      : 'MASTER SERIES';
    context.fillText(`IDEATED BY ${brandName}`, w * 0.5, topCenterY - titleSize * 0.75);

    // Line 2: The decisive moment (或自定义 headerText)
    const headerTitle = (wm && wm.headerText && wm.headerText.trim().length > 0)
      ? wm.headerText.trim()
      : 'The decisive moment';
    context.fillStyle = '#FFFFFF';
    context.font = `italic 500 ${titleSize}px Georgia, "Noto Serif SC", serif`;
    context.fillText(headerTitle, w * 0.5, topCenterY);

    // Line 3: PHOTOGRAPH
    context.fillStyle = 'rgba(255, 255, 255, 0.60)';
    context.font = `500 ${Math.max(6, Math.round(titleSize * 0.45))}px monospace, sans-serif`;
    context.fillText('P H O T O G R A P H', w * 0.5, topCenterY + titleSize * 0.75);
  }

  if (!wm || bannerH <= 0) {
    return;
  }

  // 2. 底部居中机型与人文副标
  const centerY = photoBottom + bannerH * 0.5;
  const primarySize = Math.max(12, Math.round(bannerH * 0.20));
  const secondarySize = Math.max(9, Math.round(bannerH * 0.14));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const subTitle = (wm.subTitle && wm.subTitle.trim().length > 0)
    ? wm.subTitle.trim()
    : '一双发现美的眼睛';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';
  const displayDevice = formatWatermarkDeviceText(device, logo, hasLogo);

  const line1Y = centerY - bannerH * 0.15;
  const line2Y = centerY + bannerH * 0.18;

  // 第一行：设备品牌型号 (如果有独立 Logo 且需居中协同排版)
  const logoSize = Math.round(primarySize * 1.1);
  const logoW = hasLogo ? getLogoBadgeWidth(context, logo, logoSize) : 0;
  context.font = `bold ${primarySize}px sans-serif`;
  const devW = displayDevice.length > 0 ? context.measureText(displayDevice).width : 0;
  const gap = (logoW > 0 && devW > 0) ? 8 * scale : 0;
  const totalW = logoW + gap + devW;

  if (logoW > 0) {
    paintLogoBadge(context, logo, w * 0.5 - totalW * 0.5, line1Y, logoSize, '#FFFFFF');
  }
  if (displayDevice.length > 0) {
    context.fillStyle = '#FFFFFF';
    context.textAlign = logoW > 0 ? 'left' : 'center';
    const textX = logoW > 0 ? (w * 0.5 - totalW * 0.5 + logoW + gap) : (w * 0.5);
    context.fillText(displayDevice, textX, line1Y);
  }

  // 第二行：中文人文副标 / 摄影感悟
  context.textAlign = 'center';
  context.fillStyle = 'rgba(255, 255, 255, 0.85)';
  context.font = `400 ${secondarySize}px "Noto Serif SC", sans-serif`;
  context.fillText(subTitle, w * 0.5, line2Y);
}

/**
 * 格式化参数为工业键值对格式：Aperture | f/4.0    Shutter | 1/250s    ISO | 800
 */
export function formatKeyValueSpecs(paramsText: string): string {
  if (!paramsText || paramsText.trim().length === 0) {
    return 'Aperture | f/4.0    Shutter | 1/250s    ISO | 800';
  }
  const clean = paramsText.trim();
  const apMatch = clean.match(/[fF]\/?([0-9.]+)/);
  const shMatch = clean.match(/([0-9]+\/[0-9]+s?|[0-9.]+s)/i);
  const isoMatch = clean.match(/ISO\s*([0-9]+)/i);

  if (apMatch && shMatch && isoMatch) {
    const ap = `f/${apMatch[1]}`;
    const sh = shMatch[1].endsWith('s') ? shMatch[1] : `${shMatch[1]}s`;
    const iso = isoMatch[1];
    return `Aperture | ${ap}    Shutter | ${sh}    ISO | ${iso}`;
  }
  return clean.replace(/([fF][0-9.]+)/g, 'Aperture | $1')
              .replace(/([0-9]+\/[0-9]+s?)/g, 'Shutter | $1')
              .replace(/ISO\s*([0-9]+)/g, 'ISO | $1');
}

/**
 * 极简键值印记水印（原图 4 风格）：
 * 1. 底部微暗渐变保护；
 * 2. 居中经典单字母徽标（如哈苏斜体加粗 H 或其他品牌单标）；
 * 3. 居中 Aperture | ... Shutter | ... ISO | ... 工业规范排版。
 */
function paintMinimalKeyvalueWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;

  const overlayH = Math.max(64 * scale, h * 0.16);
  const grad = context.createLinearGradient(0, h - overlayH, 0, h);
  grad.addColorStop(0, 'rgba(0, 0, 0, 0)');
  grad.addColorStop(0.3, 'rgba(0, 0, 0, 0.25)');
  grad.addColorStop(1, 'rgba(0, 0, 0, 0.70)');
  context.fillStyle = grad;
  context.fillRect(0, h - overlayH, w, overlayH);

  const centerY = h - overlayH * 0.45;
  const primarySize = Math.max(16, Math.round(overlayH * 0.30));
  const secondarySize = Math.max(8, Math.round(overlayH * 0.16));

  const rawParams = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : 'f/4.0 1/250s ISO800';
  const kvParams = formatKeyValueSpecs(rawParams);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none');
  const logo = hasLogo ? (wm.logo ?? 'hasselblad') : 'none';

  context.textAlign = 'center';
  context.textBaseline = 'middle';

  const logoY = centerY - secondarySize * 0.9;
  const paramsY = centerY + secondarySize * 0.85;

  // 1. 居中单徽标
  if (hasLogo) {
    if (logo === 'hasselblad') {
      context.fillStyle = '#FFFFFF';
      context.font = `italic 700 ${primarySize}px serif, "Times New Roman", sans-serif`;
      context.fillText('H', w * 0.5, logoY);
    } else {
      const logoW = getLogoBadgeWidth(context, logo, primarySize);
      paintLogoBadge(context, logo, w * 0.5 - logoW * 0.5, logoY, primarySize, '#FFFFFF');
    }
  }

  // 2. 居中带键名参数条
  context.fillStyle = '#FFFFFF';
  context.font = `bold ${secondarySize}px monospace, sans-serif`;
  context.fillText(kvParams, w * 0.5, hasLogo ? paramsY : centerY);
}

/** 弥散虚化画中画水印（参考图 2 & 5） */
function paintBlurPipWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;

  // 1. 主图柔和卡片外阴影与细亮外边框
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;
  const pr = geometry.cornerRadius * scale;

  context.save();
  context.shadowColor = 'rgba(0, 0, 0, 0.45)';
  context.shadowBlur = 20 * scale;
  context.shadowOffsetY = 8 * scale;
  context.fillStyle = 'rgba(0, 0, 0, 0.60)';
  if (pr > 0) {
    drawRoundedRectPath(context, px, py, pw, ph, pr);
    context.fill();
  } else {
    context.fillRect(px, py, pw, ph);
  }
  context.restore();

  // 照片周圈超细透亮框线，增强画中画层级质感
  context.strokeStyle = 'rgba(255, 255, 255, 0.20)';
  context.lineWidth = Math.max(1, 1 * scale);
  if (pr > 0) {
    drawRoundedRectPath(context, px, py, pw, ph, pr);
    context.stroke();
  } else {
    context.strokeRect(px, py, pw, ph);
  }

  if (!wm || bannerH <= 0) {
    return;
  }

  // 2. 底部居中机型与参数
  const centerY = photoBottom + bannerH * 0.5;
  const primarySize = Math.max(11, Math.round(bannerH * 0.18));
  const secondarySize = Math.max(9, Math.round(bannerH * 0.12));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';
  const displayDevice = formatWatermarkDeviceText(device, logo, hasLogo);

  context.textBaseline = 'middle';
  const topY = params ? (centerY - bannerH * 0.15) : centerY;
  const botY = centerY + bannerH * 0.15;

  // Line 1: Logo + Device 居中
  context.font = `bold ${primarySize}px sans-serif`;
  const devW = displayDevice.length > 0 ? context.measureText(displayDevice).width : 0;
  const logoW = hasLogo ? getLogoBadgeWidth(context, logo, primarySize) : 0;
  const gap = (logoW > 0 && devW > 0) ? 8 * scale : 0;
  const totalLine1W = logoW + gap + devW;
  const startX = (w - totalLine1W) * 0.5;

  if (logoW > 0) {
    paintLogoBadge(context, logo, startX, topY, primarySize, '#FFFFFF');
  }
  if (devW > 0) {
    context.fillStyle = '#FFFFFF';
    context.font = `600 ${primarySize}px sans-serif`;
    context.textAlign = 'left';
    context.fillText(displayDevice, startX + logoW + gap, topY);
  }

  // Line 2: 拍摄参数 [+ 时间]
  let subText = params;
  if (time) {
    subText = subText ? `${subText}  ·  ${time}` : time;
  }
  if (subText) {
    context.fillStyle = 'rgba(255, 255, 255, 0.85)';
    context.font = `500 ${secondarySize}px monospace, sans-serif`;
    context.textAlign = 'center';
    context.fillText(subText, w * 0.5, botY);
  }
}

/** 电影艺术影集水印（参考图 4） */
function paintCinematicWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const topH = geometry.photoRect.y * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;

  // 1. 顶部艺术题签
  if (topH > 0) {
    const topCenterY = topH * 0.5;
    context.textAlign = 'center';
    context.textBaseline = 'middle';

    context.fillStyle = '#A0A8A0';
    context.font = `500 ${Math.max(6, Math.round(topH * 0.18))}px monospace, sans-serif`;
    context.fillText('IDEATED BY MASTER SERIES', w * 0.5, topCenterY - topH * 0.25);

    context.fillStyle = '#FFFFFF';
    context.font = `italic 600 ${Math.max(9, Math.round(topH * 0.32))}px serif, cursive`;
    context.fillText('The decisive moment', w * 0.5, topCenterY + topH * 0.05);

    context.fillStyle = '#808880';
    context.font = `400 ${Math.max(5, Math.round(topH * 0.15))}px monospace, sans-serif`;
    context.fillText('P H O T O G R A P H', w * 0.5, topCenterY + topH * 0.35);
  }

  // 2. 底部居中设备与参数
  if (!wm || bannerH <= 0) {
    return;
  }
  const centerY = photoBottom + bannerH * 0.5;
  const primarySize = Math.max(10, Math.round(bannerH * 0.22));
  const secondarySize = Math.max(8, Math.round(bannerH * 0.15));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : 'OPPO Find X9 Pro';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';

  const topY = centerY - bannerH * 0.16;
  const botY = centerY + bannerH * 0.20;

  context.textAlign = 'center';
  context.textBaseline = 'middle';

  // 设备名大字
  context.fillStyle = '#FFFFFF';
  context.font = `bold ${primarySize}px sans-serif`;
  context.fillText(device, w * 0.5, topY);

  // 参数小字
  if (params.length > 0) {
    context.fillStyle = '#B0B5B0';
    context.font = `400 ${secondarySize}px monospace, sans-serif`;
    context.fillText(params, w * 0.5, botY);
  }
}

/** 富士复古胶片水印（拍立得相纸质感） */
function paintRetroFilmWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;
  if (bannerH <= 0) {
    return;
  }

  const centerY = photoBottom + bannerH * 0.5;
  const marginX = Math.max(12 * scale, w * 0.05);

  const primarySize = Math.max(9, Math.round(bannerH * 0.20));
  const secondarySize = Math.max(8, Math.round(bannerH * 0.15));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';

  context.textBaseline = 'middle';

  // 左侧：经典复古 Logo + 设备名
  let curX = marginX;
  const logoW = hasLogo ? getLogoBadgeWidth(context, logo, primarySize) : 0;
  if (logoW > 0) {
    paintLogoBadge(context, logo, curX, centerY, primarySize, '#222222');
    curX += logoW + 8 * scale;
  }
  if (device.length > 0) {
    context.fillStyle = '#222222';
    context.font = `600 ${primarySize}px serif, monospace`;
    context.textAlign = 'left';
    context.fillText(device, curX, centerY);
  }

  // 右侧：打字机/胶片风格日期与参数
  const rightX = w - marginX;
  context.textAlign = 'right';

  if (time.length > 0 && params.length > 0) {
    context.fillStyle = '#444444';
    context.font = `500 ${secondarySize}px monospace`;
    context.fillText(time, rightX, centerY - secondarySize * 0.6);

    context.fillStyle = '#666666';
    context.font = `400 ${Math.max(7, Math.round(secondarySize * 0.88))}px monospace`;
    context.fillText(params, rightX, centerY + secondarySize * 0.7);
  } else if (params.length > 0) {
    context.fillStyle = '#444444';
    context.font = `500 ${secondarySize}px monospace`;
    context.fillText(params, rightX, centerY);
  } else if (time.length > 0) {
    context.fillStyle = '#666666';
    context.font = `400 ${secondarySize}px monospace`;
    context.fillText(time, rightX, centerY);
  }
}

/** 无界原图悬浮水印（参考图 2） */
function paintOverlayWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  if (!wm) {
    return;
  }
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;

  // 1. 底部微暗半透明渐变层（保证任何底图文字都清晰）
  const overlayH = Math.max(48 * scale, h * 0.12);
  const grad = context.createLinearGradient(0, h - overlayH, 0, h);
  grad.addColorStop(0, 'rgba(0, 0, 0, 0)');
  grad.addColorStop(0.3, 'rgba(0, 0, 0, 0.25)');
  grad.addColorStop(1, 'rgba(0, 0, 0, 0.65)');
  context.fillStyle = grad;
  context.fillRect(0, h - overlayH, w, overlayH);

  // 2. 纯白高透亮水印排版
  const centerY = h - overlayH * 0.45;
  const marginX = Math.max(14 * scale, w * 0.045);

  const primarySize = Math.max(10, Math.round(overlayH * 0.28));
  const secondarySize = Math.max(8, Math.round(overlayH * 0.22));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';
  const displayDevice = formatWatermarkDeviceText(device, logo, hasLogo);

  context.textBaseline = 'middle';

  // 左侧：白底加粗 Logo + 设备型号
  let curX = marginX;
  const logoW = hasLogo ? getLogoBadgeWidth(context, logo, primarySize) : 0;
  if (logoW > 0) {
    paintLogoBadge(context, logo, curX, centerY, primarySize, '#FFFFFF');
    curX += logoW + 8 * scale;
  }
  if (displayDevice.length > 0) {
    if (logoW > 0) {
      context.fillStyle = 'rgba(255, 255, 255, 0.6)';
      context.font = `300 ${primarySize}px sans-serif`;
      context.fillText('|', curX, centerY - 1);
      curX += context.measureText('|').width + 8 * scale;
    }
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${primarySize}px sans-serif`;
    context.textAlign = 'left';
    context.fillText(displayDevice, curX, centerY);
  }

  // 右侧：白色参数与时间
  const rightX = w - marginX;
  context.textAlign = 'right';

  if (params.length > 0 && time.length > 0) {
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${secondarySize}px monospace, sans-serif`;
    context.fillText(params, rightX, centerY - secondarySize * 0.6);

    context.fillStyle = 'rgba(255, 255, 255, 0.8)';
    context.font = `400 ${Math.max(7, Math.round(secondarySize * 0.88))}px sans-serif`;
    context.fillText(time, rightX, centerY + secondarySize * 0.7);
  } else if (params.length > 0) {
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${secondarySize}px monospace, sans-serif`;
    context.fillText(params, rightX, centerY);
  } else if (time.length > 0) {
    context.fillStyle = 'rgba(255, 255, 255, 0.9)';
    context.font = `400 ${secondarySize}px sans-serif`;
    context.fillText(time, rightX, centerY);
  }
}

/** 北欧画廊水印（哈苏极简画廊装裱） */
function paintNordicGalleryWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;

  // 1. 照片微浮雕立体阴影
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;
  const pr = geometry.cornerRadius * scale;

  context.save();
  context.shadowColor = 'rgba(0, 0, 0, 0.12)';
  context.shadowBlur = 14 * scale;
  context.shadowOffsetY = 5 * scale;
  context.fillStyle = 'rgba(0, 0, 0, 0.05)';
  if (pr > 0) {
    drawRoundedRectPath(context, px, py, pw, ph, pr);
    context.fill();
  } else {
    context.fillRect(px, py, pw, ph);
  }
  context.restore();

  if (!wm || bannerH <= 0) {
    return;
  }

  // 2. 底栏正中排版
  const centerY = photoBottom + bannerH * 0.52;
  const primarySize = Math.max(10, Math.round(bannerH * 0.17));
  const secondarySize = Math.max(8, Math.round(bannerH * 0.11));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : 'HASSELBLAD X2D 100C';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo ?? 'none') : 'none';

  // 检测背景明暗
  const isDark = ((safe.colorArgb >> 16) & 0xFF) < 128;
  const textColor = isDark ? '#E5E5E5' : '#1A1A1A';
  const subColor = isDark ? '#999999' : '#666666';

  context.textAlign = 'center';
  context.textBaseline = 'middle';

  // 暖橙焦点小圆点或所选 Logo
  const dotY = centerY - bannerH * 0.22;
  if (hasLogo && logo !== 'hasselblad') {
    const logoW = getLogoBadgeWidth(context, logo, Math.round(primarySize * 0.9));
    paintLogoBadge(context, logo, w * 0.5 - logoW * 0.5, dotY, Math.round(primarySize * 0.9), textColor);
  } else {
    // 标志性哈苏暖橙圆点
    context.fillStyle = '#FF5500';
    context.beginPath();
    context.arc(w * 0.5, dotY, Math.max(3, 3.5 * scale), 0, 2 * Math.PI);
    context.fill();
  }

  // 设备名称（大字距 spaced text）
  const devSpaced = device.toUpperCase().split('').join(' ');
  context.fillStyle = textColor;
  context.font = `600 ${primarySize}px sans-serif`;
  context.fillText(devSpaced, w * 0.5, centerY);

  // 微缩等宽参数
  let subText = params;
  if (time) {
    subText = subText ? `${subText}  ·  ${time}` : time;
  }
  if (subText) {
    context.fillStyle = subColor;
    context.font = `400 ${secondarySize}px monospace, sans-serif`;
    context.fillText(subText, w * 0.5, centerY + bannerH * 0.20);
  }
}

/** 纪实画报水印（国家地理特辑封面） */
function paintEditorialMagWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;

  if (!wm || bannerH <= 0) {
    return;
  }

  const isDark = ((safe.colorArgb >> 16) & 0xFF) < 128;
  const textColor = isDark ? '#FFFFFF' : '#141414';
  const subColor = isDark ? 'rgba(255, 255, 255, 0.75)' : '#666666';

  const centerY = photoBottom + bannerH * 0.5;
  const primarySize = Math.max(12, Math.round(bannerH * 0.24));
  const secondarySize = Math.max(8, Math.round(bannerH * 0.12));
  const marginX = Math.max(16 * scale, geometry.photoRect.x * scale);

  // 左侧：国家地理经典明黄竖线
  const yellowW = Math.max(3, 3.5 * scale);
  const yellowH = Math.round(bannerH * 0.55);
  context.fillStyle = '#FFCC00';
  context.fillRect(marginX, centerY - yellowH * 0.5, yellowW, yellowH);

  // 左侧文字：THE MOMENT / EDITORIAL
  const titleX = marginX + yellowW + 8 * scale;
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  context.fillStyle = textColor;
  context.font = `bold ${primarySize}px "Georgia", "Noto Serif SC", serif`;
  context.fillText('THE MOMENT', titleX, centerY - bannerH * 0.13);

  context.fillStyle = subColor;
  context.font = `600 ${Math.max(7, Math.round(secondarySize * 0.85))}px monospace, sans-serif`;
  context.fillText('EDITORIAL ARCHIVE', titleX, centerY + bannerH * 0.15);

  // 右侧：机型与经纬度地理坐标 + 参数
  const rightX = w - marginX;
  context.textAlign = 'right';

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';

  // Line 1: 机型
  if (device) {
    context.fillStyle = textColor;
    context.font = `bold ${Math.round(primarySize * 0.9)}px sans-serif`;
    context.fillText(device, rightX, centerY - bannerH * 0.13);
  }

  // Line 2: 经纬度地理标刻 + 拍摄参数
  const coords = 'LAT 31°14\'N  LON 121°28\'E';
  let line2 = coords;
  if (params) {
    line2 = `${coords}  ·  ${params}`;
  }
  context.fillStyle = subColor;
  context.font = `500 ${secondarySize}px monospace, sans-serif`;
  context.fillText(line2, rightX, centerY + bannerH * 0.15);
}

/** 暗房印样水印（柯达胶片接触印相 Contact Sheet） */
function paintContactSheetWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;

  // 1. 照片四周四角 L 形暗房曝光裁切安全框
  const cornerLen = Math.max(10, 14 * scale);
  context.strokeStyle = '#E5C158'; // 胶卷金黄色
  context.lineWidth = Math.max(1, 1.5 * scale);

  const offset = 4 * scale;
  const left = px - offset;
  const right = px + pw + offset;
  const top = py - offset;
  const bottom = py + ph + offset;

  // 左上角 L
  context.beginPath();
  context.moveTo(left, top + cornerLen);
  context.lineTo(left, top);
  context.lineTo(left + cornerLen, top);
  context.stroke();

  // 右上角 L
  context.beginPath();
  context.moveTo(right - cornerLen, top);
  context.lineTo(right, top);
  context.lineTo(right, top + cornerLen);
  context.stroke();

  // 左下角 L
  context.beginPath();
  context.moveTo(left, bottom - cornerLen);
  context.lineTo(left, bottom);
  context.lineTo(left + cornerLen, bottom);
  context.stroke();

  // 右下角 L
  context.beginPath();
  context.moveTo(right - cornerLen, bottom);
  context.lineTo(right, bottom);
  context.lineTo(right, bottom - cornerLen);
  context.stroke();

  // 2. 顶部胶卷金字编号印字
  const topH = py;
  if (topH >= 24 * scale) {
    const topCenterY = topH * 0.5;
    context.textBaseline = 'middle';

    // 顶部左侧：KODAK SAFETY FILM · 400TX
    context.fillStyle = '#E5C158';
    context.font = `600 ${Math.max(8, Math.round(topH * 0.32))}px monospace, sans-serif`;
    context.textAlign = 'left';
    context.fillText('KODAK SAFETY FILM · 400TX', px, topCenterY);

    // 顶部右侧：底片卷号 [ 12A ]
    context.fillStyle = '#E5C158';
    context.font = `bold ${Math.max(9, Math.round(topH * 0.36))}px monospace, sans-serif`;
    context.textAlign = 'right';
    context.fillText('[ 12A ]', px + pw, topCenterY);
  }

  // 3. 底部曝光补偿红方块与相机参数
  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const badgeH = Math.round(bannerH * 0.36);
  const badgeW = Math.round(badgeH * 2.2);

  // 底部左侧：深红底曝光补偿微标
  context.fillStyle = '#8B1E1E';
  context.fillRect(px, centerY - badgeH * 0.5, badgeW, badgeH);

  context.fillStyle = '#FFFFFF';
  context.font = `bold ${Math.max(7, Math.round(badgeH * 0.65))}px monospace, sans-serif`;
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText('+0.3 EV', px + badgeW * 0.5, centerY);

  // 底部机型与镜头参数（白金色点阵文字）
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';

  context.textAlign = 'right';
  context.fillStyle = '#E0DCD3';
  context.font = `500 ${Math.max(9, Math.round(bannerH * 0.26))}px monospace, sans-serif`;
  const infoText = device && params ? `${device}  |  ${params}` : (device || params);
  context.fillText(infoText, px + pw, centerY);
}

/** 文书钤印水印（宋代册页金石朱砂印信） */
function paintOrientalSealWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;
  const pr = geometry.cornerRadius * scale;

  // 1. 照片四周 0.5px 极细朱砂双内框
  const outGap = 6 * scale;
  const inGap = 2.5 * scale;
  context.strokeStyle = 'rgba(178, 59, 47, 0.70)'; // 经典朱砂 #B23B2F
  context.lineWidth = Math.max(0.7, 0.9 * scale);
  if (pr > 0) {
    drawRoundedRectPath(context, px - outGap, py - outGap, pw + outGap * 2, ph + outGap * 2, pr + outGap);
    context.stroke();
    drawRoundedRectPath(context, px - outGap + inGap, py - outGap + inGap, pw + (outGap - inGap) * 2, ph + (outGap - inGap) * 2, Math.max(0, pr + outGap - inGap));
    context.stroke();
  } else {
    context.strokeRect(px - outGap, py - outGap, pw + outGap * 2, ph + outGap * 2);
    context.strokeRect(px - outGap + inGap, py - outGap + inGap, pw + (outGap - inGap) * 2, ph + (outGap - inGap) * 2);
  }

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;

  // 2. 右侧：金石朱砂篆刻方印
  const sealSize = Math.round(bannerH * 0.50);
  const sealX = px + pw - sealSize;
  const sealY = centerY - sealSize * 0.5;

  // 印泥红底
  context.fillStyle = '#A32924';
  context.fillRect(sealX, sealY, sealSize, sealSize);

  // 边框留白
  context.strokeStyle = '#F7F4EB';
  context.lineWidth = Math.max(1, 1.2 * scale);
  context.strokeRect(sealX + 2 * scale, sealY + 2 * scale, sealSize - 4 * scale, sealSize - 4 * scale);

  // 篆书印文（「澄心」金石白文）
  context.fillStyle = '#F7F4EB';
  context.font = `bold ${Math.round(sealSize * 0.38)}px "Georgia", "Noto Serif SC", serif`;
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText('澄心', sealX + sealSize * 0.5, sealY + sealSize * 0.52);

  // 3. 左侧：宋体古典款识与相机参数
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  const fontSize1 = Math.max(9, Math.round(bannerH * 0.22));
  const fontSize2 = Math.max(8, Math.round(bannerH * 0.16));

  context.textAlign = 'left';
  context.textBaseline = 'middle';

  // Line 1: 设备款识
  if (device) {
    context.fillStyle = '#241918';
    context.font = `600 ${fontSize1}px "Georgia", "Noto Serif SC", serif`;
    context.fillText(device, px, centerY - bannerH * 0.14);
  }

  // Line 2: 节气物候 · 曝光参数
  let line2 = params;
  if (time) {
    line2 = `${time}  ·  ${line2}`;
  }
  if (line2) {
    context.fillStyle = '#6E5C5A';
    context.font = `400 ${fontSize2}px monospace, "Noto Serif SC", serif`;
    context.fillText(line2, px, centerY + bannerH * 0.16);
  }
}

/** 齿孔邮票水印（连续齿孔咬边与旅拍打卡签条） */
function paintTravelStampWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;

  // 1. 绘制四周邮票齿孔打孔咬边效果
  const holeR = Math.max(3, 4.5 * scale);
  const step = holeR * 2.8;
  context.fillStyle = '#E5E1D8'; // 打孔微阴影
  // 顶底两边
  for (let x = holeR * 2; x < w - holeR; x += step) {
    context.beginPath();
    context.arc(x, 0, holeR, 0, Math.PI);
    context.fill();
    context.beginPath();
    context.arc(x, h, holeR, Math.PI, 2 * Math.PI);
    context.fill();
  }
  // 左右两边
  for (let y = holeR * 2; y < h - holeR; y += step) {
    context.beginPath();
    context.arc(0, y, holeR, -Math.PI / 2, Math.PI / 2);
    context.fill();
    context.beginPath();
    context.arc(w, y, holeR, Math.PI / 2, 3 * Math.PI / 2);
    context.fill();
  }

  // 2. 照片四周虚线邮票保护框
  const insetGap = 6 * scale;
  context.strokeStyle = '#D5D0C5';
  context.lineWidth = Math.max(1, 1.2 * scale);
  const dash = 4 * scale;
  context.setLineDash([dash, dash]);
  context.strokeRect(px - insetGap, py - insetGap, pw + insetGap * 2, ph + insetGap * 2);
  context.setLineDash([]);

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  // 3. 提取月份序号（如 01 或 09）
  let monthNum = '01';
  if (time) {
    const match = time.match(/(\d{1,2})月|[-\/](\d{1,2})[-\/]/);
    if (match) {
      const val = parseInt(match[1] || match[2], 10);
      monthNum = val < 10 ? `0${val}` : `${val}`;
    }
  }

  // 4. 左侧：大号月份序号
  const numSize = Math.max(16, Math.round(bannerH * 0.52));
  context.fillStyle = '#2A2621';
  context.font = `bold ${numSize}px "Georgia", serif`;
  context.textAlign = 'left';
  context.textBaseline = 'middle';
  context.fillText(monthNum, px, centerY);
  const numW = context.measureText(monthNum).width;

  // 5. 月份序号右侧两行旅拍签名
  const textX = px + numW + 8 * scale;
  const line1 = device ? `TRAVEL · ${device}` : 'POSTAGE · TRAVEL LOG';
  const line2 = params || time || 'ORIGINAL PHOTOGRAPHY';

  context.fillStyle = '#3D3833';
  context.font = `600 ${Math.max(9, Math.round(bannerH * 0.18))}px sans-serif`;
  context.fillText(line1, textX, centerY - bannerH * 0.14);

  context.fillStyle = '#666666';
  context.font = `400 ${Math.max(8, Math.round(bannerH * 0.14))}px monospace, sans-serif`;
  context.fillText(line2, textX, centerY + bannerH * 0.16);

  // 6. 右侧：航空信印章小框
  const badgeH = Math.round(bannerH * 0.44);
  const badgeW = Math.round(badgeH * 2.2);
  const badgeX = px + pw - badgeW;
  const badgeY = centerY - badgeH * 0.5;

  context.strokeStyle = '#998F82';
  context.lineWidth = Math.max(1, 1.2 * scale);
  context.strokeRect(badgeX, badgeY, badgeW, badgeH);

  context.fillStyle = '#6E6559';
  context.font = `bold ${Math.max(7, Math.round(badgeH * 0.38))}px sans-serif`;
  context.textAlign = 'center';
  context.fillText('AIR MAIL', badgeX + badgeW * 0.5, centerY);
}

/** 格式化邮戳日期：将 2026.09.03 16:30 或 2026:09:11 格式化为古典航空邮戳风格 */
export function formatPostmarkDate(timeText: string): string {
  if (!timeText || timeText.trim().length === 0) {
    return '2026.09.11';
  }
  const clean = timeText.trim();
  const match = clean.match(/^(\d{4})[.\-\/:](\d{1,2})[.\-\/:](\d{1,2})/);
  if (match) {
    const y = match[1];
    const m = match[2].padStart(2, '0');
    const d = match[3].padStart(2, '0');
    const months: string[] = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    const mIdx = parseInt(m, 10) - 1;
    if (mIdx >= 0 && mIdx < 12) {
      return `${d} · ${months[mIdx]} · ${y.substring(2)}`;
    }
    return `${y}.${m}.${d}`;
  }
  return clean.substring(0, 10);
}

/** 沿着圆弧绘制弯曲文字（贴合圆弧轮廓） */
export function drawArcText(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  text: string,
  radius: number,
  angularSpan: number
): void {
  const n = text.length;
  if (n === 0) {
    return;
  }
  const step = n > 1 ? angularSpan / (n - 1) : 0;
  const startAngle = n > 1 ? -Math.PI / 2 - angularSpan / 2 : -Math.PI / 2;

  for (let i = 0; i < n; i++) {
    const angle = startAngle + i * step;
    context.save();
    context.rotate(angle + Math.PI / 2);
    context.fillText(text[i], 0, -radius);
    context.restore();
  }
}

/** 绘制空气动力学平滑波浪消资线（4 联装三次贝塞尔曲线） */
export function drawAerodynamicWaveLines(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  startX: number,
  centerY: number,
  width: number,
  lineSpacing: number,
  amplitude: number
): void {
  const halfWave = width / 4;
  context.lineCap = 'round';

  for (let i = 0; i < 4; i++) {
    const wy = centerY + (i - 1.5) * lineSpacing;
    context.beginPath();
    context.moveTo(startX, wy);

    for (let c = 0; c < 2; c++) {
      const cx0 = startX + c * 2 * halfWave;
      // 1. 上半周（波峰）
      context.bezierCurveTo(
        cx0 + halfWave * 0.364, wy - amplitude,
        cx0 + halfWave * 0.636, wy - amplitude,
        cx0 + halfWave, wy
      );
      // 2. 下半周（波谷）
      context.bezierCurveTo(
        cx0 + halfWave + halfWave * 0.364, wy + amplitude,
        cx0 + halfWave + halfWave * 0.636, wy + amplitude,
        cx0 + 2 * halfWave, wy
      );
    }
    context.stroke();
  }
}

/** 旅行明信片水印（天青相纸、手写旅行题签、复古航空日戳与平滑波浪消资线） */
function paintTravelPostcardWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;
  const pr = geometry.cornerRadius * scale;

  // 1. 照片白色勾边（严格契合照片圆角）
  context.strokeStyle = 'rgba(255, 255, 255, 0.95)';
  context.lineWidth = Math.max(1.5, 2 * scale);
  if (pr > 0) {
    drawRoundedRectPath(context, px - 1 * scale, py - 1 * scale, pw + 2 * scale, ph + 2 * scale, pr + 1 * scale);
    context.stroke();
  } else {
    context.strokeRect(px - 1 * scale, py - 1 * scale, pw + 2 * scale, ph + 2 * scale);
  }

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  // 2. 邮戳与波浪基础度量计算
  const stampR = Math.max(18 * scale, Math.min(36 * scale, Math.round(bannerH * 0.35)));
  const innerR = Math.round(stampR * 0.68);
  const marginR = Math.max(8 * scale, 12);
  const gapBetween = Math.round(4 * scale);

  let waveW = Math.max(20 * scale, Math.min(48 * scale, Math.round(stampR * 1.5)));
  let showWaves = true;

  // 3. 计算文本可用宽度并执行动态防撞收缩
  const textStartX = px + Math.max(6 * scale, 8);
  const safeGap = Math.max(14 * scale, 16);

  // 整理副标题（机型与拍摄参数协同，不进行短路丢弃）
  const sublineParts: string[] = [];
  if (device) {
    sublineParts.push(device);
  }
  if (params) {
    sublineParts.push(params);
  }
  const sublineText = sublineParts.join('  ·  ');
  const titleText = '去有风的地方';

  // 预估文字字号
  let titleSize = Math.max(11, Math.min(22 * scale, Math.round(bannerH * 0.27)));
  let sublineSize = Math.max(8, Math.min(12 * scale, Math.round(bannerH * 0.15)));

  context.font = `bold italic ${titleSize}px "Georgia", "Noto Serif SC", serif`;
  let titleW = context.measureText(titleText).width;
  context.font = `500 ${sublineSize}px monospace, "Noto Sans SC", sans-serif`;
  let sublineW = context.measureText(sublineText).width;
  let maxLeftW = Math.max(titleW, sublineW);

  // 防撞收缩决策（4 级平滑降级）
  let totalStampW = stampR * 2 + (showWaves ? (gapBetween + waveW) : 0);
  let availTextW = (px + pw - marginR - totalStampW - safeGap) - textStartX;

  // Level 2: 压缩波浪线
  if (maxLeftW > availTextW && showWaves) {
    waveW = Math.max(16 * scale, Math.round(waveW * 0.55));
    totalStampW = stampR * 2 + gapBetween + waveW;
    availTextW = (px + pw - marginR - totalStampW - safeGap) - textStartX;
  }

  // Level 3: 隐藏波浪线（仅保留精美日戳）
  if (maxLeftW > availTextW && showWaves) {
    showWaves = false;
    totalStampW = stampR * 2;
    availTextW = (px + pw - marginR - totalStampW - safeGap) - textStartX;
  }

  // Level 4: 微缩字号与智能截断
  if (maxLeftW > availTextW && availTextW > 0) {
    // factor = Math.max(0.82, availTextW / maxLeftW); 进一步允许自适应下潜至 0.60
    const factor = Math.max(0.60, availTextW / maxLeftW);
    titleSize = Math.max(7, Math.round(titleSize * factor));
    sublineSize = Math.max(6, Math.round(sublineSize * factor));
  }

  // 4. 绘制左侧：意境题签与参数排版
  context.save();
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  // 主行：去有风的地方（自适应截断防护，保证 >= 16px 安全隔离带）
  context.fillStyle = '#243A47';
  context.font = `bold italic ${titleSize}px "Georgia", "Noto Serif SC", serif`;
  let drawTitle = titleText;
  if (availTextW <= 12) {
    drawTitle = '';
  } else if (context.measureText(drawTitle).width > availTextW && availTextW > 0) {
    while (drawTitle.length > 1 && context.measureText(drawTitle + '…').width > availTextW) {
      drawTitle = drawTitle.substring(0, drawTitle.length - 1);
    }
    drawTitle += '…';
    if (context.measureText(drawTitle).width > availTextW) {
      drawTitle = '';
    }
  }
  if (drawTitle) {
    context.fillText(drawTitle, textStartX, centerY - bannerH * 0.15);
  }

  // 副行：机型与光学参数（若过长则安全截断）
  if (sublineText) {
    context.fillStyle = '#5A7382';
    context.font = `500 ${sublineSize}px monospace, "Noto Sans SC", sans-serif`;
    let drawSub = sublineText;
    if (availTextW <= 12) {
      drawSub = '';
    } else if (context.measureText(drawSub).width > availTextW && availTextW > 0) {
      while (drawSub.length > 1 && context.measureText(drawSub + '…').width > availTextW) {
        drawSub = drawSub.substring(0, drawSub.length - 1);
      }
      drawSub += '…';
      if (context.measureText(drawSub).width > availTextW) {
        drawSub = '';
      }
    }
    if (drawSub) {
      context.fillText(drawSub, textStartX, centerY + bannerH * 0.17);
    }
  }
  context.restore();

  // 5. 绘制右侧：复古航空日戳与平滑波浪消资线
  const stampCenterX = showWaves
    ? (px + pw - marginR - waveW - gapBetween - stampR)
    : (px + pw - marginR - stampR);
  const stampCenterY = centerY;

  context.strokeStyle = '#476375';
  context.fillStyle = '#476375';

  // 5.1 拟真手工微倾角盖印（-4.2°）
  context.save();
  context.translate(stampCenterX, stampCenterY);
  context.rotate(-0.073); // -4.2度

  // 外同心圈
  context.lineWidth = Math.max(1.2, 1.5 * scale);
  context.beginPath();
  context.arc(0, 0, stampR, 0, 2 * Math.PI);
  context.stroke();

  // 内同心圈
  context.lineWidth = Math.max(0.7, 0.9 * scale);
  context.beginPath();
  context.arc(0, 0, innerR, 0, 2 * Math.PI);
  context.stroke();

  // 三段式日戳横隔线（两根平行内弦线）
  const chordH = Math.round(innerR * 0.36);
  const chordHalfW = Math.sqrt(Math.max(0, innerR * innerR - chordH * chordH));

  context.lineWidth = Math.max(0.6, 0.8 * scale);
  context.beginPath();
  context.moveTo(-chordHalfW, -chordH);
  context.lineTo(chordHalfW, -chordH);
  context.moveTo(-chordHalfW, chordH);
  context.lineTo(chordHalfW, chordH);
  context.stroke();

  // 上弦弧形文字：AIR MAIL
  const arcR = (stampR + innerR) * 0.5;
  context.font = `bold ${Math.max(5, Math.round(stampR * 0.22))}px sans-serif`;
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  drawArcText(context, 'AIR MAIL', arcR, 0.85);

  // 中舱：日期轮转排版
  const formattedDate = formatPostmarkDate(time);
  context.font = `bold ${Math.max(5, Math.round(innerR * 0.34))}px monospace, sans-serif`;
  context.fillText(formattedDate, 0, 1 * scale);

  // 下弦：三颗微星徽
  context.font = `bold ${Math.max(4, Math.round(stampR * 0.20))}px sans-serif`;
  context.fillText('★   ★   ★', 0, (stampR + innerR) * 0.48);

  context.restore();

  // 5.2 绘制右侧平滑 4 联装波浪消资线
  if (showWaves && waveW > 10) {
    context.save();
    const waveStartX = stampCenterX + stampR + gapBetween;
    const lineSpacing = Math.max(3.2 * scale, Math.round(stampR * 0.25));
    const lineWidth = Math.max(0.8, 1.0 * scale);
    const maxSafeAmp = (lineSpacing - lineWidth) * 0.42;
    const amplitude = Math.max(1.0 * scale, Math.min(maxSafeAmp, lineSpacing * 0.32));
    context.lineWidth = lineWidth;
    drawAerodynamicWaveLines(context, waveStartX, stampCenterY, waveW, lineSpacing, amplitude);
    context.restore();
  }
}


/** 幻彩双色框水印（蔡司蓝到暖橙渐变外框线） */
function paintGradientFrameWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;
  const pr = geometry.cornerRadius * scale;

  const bannerH = h - (py + ph);

  // 1. 照片外围绘制幻彩对角线渐变线
  const grad = context.createLinearGradient(px, py, px + pw, py + ph);
  grad.addColorStop(0, '#00D2FF'); // 蔡司极光青
  grad.addColorStop(0.5, '#0055FF'); // 科技深蓝
  grad.addColorStop(1, '#FF7A00'); // 暖橙

  const frameGap = 4 * scale;
  context.strokeStyle = grad;
  context.lineWidth = Math.max(1.8, 2.5 * scale);

  if (pr > 0) {
    drawRoundedRectPath(context, px - frameGap, py - frameGap, pw + frameGap * 2, ph + frameGap * 2, pr + frameGap);
    context.stroke();
  } else {
    context.strokeRect(px - frameGap, py - frameGap, pw + frameGap * 2, ph + frameGap * 2);
  }

  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;

  const r = (safe.colorArgb >>> 16) & 255;
  const g = (safe.colorArgb >>> 8) & 255;
  const b = safe.colorArgb & 255;
  const isDark = (0.299 * r + 0.587 * g + 0.114 * b) < 140;

  const primaryColor = isDark ? '#FFFFFF' : '#141414';
  const secondaryColor = isDark ? '#A0AAB2' : '#606970';

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, device);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? wm.logo : 'none';
  const displayDevice = formatWatermarkDeviceText(device, logo, hasLogo);

  // 2. 左侧：机型与光学参数
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  if (displayDevice) {
    context.fillStyle = primaryColor;
    context.font = `bold ${Math.max(10, Math.round(bannerH * 0.24))}px sans-serif`;
    context.fillText(displayDevice, px, centerY - bannerH * 0.14);
  }

  if (params) {
    context.fillStyle = secondaryColor;
    context.font = `400 ${Math.max(8, Math.round(bannerH * 0.16))}px monospace, sans-serif`;
    context.fillText(params, px, centerY + bannerH * 0.16);
  }

  // 3. 右侧：品牌 Badge
  if (hasLogo) {
    const badgeSize = Math.max(14, Math.round(bannerH * 0.44));
    const badgeW = getLogoBadgeWidth(context, logo, badgeSize);
    paintLogoBadge(context, logo, px + pw - badgeW, centerY, badgeSize, primaryColor);
  }
}

/** 皮革彩虹标水印（碳黑底卡、点阵参数、复古六色彩虹徽章） */
function paintLeatherBadgeWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;

  // 1. 照片四周内沉暗调微边框
  context.strokeStyle = 'rgba(255, 255, 255, 0.12)';
  context.lineWidth = Math.max(1, 1.2 * scale);
  context.strokeRect(px - 1 * scale, py - 1 * scale, pw + 2 * scale, ph + 2 * scale);

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  // 2. 左侧：复古点阵/等宽设备与参数
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  if (device) {
    context.fillStyle = '#EDEAE6';
    context.font = `bold ${Math.max(10, Math.round(bannerH * 0.22))}px monospace, sans-serif`;
    context.fillText(device, px, centerY - bannerH * 0.14);
  }

  const line2 = [params, time].filter((s: string) => s.length > 0).join('  ·  ');
  if (line2) {
    context.fillStyle = '#9E978F';
    context.font = `400 ${Math.max(8, Math.round(bannerH * 0.15))}px monospace, sans-serif`;
    context.fillText(line2, px, centerY + bannerH * 0.16);
  }

  // 3. 右侧：经典六色彩虹条纹质感徽章
  const badgeH = Math.round(bannerH * 0.42);
  const badgeW = Math.round(badgeH * 2.2);
  const badgeX = px + pw - badgeW;
  const badgeY = centerY - badgeH * 0.5;

  // 徽章底卡
  context.fillStyle = '#2B2927';
  context.fillRect(badgeX, badgeY, badgeW, badgeH);
  context.strokeStyle = '#423F3C';
  context.lineWidth = Math.max(0.8, 1 * scale);
  context.strokeRect(badgeX, badgeY, badgeW, badgeH);

  // 六色彩虹横条纹（左侧 ribbon）
  const rainbowColors = ['#E53935', '#FB8C00', '#FDD835', '#43A047', '#1E88E5', '#8E24AA'];
  const stripeW = 3 * scale;
  for (let i = 0; i < rainbowColors.length; i++) {
    context.fillStyle = rainbowColors[i];
    context.fillRect(badgeX + i * stripeW, badgeY, stripeW, badgeH);
  }

  // 徽章文字 "VIVID"
  context.fillStyle = '#FFFFFF';
  context.font = `bold ${Math.max(7, Math.round(badgeH * 0.42))}px sans-serif`;
  context.textAlign = 'center';
  context.fillText('VIVID', badgeX + (rainbowColors.length * stripeW) + (badgeW - rainbowColors.length * stripeW) * 0.5, centerY);
}

/** 经典极简旁轴/微单矢量相机图符 SVG 路径（32x24 视口，4:3 典雅画幅，非零环绕数负空间挖空） */
export const MINT_CAMERA_ICON_SVG: string =
  'M 4 5 ' +
  'h 7 V 3.5 c 0 -0.4 0.3 -0.7 0.7 -0.7 h 2.6 c 0.4 0 0.7 0.3 0.7 0.7 V 5 ' +
  'h 8 V 3 c 0 -0.4 0.3 -0.7 0.7 -0.7 h 2.6 c 0.4 0 0.7 0.3 0.7 0.7 V 5 ' +
  'H 29.5 C 30.9 5 32 6.1 32 7.5 v 11 c 0 1.4 -1.1 2.5 -2.5 2.5 H 2.5 C 1.1 21 0 19.9 0 18.5 v -11 C 0 6.1 1.1 5 2.5 5 H 4 Z ' +
  'M 4.5 7.5 ' +
  'v 2 c 0 0.3 0.2 0.5 0.5 0.5 h 3 c 0.3 0 0.5 -0.2 0.5 -0.5 v -2 c 0 -0.3 -0.2 -0.5 -0.5 -0.5 h -3 c -0.3 0 -0.5 0.2 -0.5 0.5 Z ' +
  'M 10.5 8 ' +
  'v 1.2 c 0 0.3 0.2 0.5 0.5 0.5 h 1.8 c 0.3 0 0.5 -0.2 0.5 -0.5 V 8 c 0 -0.3 -0.2 -0.5 -0.5 -0.5 H 11 c -0.3 0 -0.5 0.2 -0.5 0.5 Z ' +
  'M 18.5 7.5 ' +
  'a 5.5 5.5 0 1 0 0 11 a 5.5 5.5 0 1 0 0 -11 Z ' +
  'M 18.5 9 ' +
  'a 4 4 0 1 1 0 8 a 4 4 0 1 1 0 -8 Z ' +
  'M 18.5 11 ' +
  'a 2 2 0 1 0 0 4 a 2 2 0 1 0 0 -4 Z';

export const MINT_CAMERA_SVG: string = MINT_CAMERA_ICON_SVG;

let mintCameraIconPath: Path2D | null = null;

export function getMintCameraIconPath(): Path2D {
  if (!mintCameraIconPath) {
    mintCameraIconPath = new Path2D(MINT_CAMERA_ICON_SVG);
  }
  return mintCameraIconPath;
}

export function getMintCameraPath(): Path2D {
  return getMintCameraIconPath();
}

/** 清新薄荷绿水印（清新薄荷底条、微单/品牌矢量图标、防撞自适应白瓷胶囊） */
function paintMintFilmWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const px = geometry.photoRect.x * scale;
  const py = geometry.photoRect.y * scale;
  const pw = geometry.photoRect.width * scale;
  const ph = geometry.photoRect.height * scale;

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const hasDevice = !!(wm.showDevice && wm.deviceModel && wm.deviceModel.trim().length > 0);
  const rawDevice = hasDevice ? wm.deviceModel.trim() : '';

  // 1. 品牌徽标识别与去重联动
  const isDuplicated = isLogoDuplicatedWithDevice(wm.logo, rawDevice);
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none' && !isDuplicated);
  const logo = hasLogo ? (wm.logo as string) : 'none';
  const displayDevice = formatWatermarkDeviceText(rawDevice, logo, hasLogo);

  // 参数提取与规范化（清洗多余 sec 单位，空格标准化为中间点 · 分隔）
  const hasParams = !!(wm.showParams && wm.paramsText && wm.paramsText.trim().length > 0);
  let paramsText = hasParams ? wm.paramsText.trim().replace(/\s*sec\.?s?/gi, 's').replace(/\s+/g, ' ') : '';
  if (paramsText) {
    paramsText = paramsText.replace(/\s{2,}/g, ' · ');
  }

  const primaryColor = '#1D453B'; // 经典高对比深薄荷墨绿

  // 2. 左侧尺寸测算
  const baseSize = Math.max(9, Math.round(bannerH * 0.22));
  let iconW = 0;
  const iconGap = Math.max(6 * scale, Math.round(baseSize * 0.45));

  if (hasLogo) {
    iconW = getLogoBadgeWidth(context, logo, baseSize);
  } else {
    // 极简旁轴/微单矢量图标（宽高比 32:24）
    iconW = Math.round(baseSize * (32 / 24));
  }

  context.font = `bold ${baseSize}px sans-serif`;
  const effectiveDeviceText = displayDevice || (hasDevice ? '' : 'MINT CAMERA');
  const deviceW = effectiveDeviceText ? context.measureText(effectiveDeviceText).width : 0;
  const leftW = iconW + (effectiveDeviceText ? (iconGap + deviceW) : 0);

  // 3. 右侧白瓷胶囊尺寸测算
  let tagW = 0;
  let tagH = 0;
  let tagFontSize = 0;
  if (paramsText) {
    tagH = Math.max(16 * scale, Math.round(bannerH * 0.36)); // 比重由 0.44 优化为 0.36
    tagFontSize = Math.max(7, Math.round(tagH * 0.50)); // 内部字体占比优化为 50%
    context.font = `500 ${tagFontSize}px monospace, sans-serif`;
    const textW = context.measureText(paramsText).width;
    const horizontalPad = Math.round(tagH * 0.6); // 保证两端充足半圆留白
    tagW = textW + horizontalPad * 2;
  }

  // 4. 防撞与自适应缩放计算
  const availW = pw;
  const minGap = Math.max(12 * scale, 12);
  const maxTagCap = Math.max(20 * scale, Math.min(availW * 0.65, availW - minGap - 30 * scale));
  if (tagW > maxTagCap && availW > 0) {
    tagW = Math.min(tagW, maxTagCap);
  }

  let shrink = 1.0;
  if (leftW + minGap + tagW > availW) {
    shrink = Math.max(0.70, (availW - minGap) / (leftW + tagW));
  }

  let finalTagW = tagW > 0 ? Math.round(tagW * shrink) : 0;
  if (finalTagW > availW) {
    finalTagW = Math.max(0, availW);
  }

  context.save();
  context.textBaseline = 'middle';

  // 5. 绘制左侧图标与机型
  let curX = px;
  if (hasLogo) {
    paintLogoBadge(context, logo, curX, centerY, Math.round(baseSize * shrink), primaryColor);
    curX += Math.round((iconW + iconGap) * shrink);
  } else {
    // 绘制精致旁轴微单矢量图符
    const camH = Math.round(baseSize * shrink);
    const camW = Math.round(camH * (32 / 24));
    const camScale = camH / 24;
    const camTopY = centerY - camH * 0.5;

    context.save();
    context.translate(curX, camTopY);
    context.scale(camScale, camScale);
    context.fillStyle = primaryColor;
    context.fill(getMintCameraIconPath());
    context.restore();

    curX += camW + Math.round(iconGap * shrink);
  }

  if (effectiveDeviceText) {
    context.fillStyle = primaryColor;
    context.font = `bold ${Math.round(baseSize * shrink)}px sans-serif`;
    context.textAlign = 'left';

    // 极端宽度下安全截断防护
    const maxTextW = (px + pw - (tagW > 0 ? (finalTagW + minGap) : 0)) - curX;
    let textToDraw = effectiveDeviceText;
    if (maxTextW <= 12) {
      textToDraw = '';
    } else if (context.measureText(textToDraw).width > maxTextW && maxTextW > 0) {
      while (textToDraw.length > 1 && context.measureText(textToDraw + '…').width > maxTextW) {
        textToDraw = textToDraw.substring(0, textToDraw.length - 1);
      }
      textToDraw += '…';
      if (context.measureText(textToDraw).width > maxTextW) {
        textToDraw = '';
      }
    }
    if (textToDraw) {
      context.fillText(textToDraw, curX, centerY);
    }
  }

  // 6. 绘制右侧白瓷半透参数胶囊
  if (paramsText && tagW > 0 && finalTagW > 0) {
    const finalTagH = Math.round(tagH * shrink);
    const tagX = px + pw - finalTagW;
    const tagY = centerY - finalTagH * 0.5;
    const radius = finalTagH * 0.5;
    const pad = Math.round(finalTagH * 0.6);
    const maxInnerW = Math.max(0, finalTagW - pad * 2);

    // 白瓷半透底色
    context.fillStyle = 'rgba(255, 255, 255, 0.90)';
    drawRoundedRectPath(context, tagX, tagY, finalTagW, finalTagH, radius);
    context.fill();

    // 微光发丝边
    context.strokeStyle = 'rgba(29, 69, 59, 0.10)';
    context.lineWidth = Math.max(0.6, 0.8 * scale);
    context.stroke();

    // 胶囊文字（自适应截断）
    const currentTagFontSize = Math.round(tagFontSize * shrink);
    context.font = `500 ${currentTagFontSize}px monospace, sans-serif`;
    if (maxInnerW <= 12) {
      paramsText = '';
    } else if (context.measureText(paramsText).width > maxInnerW && maxInnerW > 0) {
      while (paramsText.length > 1 && context.measureText(paramsText + '…').width > maxInnerW) {
        paramsText = paramsText.substring(0, paramsText.length - 1);
      }
      paramsText += '…';
      if (context.measureText(paramsText).width > maxInnerW) {
        paramsText = '';
      }
    }

    if (paramsText) {
      context.fillStyle = '#154035';
      context.textAlign = 'center';
      context.fillText(paramsText, tagX + finalTagW * 0.5, centerY);
    }
  }

  context.restore();
}


/** 极简细白条水印（超窄精巧现代画廊细栏、微缩等宽品牌与年份） */
function paintSlimWhiteWatermark(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry,
  safe: BorderState,
  scale: number
): void {
  const wm = safe.watermark;
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const photoBottom = (geometry.photoRect.y + geometry.photoRect.height) * scale;
  const bannerH = h - photoBottom;
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = photoBottom + bannerH * 0.5;
  const marginX = 14 * scale;

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim().toUpperCase() : 'LEICA M11';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  // 左侧：纯黑微缩品牌机型
  context.fillStyle = '#111111';
  context.font = `600 ${Math.max(8, Math.round(bannerH * 0.32))}px sans-serif`;
  context.textAlign = 'left';
  context.textBaseline = 'middle';
  context.fillText(device, marginX, centerY);

  // 右侧：微缩参数与年份
  const rightText = [params, time].filter((s: string) => s.length > 0).join('   ');
  if (rightText) {
    context.fillStyle = '#666666';
    context.font = `400 ${Math.max(7, Math.round(bannerH * 0.28))}px monospace, sans-serif`;
    context.textAlign = 'right';
    context.fillText(rightText, w - marginX, centerY);
  }
}
