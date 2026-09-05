/**
 * 边框几何解析器（实施计划 §3.2 / §3.3 / 任务 5）。
 *
 * 纯逻辑，无 ArkUI 依赖。输入照片像素尺寸 + BorderState，输出完整的几何结果。
 * 预览与导出共享同一解析器（按 §3.3 一致性要求，误差 ≤ 1 px）。
 *
 * 坐标约定：
 * - 原点为输出画布左上角
 * - 照片内容区域 = 输出画布减去边框后的矩形
 * - 所有尺寸为像素（输入输出单位一致）
 */

import {
  BorderState,
  clampBorderRadiusRatio,
  clampBorderShadow,
  clampBorderWidthRatio
} from '../../../models/SharedContracts';
import { normalizeBorderTemplateId } from './BorderState';
import { templateSupportsCapability } from './BorderCatalog';

/** 四边宽度（像素）。 */
export interface BorderInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

/** 矩形（像素）。 */
export interface RectPx {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** 装饰元素：用于 film_negative 齿孔、scroll_mount 内线/角标等。 */
export interface BorderDecoration {
  /** 装饰类型：`sprocket`（胶片齿孔）/ `filmNumber`（底片编号）/ `innerLine`（朱砂内线）/ `cornerMark`（角标）。 */
  kind: 'sprocket' | 'filmNumber' | 'innerLine' | 'cornerMark';
  rect: RectPx;
}

/** 边框解析结果。 */
export interface BorderGeometry {
  /** 输出画布总宽度（像素）。 */
  outputWidth: number;
  /** 输出画布总高度（像素）。 */
  outputHeight: number;
  /** 照片内容区域（像素，相对输出画布左上角）。 */
  photoRect: RectPx;
  /** 四边宽度（像素）。 */
  insets: BorderInsets;
  /** 投影扩散范围（像素，非投影模板为 0）。 */
  shadowSpread: number;
  /** 装饰元素数组；`none` 和简单模板为空。 */
  decorations: BorderDecoration[];
  /** 最终使用的 templateId（归一化后）。 */
  templateId: string;
  /** 照片圆角半径（像素）。 */
  cornerRadius: number;
}

/** 解析入参。 */
export interface BorderResolveInput {
  photoWidth: number;
  photoHeight: number;
  border: BorderState;
}

/** 边宽比例按照片短边计算。 */
export function computeBaseBorderWidth(photoWidth: number, photoHeight: number, widthRatio: number): number {
  const shortEdge = Math.min(photoWidth, photoHeight);
  const ratio = clampBorderWidthRatio(widthRatio);
  return Math.round(shortEdge * ratio);
}

/**
 * 解析边框几何。
 *
 * 统一规则：
 * - 照片始终完整显示（不得裁切）；
 * - 边框只向外扩展画布；
 * - 输出画布 = 照片尺寸 + 四边宽度；
 * - `none` 模板：输出 = 照片尺寸，所有装饰为空。
 */
export function resolveBorderGeometry(input: BorderResolveInput): BorderGeometry {
  const templateId = normalizeBorderTemplateId(input.border.templateId);
  const widthRatio = clampBorderWidthRatio(input.border.widthRatio);
  const shadow = clampBorderShadow(input.border.shadowStrength);
  const radiusRatio = clampBorderRadiusRatio(input.border.radiusRatio ?? 0);
  const maxCornerRadius = Math.round(Math.min(input.photoWidth, input.photoHeight) * 0.5);
  const cornerRadius = templateSupportsCapability(templateId, 'radius')
    ? Math.round(maxCornerRadius * radiusRatio)
    : 0;

  if (templateId === 'none' || widthRatio === 0) {
    return {
      outputWidth: input.photoWidth,
      outputHeight: input.photoHeight,
      photoRect: { x: 0, y: 0, width: input.photoWidth, height: input.photoHeight },
      insets: { top: 0, right: 0, bottom: 0, left: 0 },
      shadowSpread: 0,
      decorations: [],
      templateId: 'none',
      cornerRadius: 0
    };
  }

  let geom: BorderGeometry;
  if (templateId === 'polaroid') {
    geom = resolvePolaroid(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'film_negative') {
    geom = resolveFilmNegative(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'floating_shadow') {
    geom = resolveFloatingShadow(input.photoWidth, input.photoHeight, widthRatio, shadow);
  } else if (templateId === 'scroll_mount') {
    geom = resolveScrollMount(input.photoWidth, input.photoHeight, widthRatio, shadow);
  } else if (templateId === 'camera_watermark') {
    geom = resolveCameraWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_master_grid') {
    geom = resolveMasterGridWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_blur_pip') {
    geom = resolveBlurPipWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_cinematic') {
    geom = resolveCinematicWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_retro_film') {
    geom = resolveRetroFilmWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_overlay') {
    geom = resolveOverlayWatermark(input.photoWidth, input.photoHeight);
  } else if (templateId === 'watermark_nordic_gallery') {
    geom = resolveNordicGalleryWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_editorial_mag') {
    geom = resolveEditorialMagWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_contact_sheet') {
    geom = resolveContactSheetWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_oriental_seal') {
    geom = resolveOrientalSealWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_travel_stamp') {
    geom = resolveTravelStampWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_travel_postcard') {
    geom = resolveTravelPostcardWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_gradient_frame') {
    geom = resolveGradientFrameWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_leather_badge') {
    geom = resolveLeatherBadgeWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_mint_film') {
    geom = resolveMintFilmWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else if (templateId === 'watermark_slim_white') {
    geom = resolveSlimWhiteWatermark(input.photoWidth, input.photoHeight, widthRatio);
  } else {
    // paper_white / ink_black / 未知模板：对称边框
    geom = resolveSymmetric(input.photoWidth, input.photoHeight, widthRatio, templateId);
  }

  geom.cornerRadius = cornerRadius;
  return geom;
}

/** 对称边框（paper_white / ink_black / 兜底）。 */
function resolveSymmetric(
  photoWidth: number, photoHeight: number,
  widthRatio: number, templateId: string
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  return {
    outputWidth: photoWidth + bw * 2,
    outputHeight: photoHeight + bw * 2,
    photoRect: { x: bw, y: bw, width: photoWidth, height: photoHeight },
    insets: { top: bw, right: bw, bottom: bw, left: bw },
    shadowSpread: 0,
    decorations: [],
    templateId,
    cornerRadius: 0
  };
}

/** 浮光卡片：对称边框 + 外投影。 */
function resolveFloatingShadow(
  photoWidth: number, photoHeight: number,
  widthRatio: number, shadow: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  // 投影扩散 = 边宽 × shadowStrength × 0.5，最少 0
  const spread = Math.round(bw * shadow * 0.5);
  // 投影只向外扩散（top/left 增加 spread，bottom/right 增加 spread）
  const top = bw + spread;
  const left = bw + spread;
  const bottom = bw + spread;
  const right = bw + spread;
  return {
    outputWidth: photoWidth + left + right,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: left, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right, bottom, left },
    shadowSpread: spread,
    decorations: [],
    templateId: 'floating_shadow',
    cornerRadius: 0
  };
}

/**
 * 拍立得：左右上窄（边宽 × 0.5），底部加宽（边宽 × 2.5）。
 * 保持经典拍立得比例感。
 */
function resolvePolaroid(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(1, Math.round(bw * 0.5));
  const bottom = Math.max(bw, Math.round(bw * 2.5));
  const top = side;
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'polaroid',
    cornerRadius: 0
  };
}

/**
 * 胶片边框：左右对称宽度，底部加宽（用于底片编号），顶部稍宽。
 * 齿孔位于左右两侧，不侵入照片区域。
 */
function resolveFilmNegative(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const left = bw;
  const right = bw;
  const top = Math.max(1, Math.round(bw * 1.2));
  const bottom = Math.max(1, Math.round(bw * 1.8));
  const outW = photoWidth + left + right;
  const outH = photoHeight + top + bottom;

  // 齿孔：左右两侧均匀分布，直径 = 边宽 × 0.4
  const decorations: BorderDecoration[] = [];
  const sprocketDiameter = Math.max(2, Math.round(bw * 0.4));
  const sprocketSpacing = Math.max(sprocketDiameter * 2, Math.round(photoHeight / 8));
  const sprocketCount = Math.max(1, Math.floor(photoHeight / sprocketSpacing));
  const sprocketXLeft = Math.round((left - sprocketDiameter) / 2);
  const sprocketXRight = Math.round(left + photoWidth + (right - sprocketDiameter) / 2);
  const sprocketStartY = top + Math.round((photoHeight - (sprocketCount - 1) * sprocketSpacing) / 2);
  for (let i = 0; i < sprocketCount; i++) {
    const y = sprocketStartY + i * sprocketSpacing - sprocketDiameter / 2;
    decorations.push({
      kind: 'sprocket',
      rect: { x: sprocketXLeft, y: y, width: sprocketDiameter, height: sprocketDiameter }
    });
    decorations.push({
      kind: 'sprocket',
      rect: { x: sprocketXRight, y: y, width: sprocketDiameter, height: sprocketDiameter }
    });
  }

  // 底片编号：底部边框中部一个占位矩形
  const numberWidth = Math.max(4, Math.round(bw * 2));
  const numberHeight = Math.max(2, Math.round(bw * 0.5));
  decorations.push({
    kind: 'filmNumber',
    rect: {
      x: Math.round((outW - numberWidth) / 2),
      y: top + photoHeight + Math.round((bottom - numberHeight) / 2),
      width: numberWidth,
      height: numberHeight
    }
  });

  return {
    outputWidth: outW,
    outputHeight: outH,
    photoRect: { x: left, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right, bottom, left },
    shadowSpread: 0,
    decorations,
    templateId: 'film_negative',
    cornerRadius: 0
  };
}

/**
 * 卷轴装裱：外框（边宽）+ 细朱砂内线（外框内缩 1/4 边宽处）+ 角标（四角）。
 * 内线粗细 = 边宽 × 0.08；角标边长 = 边宽 × 0.3。
 */
function resolveScrollMount(
  photoWidth: number, photoHeight: number,
  widthRatio: number, shadow: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const top = bw;
  const left = bw;
  const bottom = bw;
  const right = bw;
  const outW = photoWidth + left + right;
  const outH = photoHeight + top + bottom;

  const decorations: BorderDecoration[] = [];

  // 朱砂内线：紧贴外框内侧 1/4 边宽位置
  const insetOffset = Math.max(1, Math.round(bw * 0.25));
  const lineThickness = Math.max(1, Math.round(bw * 0.08));
  // 内线覆盖整个外框内缘（4 条细矩形）
  decorations.push({
    kind: 'innerLine',
    rect: {
      x: insetOffset,
      y: insetOffset,
      width: outW - insetOffset * 2,
      height: lineThickness
    }
  }); // 上
  decorations.push({
    kind: 'innerLine',
    rect: {
      x: insetOffset,
      y: outH - insetOffset - lineThickness,
      width: outW - insetOffset * 2,
      height: lineThickness
    }
  }); // 下
  decorations.push({
    kind: 'innerLine',
    rect: {
      x: insetOffset,
      y: insetOffset,
      width: lineThickness,
      height: outH - insetOffset * 2
    }
  }); // 左
  decorations.push({
    kind: 'innerLine',
    rect: {
      x: outW - insetOffset - lineThickness,
      y: insetOffset,
      width: lineThickness,
      height: outH - insetOffset * 2
    }
  }); // 右

  // 四角标（L 形简化为小方块）
  const cornerSize = Math.max(2, Math.round(bw * 0.3));
  const corners: number[][] = [
    [0, 0],                                       // 左上
    [outW - cornerSize, 0],                       // 右上
    [0, outH - cornerSize],                       // 左下
    [outW - cornerSize, outH - cornerSize]        // 右下
  ];
  for (const c of corners) {
    decorations.push({
      kind: 'cornerMark',
      rect: { x: c[0], y: c[1], width: cornerSize, height: cornerSize }
    });
  }

  // 投影（可选）
  const spread = Math.round(bw * shadow * 0.4);

  return {
    outputWidth: outW + spread * 2,
    outputHeight: outH + spread * 2,
    photoRect: { x: left + spread, y: top + spread, width: photoWidth, height: photoHeight },
    insets: { top: top + spread, right: right + spread, bottom: bottom + spread, left: left + spread },
    shadowSpread: spread,
    decorations,
    templateId: 'scroll_mount',
    cornerRadius: 0
  };
}

/**
 * 相机水印边框：四周微窄边框（纯净极简感），底部加宽用于排版机型/Logo/拍摄参数与时间。
 */
function resolveCameraWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.round(bw * 0.15);
  const top = side;
  const bottom = Math.max(36, Math.round(bw * 2.2));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'camera_watermark',
    cornerRadius: 0
  };
}

