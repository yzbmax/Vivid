import { MaskData, RectData } from '../models/SegmentationModels';

/**
 * 蒙版数据纯函数工具（无 Kit 依赖，本地单测可加载）。
 *
 * 职责：mattingList → Uint8Array 权重转换（V2 §5）、RawMask 强制校验（V2 §8）、
 * Debug 四视图的灰度/叠加缓冲生成（V2 §9）。
 *
 * 红线：本文件不做任何二值化（mask>=128?255:0 禁止，V2 §10），
 * 输出始终保留 Core Vision 的连续 0~255 软边缘权重。
 */

/**
 * Int32Array mattingList → 逐元素钳制到 0~255 的 Uint8Array。
 *
 * Core Vision 原始返回 Int32Array；转 Uint8Array 降低一半以上内存占用（V2 §5）。
 * 越界值（<0 或 >255）按边界钳制，不抛错——校验交给 validateRawMask 的语义检查。
 */
export function mattingListToWeights(src: Int32Array): Uint8Array {
  const n = src.length;
  const out = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    const v = src[i];
    if (v <= 0) {
      out[i] = 0;
    } else if (v >= 255) {
      out[i] = 255;
    } else {
      out[i] = v;
    }
  }
  return out;
}

/** RawMask 校验结果；ok=false 时 reason 为内部诊断说明（不直接进 UI）。 */
export interface MaskValidation {
  ok: boolean;
  reason: string;
}

/**
 * RawMask 强制校验（V2 §8 全集）。任何一项失败都必须进入 error 态，
 * 禁止继续进入区域调色：
 * - 宽高大于 0；
 * - weights.length === width × height；
 * - 至少存在一个 >0 权重；
 * - subjectRectangle 合法且未越界（仅用于合法性验证，红线允许的用途之一）。
 */
export function validateRawMask(
  width: number,
  height: number,
  weights: Uint8Array,
  bounds: RectData
): MaskValidation {
  if (!(width > 0) || !(height > 0)) {
    const r: MaskValidation = { ok: false, reason: 'mask size non-positive' };
    return r;
  }
  if (weights.length !== width * height) {
    const r: MaskValidation =
      { ok: false, reason: `weights length ${weights.length} != ${width}x${height}` };
    return r;
  }
  let hasWeight = false;
  for (let i = 0; i < weights.length; i++) {
    if (weights[i] > 0) {
      hasWeight = true;
      break;
    }
  }
  if (!hasWeight) {
    const r: MaskValidation = { ok: false, reason: 'no positive weight' };
    return r;
  }
  if (!(bounds.width > 0) || !(bounds.height > 0)) {
    const r: MaskValidation = { ok: false, reason: 'subject rect empty' };
    return r;
  }
  if (bounds.left < 0 || bounds.top < 0 ||
    bounds.left + bounds.width > width ||
    bounds.top + bounds.height > height) {
    const r: MaskValidation = { ok: false, reason: 'subject rect out of bounds' };
    return r;
  }
  const okResult: MaskValidation = { ok: true, reason: '' };
  return okResult;
}

/**
 * 权重 → 灰度 RGBA 缓冲（Debug 视图 C：RawMask 直读）。
 * v → R=G=B=v，A=255。不经过任何 MaskProcessor（V2 §9）。
 */
export function weightsToGrayRgba(weights: Uint8Array): Uint8Array {
  const n = weights.length;
  const rgba = new Uint8Array(n * 4);
  for (let i = 0; i < n; i++) {
    const v = weights[i];
    const o = i * 4;
    rgba[o] = v;
    rgba[o + 1] = v;
    rgba[o + 2] = v;
    rgba[o + 3] = 255;
  }
  return rgba;
}

/**
 * 权重 → 双色叠加 RGBA 缓冲（Debug 视图 D / 编辑页「查看分区」）。
 *
 * 按真实权重在主体色与背景色间线性混合，alpha = alphaBase × w
 * ——软边缘呈现为透明度渐变，不做硬切换。
 *
 * @param weights 逐像素权重（0~255）
 * @param subjectRgb 主体色 [r,g,b]（如朱砂红 178,59,47）
 * @param backgroundRgb 背景色 [r,g,b]（如青绿 44,98,180）
 * @param alphaBase 最大不透明度 0~255
 */
export function weightsToOverlayRgba(
  weights: Uint8Array,
  subjectRgb: number[],
  backgroundRgb: number[],
  alphaBase: number
): Uint8Array {
  const n = weights.length;
  const rgba = new Uint8Array(n * 4);
  const sr = subjectRgb[0];
  const sg = subjectRgb[1];
  const sb = subjectRgb[2];
  const br = backgroundRgb[0];
  const bg = backgroundRgb[1];
  const bb = backgroundRgb[2];
  for (let i = 0; i < n; i++) {
    // w 归一到 [0,1]；用整数运算避免浮点抖动
    const w = weights[i];
    const o = i * 4;
    rgba[o] = ((sr * w) + (br * (255 - w))) / 255;
    rgba[o + 1] = ((sg * w) + (bg * (255 - w))) / 255;
    rgba[o + 2] = ((sb * w) + (bb * (255 - w))) / 255;
    rgba[o + 3] = (alphaBase * w) / 255;
  }
  return rgba;
}

/** 由宽高构造全零 MaskData（测试与兜底用）。 */
export function createEmptyMaskData(width: number, height: number): MaskData {
  const data: MaskData = {
    width: width,
    height: height,
    weights: new Uint8Array(width * height)
  };
  return data;
}

