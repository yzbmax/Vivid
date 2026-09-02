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
  clampBorderShadow,
  clampBorderWidthRatio
} from '../../../models/SharedContracts';
import { normalizeBorderTemplateId } from './BorderState';

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

  if (templateId === 'none' || widthRatio === 0) {
    return {
      outputWidth: input.photoWidth,
      outputHeight: input.photoHeight,
      photoRect: { x: 0, y: 0, width: input.photoWidth, height: input.photoHeight },
      insets: { top: 0, right: 0, bottom: 0, left: 0 },
      shadowSpread: 0,
      decorations: [],
      templateId: 'none'
    };
  }

  if (templateId === 'polaroid') {
    return resolvePolaroid(input.photoWidth, input.photoHeight, widthRatio);
  }
  if (templateId === 'film_negative') {
    return resolveFilmNegative(input.photoWidth, input.photoHeight, widthRatio);
  }
  if (templateId === 'floating_shadow') {
    return resolveFloatingShadow(input.photoWidth, input.photoHeight, widthRatio, shadow);
  }
  if (templateId === 'scroll_mount') {
    return resolveScrollMount(input.photoWidth, input.photoHeight, widthRatio, shadow);
  }
  // paper_white / ink_black / 未知模板：对称边框
  return resolveSymmetric(input.photoWidth, input.photoHeight, widthRatio, templateId);
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
    templateId
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
    templateId: 'floating_shadow'
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
    templateId: 'polaroid'
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
    templateId: 'film_negative'
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
    templateId: 'scroll_mount'
  };
}