/**
 * 影展四栏矩阵边框：微窄三边，底部预留大幅留白用于四栏等宽参数矩阵与大师签名。
 */
function resolveMasterGridWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.round(bw * 0.15);
  const top = side;
  const bottom = Math.max(56, Math.round(bw * 2.8));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_master_grid',
    cornerRadius: 0
  };
}

/**
 * 画中画虚化边框：四周较宽外扩画布，底部居中印制相机与参数。
 */
function resolveBlurPipWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(16, Math.round(bw * 0.45));
  const top = Math.max(48, Math.round(bw * 1.4));
  const bottom = Math.max(68, Math.round(bw * 2.2));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_blur_pip',
    cornerRadius: 0
  };
}

/**
 * 电影艺术影集边框：顶部留白用于英文题签，底部留白用于大字机型与参数。
 */
function resolveCinematicWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.round(bw * 0.15);
  const top = Math.max(38, Math.round(bw * 1.6));
  const bottom = Math.max(42, Math.round(bw * 2.0));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_cinematic',
    cornerRadius: 0
  };
}

/**
 * 富士复古胶片边框：拍立得式不对称加宽底栏，相纸复古留白。
 */
function resolveRetroFilmWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.round(bw * 0.35);
  const top = side;
  const bottom = Math.max(48, Math.round(bw * 2.6));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_retro_film',
    cornerRadius: 0
  };
}

