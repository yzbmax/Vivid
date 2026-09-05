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
  // 实色衬底使 JPEG 与 PNG 的阴影区域保持一致；画中画虚化使用原图模糊背景，不填充不透明实色底。
  if (geometry.templateId !== 'watermark_blur_pip') {
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
    return Math.round(badgeH * 1.5);
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
  if (logo === 'xmage') {
    context.font = `800 ${Math.round(size * 0.9)}px sans-serif`;
    return context.measureText('XMAGE').width;
  }
  if (logo === 'apple') {
    context.font = `600 ${Math.round(size * 0.9)}px sans-serif`;
    return context.measureText(' iPhone').width;
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
  if (logo === 'huawei') {
    context.font = `bold ${Math.round(size * 0.8)}px sans-serif`;
    return Math.round(size * 0.9) + context.measureText('HUAWEI').width + 4;
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
  const hasLogo = !!(wm.showLogo && wm.logo && wm.logo !== 'none');
  const hasParams = !!(wm.showParams && wm.paramsText && wm.paramsText.trim().length > 0);
  const hasTime = !!(wm.showTime && wm.timeText && wm.timeText.trim().length > 0);

  if (!hasDevice && !hasLogo && !hasParams && !hasTime) {
    return;
  }

  // 整理参数文本（统一去除多余空格与可能的冗余 "sec.s"）
  const paramsText = hasParams ? wm.paramsText.trim().replace(/\s*sec\.?s?/gi, 's').replace(/\s+/g, ' ') : '';
  const timeText = hasTime ? wm.timeText.trim() : '';
  const deviceModel = hasDevice ? wm.deviceModel.trim() : '';
  const logo = hasLogo ? wm.logo : 'none';

  const basePrimary = Math.max(9, Math.round(bannerH * 0.22));
  const baseSecondary = Math.max(8, Math.round(bannerH * 0.16));

  // 1. 预估单行左侧与右侧宽度
  context.font = `600 ${basePrimary}px sans-serif`;
  const singleLineDeviceW = hasDevice ? context.measureText(deviceModel).width : 0;
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
    const stackDeviceW = hasDevice ? context.measureText(deviceModel).width : 0;
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
      context.fillText(deviceModel, marginX, hasLogo ? topY : centerY);
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
      context.fillText(deviceModel, curX, centerY);
      curX += context.measureText(deviceModel).width + curGap;

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
    // 经典蔡司蓝方标
    const badgeH = Math.round(size * 1.15);
    const badgeW = Math.round(badgeH * 1.5);
    context.fillStyle = '#0047BA';
    context.fillRect(x, centerY - badgeH * 0.5, badgeW, badgeH);
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${Math.round(badgeH * 0.5)}px sans-serif`;
    context.textAlign = 'center';
    context.fillText('ZEISS', x + badgeW * 0.5, centerY);
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
  } else if (logo === 'xmage') {
    context.fillStyle = '#C49A5B';
    context.font = `800 ${Math.round(size * 0.9)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('XMAGE', x, centerY);
  } else if (logo === 'apple') {
    context.fillStyle = defaultTextColor;
    context.font = `600 ${Math.round(size * 0.9)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText(' iPhone', x, centerY);
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
  } else if (logo === 'huawei') {
    // 华为红色花瓣 + HUAWEI
    const iconR = Math.round(size * 0.45);
    context.fillStyle = '#E4002B';
    context.beginPath();
    context.arc(x + iconR, centerY, iconR, 0, 2 * Math.PI);
    context.fill();
    context.fillStyle = defaultTextColor;
    context.font = `bold ${Math.round(size * 0.8)}px sans-serif`;
    context.textAlign = 'left';
    context.fillText('HUAWEI', x + iconR * 2 + 4, centerY);
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
  const labelColor = isDark ? '#888888' : '#777777';
  const dividerColor = isDark ? '#333333' : '#E5E5E5';

  // 1. 上半部：艺术手写签或所选 Logo
  const topCenterY = photoBottom + bannerH * 0.28;
  const scriptSize = Math.max(10, Math.round(bannerH * 0.16));
  context.textAlign = 'center';
  context.textBaseline = 'middle';

  if (wm.showLogo && wm.logo && wm.logo !== 'none' && wm.logo !== 'master') {
    const logoW = getLogoBadgeWidth(context, wm.logo, scriptSize);
    paintLogoBadge(context, wm.logo, w * 0.5 - logoW * 0.5, topCenterY, scriptSize, textColor);
  } else {
    // 经典 Just shoot photos · MASTER SERIES 签名
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
  const sMatch = p.match(/(\d+\/\d+|\d+(\.\d+)?)\s*s?/i);
  const colData: MasterGridColumn[] = [
    { val: isoMatch ? isoMatch[1] : '400', lbl: 'ISO' },
    { val: fMatch ? fMatch[1] : '2.1', lbl: 'F' },
    { val: mmMatch ? mmMatch[1] : '140', lbl: 'mm' },
    { val: sMatch ? sMatch[1] : '1/2787', lbl: 'S' }
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

/** 弥散虚化画中画水印（参考图 3） */
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

  // 2. 顶部策展铭文（与用户参考图 3 一致）
  const topH = geometry.photoRect.y * scale;
  if (topH >= 36 * scale) {
    const topCenterY = topH * 0.5;
    const titleSize = Math.max(9, Math.round(topH * 0.22));

    context.textAlign = 'center';
    context.textBaseline = 'middle';

    // Line 1: IDEATED BY ...
    context.fillStyle = 'rgba(255, 255, 255, 0.70)';
    context.font = `600 ${Math.max(7, Math.round(titleSize * 0.52))}px monospace, sans-serif`;
    const brandName = (wm && wm.showLogo && wm.logo && wm.logo !== 'none' && wm.logo !== 'master')
      ? wm.logo.toUpperCase()
      : 'MASTER SERIES';
    context.fillText(`IDEATED BY ${brandName}`, w * 0.5, topCenterY - titleSize * 0.75);

    // Line 2: The decisive moment
    context.fillStyle = '#FFFFFF';
    context.font = `italic 500 ${titleSize}px Georgia, "Noto Serif SC", serif`;
    context.fillText('The decisive moment', w * 0.5, topCenterY);

    // Line 3: PHOTOGRAPH
    context.fillStyle = 'rgba(255, 255, 255, 0.60)';
    context.font = `500 ${Math.max(6, Math.round(titleSize * 0.45))}px monospace, sans-serif`;
    context.fillText('P H O T O G R A P H', w * 0.5, topCenterY + titleSize * 0.75);
  }

  if (!wm || bannerH <= 0) {
    return;
  }

  // 3. 底部居中机型与参数
  const centerY = photoBottom + bannerH * 0.5;
  const primarySize = Math.max(11, Math.round(bannerH * 0.18));
  const secondarySize = Math.max(9, Math.round(bannerH * 0.12));

  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';
  const hasLogo = wm.showLogo && wm.logo && wm.logo !== 'none';
  const logo = wm.logo ?? 'none';

  context.textBaseline = 'middle';
  const topY = params ? (centerY - bannerH * 0.15) : centerY;
  const botY = centerY + bannerH * 0.15;

  // Line 1: Logo + Device 居中
  context.font = `bold ${primarySize}px sans-serif`;
  const devW = device.length > 0 ? context.measureText(device).width : 0;
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
    context.fillText(device, startX + logoW + gap, topY);
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
  const logo = (wm.showLogo && wm.logo && wm.logo !== 'none') ? wm.logo : 'fujifilm';

  context.textBaseline = 'middle';

  // 左侧：经典复古 Logo + 设备名
  let curX = marginX;
  const logoW = getLogoBadgeWidth(context, logo, primarySize);
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
  const logo = (wm.showLogo && wm.logo && wm.logo !== 'none') ? wm.logo : 'sony';

  context.textBaseline = 'middle';

  // 左侧：白底加粗 Logo + 设备型号
  let curX = marginX;
  const logoW = getLogoBadgeWidth(context, logo, primarySize);
  if (logoW > 0) {
    paintLogoBadge(context, logo, curX, centerY, primarySize, '#FFFFFF');
    curX += logoW + 8 * scale;
  }
  if (device.length > 0) {
    if (logoW > 0) {
      context.fillStyle = 'rgba(255, 255, 255, 0.6)';
      context.font = `300 ${primarySize}px sans-serif`;
      context.fillText('|', curX, centerY - 1);
      curX += context.measureText('|').width + 8 * scale;
    }
    context.fillStyle = '#FFFFFF';
    context.font = `bold ${primarySize}px sans-serif`;
    context.textAlign = 'left';
    context.fillText(device, curX, centerY);
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
  const hasLogo = wm.showLogo && wm.logo && wm.logo !== 'none';
  const logo = wm.logo ?? 'none';

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

  context.fillStyle = '#7C756B';
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

/** 旅行明信片水印（天青相纸、手写旅行题签、双圈日戳航空邮戳） */
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

  // 1. 照片白色勾边
  context.strokeStyle = 'rgba(255, 255, 255, 0.9)';
  context.lineWidth = Math.max(1.5, 2 * scale);
  context.strokeRect(px - 1 * scale, py - 1 * scale, pw + 2 * scale, ph + 2 * scale);

  const bannerH = h - (py + ph);
  if (!wm || bannerH <= 0) {
    return;
  }

  const centerY = (py + ph) + bannerH * 0.5;
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';
  const time = (wm.showTime && wm.timeText) ? wm.timeText.trim() : '';

  // 2. 左侧：旅拍手写意境标题与机型
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  const titleSize = Math.max(12, Math.round(bannerH * 0.28));
  context.fillStyle = '#243A47';
  context.font = `bold italic ${titleSize}px "Georgia", "Noto Serif SC", serif`;
  context.fillText('去有风的地方', px, centerY - bannerH * 0.15);

  const subline = [device, params || time].filter((s: string) => s.length > 0).join('  ·  ');
  if (subline) {
    context.fillStyle = '#5A7382';
    context.font = `400 ${Math.max(8, Math.round(bannerH * 0.15))}px sans-serif`;
    context.fillText(subline, px, centerY + bannerH * 0.16);
  }

  // 3. 右侧：双圈日戳邮戳（Concentric postmark + wavy cancellation lines）
  const stampR = Math.round(bannerH * 0.36);
  const stampX = px + pw - stampR - 28 * scale;
  const stampY = centerY;

  context.strokeStyle = '#476375';
  context.lineWidth = Math.max(1, 1.4 * scale);

  // 外圈
  context.beginPath();
  context.arc(stampX, stampY, stampR, 0, 2 * Math.PI);
  context.stroke();

  // 内圈
  context.beginPath();
  context.arc(stampX, stampY, stampR * 0.72, 0, 2 * Math.PI);
  context.stroke();

  // 邮戳文字
  context.fillStyle = '#476375';
  context.textAlign = 'center';
  context.font = `bold ${Math.max(6, Math.round(stampR * 0.34))}px sans-serif`;
  context.fillText('POSTAL', stampX, stampY - stampR * 0.18);
  context.font = `400 ${Math.max(5, Math.round(stampR * 0.28))}px monospace`;
  context.fillText(time ? time.substring(0, 7) : '2026.09', stampX, stampY + stampR * 0.26);

  // 波浪消资线（右侧 3 条）
  const waveStartX = stampX + stampR + 3 * scale;
  const waveW = 24 * scale;
  context.lineWidth = Math.max(0.8, 1.0 * scale);
  for (let i = -1; i <= 1; i++) {
    const wy = stampY + i * 5 * scale;
    context.beginPath();
    context.moveTo(waveStartX, wy);
    context.quadraticCurveTo(waveStartX + waveW * 0.3, wy - 3 * scale, waveStartX + waveW * 0.6, wy);
    context.quadraticCurveTo(waveStartX + waveW * 0.85, wy + 3 * scale, waveStartX + waveW, wy);
    context.stroke();
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
  const logo = (wm.showLogo && wm.logo) ? wm.logo : 'zeiss';

  // 2. 左侧：机型与光学参数
  context.textAlign = 'left';
  context.textBaseline = 'middle';

  if (device) {
    context.fillStyle = primaryColor;
    context.font = `bold ${Math.max(10, Math.round(bannerH * 0.24))}px sans-serif`;
    context.fillText(device, px, centerY - bannerH * 0.14);
  }

  if (params) {
    context.fillStyle = secondaryColor;
    context.font = `400 ${Math.max(8, Math.round(bannerH * 0.16))}px monospace, sans-serif`;
    context.fillText(params, px, centerY + bannerH * 0.16);
  }

  // 3. 右侧：品牌 Badge
  const badgeSize = Math.max(14, Math.round(bannerH * 0.44));
  const badgeW = getLogoBadgeWidth(context, logo, badgeSize);
  paintLogoBadge(context, logo, px + pw - badgeW, centerY, badgeSize, primaryColor);
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

/** 清新薄荷绿水印（清新薄荷底条、极简相机矢量小标与胶囊参数） */
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
  const device = (wm.showDevice && wm.deviceModel) ? wm.deviceModel.trim() : '';
  const params = (wm.showParams && wm.paramsText) ? wm.paramsText.trim() : '';

  // 1. 左侧：极简矢量相机图标
  const camSize = Math.round(bannerH * 0.36);
  const camX = px;
  const camY = centerY - camSize * 0.5;

  context.strokeStyle = '#1D453B';
  context.lineWidth = Math.max(1.2, 1.5 * scale);

  // 相机机身
  drawRoundedRectPath(context, camX, camY + camSize * 0.2, camSize * 1.3, camSize * 0.8, 3 * scale);
  context.stroke();

  // 镜头圆圈
  context.beginPath();
  context.arc(camX + camSize * 0.65, camY + camSize * 0.6, camSize * 0.24, 0, 2 * Math.PI);
  context.stroke();

  // 快门小凸起
  context.strokeRect(camX + camSize * 0.25, camY + camSize * 0.08, camSize * 0.3, camSize * 0.12);

  // 机型文字
  const labelX = camX + camSize * 1.5;
  context.fillStyle = '#1D453B';
  context.font = `bold ${Math.max(10, Math.round(bannerH * 0.22))}px sans-serif`;
  context.textAlign = 'left';
  context.textBaseline = 'middle';
  context.fillText(device || 'MINT CAMERA', labelX, centerY);

  // 2. 右侧：纯白半透明胶囊参数标签
  if (params) {
    const tagH = Math.round(bannerH * 0.44);
    context.font = `500 ${Math.max(8, Math.round(tagH * 0.44))}px monospace, sans-serif`;
    const tagW = context.measureText(params).width + 16 * scale;
    const tagX = px + pw - tagW;
    const tagY = centerY - tagH * 0.5;

    context.fillStyle = 'rgba(255, 255, 255, 0.85)';
    drawRoundedRectPath(context, tagX, tagY, tagW, tagH, tagH * 0.5);
    context.fill();

    context.fillStyle = '#154035';
    context.textAlign = 'center';
    context.fillText(params, tagX + tagW * 0.5, centerY);
  }
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
    context.fillStyle = '#777777';
    context.font = `400 ${Math.max(7, Math.round(bannerH * 0.28))}px monospace, sans-serif`;
    context.textAlign = 'right';
    context.fillText(rightText, w - marginX, centerY);
  }
}