/**
 * 无界悬浮水印：画布尺寸完全与原图一致（零外扩），保持原画幅。
 */
function resolveOverlayWatermark(
  photoWidth: number, photoHeight: number
): BorderGeometry {
  return {
    outputWidth: photoWidth,
    outputHeight: photoHeight,
    photoRect: { x: 0, y: 0, width: photoWidth, height: photoHeight },
    insets: { top: 0, right: 0, bottom: 0, left: 0 },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_overlay',
    cornerRadius: 0
  };
}

/**
 * 北欧画廊边框：哈苏中画幅极简留白风格，四周较宽纯白/亚麻纸卡，底部大字距机型与暖橙焦点。
 */
function resolveNordicGalleryWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(20, Math.round(bw * 0.75));
  const top = side;
  const bottom = Math.max(60, Math.round(bw * 1.8));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_nordic_gallery',
    cornerRadius: 0
  };
}

/**
 * 纪实画报边框：国家地理/期刊特辑风格，上下微留边，底部深邃墨黑底带给黄色细标线与经纬度。
 */
function resolveEditorialMagWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(12, Math.round(bw * 0.25));
  const top = Math.max(12, Math.round(bw * 0.25));
  const bottom = Math.max(56, Math.round(bw * 1.8));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_editorial_mag',
    cornerRadius: 0
  };
}

/**
 * 暗房印样边框：柯达银盐胶片接触印相风格，深碳黑底，顶部胶卷金字编号，底部曝光补偿标尺。
 */
function resolveContactSheetWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(16, Math.round(bw * 0.35));
  const top = Math.max(38, Math.round(bw * 1.2));
  const bottom = Math.max(52, Math.round(bw * 1.6));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_contact_sheet',
    cornerRadius: 0
  };
}

/**
 * 文书钤印边框：宋代册页文人古风，宣纸古色留白，底部金石朱砂方印与物候款识。
 */
function resolveOrientalSealWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(18, Math.round(bw * 0.6));
  const top = side;
  const bottom = Math.max(56, Math.round(bw * 1.6));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_oriental_seal',
    cornerRadius: 0
  };
}

/**
 * 齿孔邮票边框：四周留白带有半圆邮票齿孔咬边，底部大号月份序号与旅拍签条。
 */
function resolveTravelStampWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(28, Math.round(bw * 0.8));
  const top = side;
  const bottom = Math.max(64, Math.round(bw * 1.8));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_travel_stamp',
    cornerRadius: 0
  };
}

/**
 * 旅行明信片边框：天青质感相纸，底部经典手写感旅拍标语与复古双圈航空邮戳。
 */
function resolveTravelPostcardWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(24, Math.round(bw * 0.7));
  const top = side;
  const bottom = Math.max(72, Math.round(bw * 2.0));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_travel_postcard',
    cornerRadius: 0
  };
}

/**
 * 幻彩双色框边框：青蓝到暖橙对角线线性渐变外框线，底部蔡司风格机型与光学参数。
 */
function resolveGradientFrameWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(16, Math.round(bw * 0.45));
  const top = side;
  const bottom = Math.max(56, Math.round(bw * 1.6));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_gradient_frame',
    cornerRadius: 0
  };
}

/**
 * 皮革彩虹标边框：碳黑皮革质感底卡，点阵字体，右侧六色彩虹质感标与签名。
 */
function resolveLeatherBadgeWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(18, Math.round(bw * 0.5));
  const top = side;
  const bottom = Math.max(62, Math.round(bw * 1.8));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_leather_badge',
    cornerRadius: 0
  };
}

/**
 * 清新薄荷绿边框：清新浅薄荷绿底条，相机矢量图标，双行拍摄参数。
 */
function resolveMintFilmWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = Math.max(16, Math.round(bw * 0.4));
  const top = side;
  const bottom = Math.max(58, Math.round(bw * 1.7));
  return {
    outputWidth: photoWidth + side * 2,
    outputHeight: photoHeight + top + bottom,
    photoRect: { x: side, y: top, width: photoWidth, height: photoHeight },
    insets: { top, right: side, bottom, left: side },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_mint_film',
    cornerRadius: 0
  };
}

/**
 * 极简细白条边框：超窄精巧现代画廊细栏，微缩等宽品牌与年份。
 */
function resolveSlimWhiteWatermark(
  photoWidth: number, photoHeight: number,
  widthRatio: number
): BorderGeometry {
  const bw = computeBaseBorderWidth(photoWidth, photoHeight, widthRatio);
  const side = 0;
  const top = 0;
  const bottom = Math.max(36, Math.round(bw * 0.95));
  return {
    outputWidth: photoWidth,
    outputHeight: photoHeight + bottom,
    photoRect: { x: 0, y: 0, width: photoWidth, height: photoHeight },
    insets: { top: 0, right: 0, bottom, left: 0 },
    shadowSpread: 0,
    decorations: [],
    templateId: 'watermark_slim_white',
    cornerRadius: 0
  };
}

