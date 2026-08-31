import { MaskTuningConfig } from '../models/SegmentationModels';

/**
 * 蒙版处理器：RawMask → EditMask（V2 §10~§12）。
 *
 * 职责：置信度曲线重映射、双线性缩放。全部纯函数、无 Kit 依赖。
 *
 * 红线（V2 §10/§38）：
 * - 禁止二值化（mask >= 128 ? 255 : 0），必须保留发丝/毛发等软边缘；
 * - 不默认执行腐蚀等形态学操作；如未来需要，必须作为独立可关闭策略。
 */

/**
 * 置信度曲线重映射：抑制低置信污染、保留软边缘、高概率趋近 255。
 *
 * 分段线性映射（默认配置下近似恒等，V2 §11 原则：不写死未经测试的强阈值）：
 * - [0, lowConfidence]   → 压向 0 附近（低置信噪声抑制）；
 * - (lowConfidence, highConfidence) → 线性过渡（软边缘保留区）；
 * - [highConfidence, 255] → 拉向 255（真主体增强）。
 *
 * lowConfidence === 0 且 highConfidence === 255 时为严格恒等。
 */
export function applyConfidenceCurve(
  weights: Uint8Array,
  config: MaskTuningConfig
): Uint8Array {
  const lo = Math.max(0, Math.min(254, config.lowConfidence));
  const hi = Math.max(lo + 1, Math.min(255, config.highConfidence));
  const n = weights.length;
  const out = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    const v = weights[i];
    let mapped: number;
    if (v <= lo) {
      // 低置信段：0 → lo*0.3 线性压缩（保留极少量权重，不完全清零）
      mapped = (v * 30) / 255;
    } else if (v >= hi) {
      // 高置信段：hi → 255 线性抬升
      mapped = hi + ((v - hi) * (255 - hi)) / (255 - hi);
      if (mapped > 255) {
        mapped = 255;
      }
    } else {
      // 中间软边缘段：lo..hi → lo*0.3..hi 线性映射（连续，无跳变）
      const segStart = (lo * 30) / 255;
      mapped = segStart + ((v - lo) * (hi - segStart)) / (hi - lo);
    }
    out[i] = mapped < 0 ? 0 : (mapped > 255 ? 255 : Math.round(mapped));
  }
  return out;
}

/** 默认调优参数：低阈值 0、高阈值 255 → applyConfidenceCurve 为恒等（V1 未锁定前不强启用）。 */
export function defaultMaskTuning(): MaskTuningConfig {
  const cfg: MaskTuningConfig = { lowConfidence: 0, highConfidence: 255 };
  return cfg;
}

/**
 * 双线性缩放蒙版到目标尺寸（预览对齐显示尺寸 / 导出对齐成图尺寸）。
 *
 * 连续插值保持软边缘渐变（禁止最近邻硬缩放造成的锯齿，V2 §10）。
 * 同尺寸时返回内容拷贝（调用方可安全持有）。
 */
export function resizeMaskBilinear(
  src: Uint8Array,
  sw: number,
  sh: number,
  dw: number,
  dh: number
): Uint8Array {
  if (sw <= 0 || sh <= 0 || dw <= 0 || dh <= 0) {
    return new Uint8Array(0);
  }
  if (sw === dw && sh === dh) {
    return src.slice();
  }
  const out = new Uint8Array(dw * dh);
  // 目标像素中心映射回源坐标系（半像素中心对齐，避免整体偏移）
  const xRatio = sw / dw;
  const yRatio = sh / dh;
  for (let dy = 0; dy < dh; dy++) {
    const sy = (dy + 0.5) * yRatio - 0.5;
    let sy0 = Math.floor(sy);
    if (sy0 < 0) {
      sy0 = 0;
    }
    let sy1 = sy0 + 1;
    if (sy1 > sh - 1) {
      sy1 = sh - 1;
    }
    const fy = sy - sy0;
    if (fy < 0) {
      // sy0 被 clamp 后 fy 可能为负
      continue;
    }
    for (let dx = 0; dx < dw; dx++) {
      const sx = (dx + 0.5) * xRatio - 0.5;
      let sx0 = Math.floor(sx);
      if (sx0 < 0) {
        sx0 = 0;
      }
      let sx1 = sx0 + 1;
      if (sx1 > sw - 1) {
        sx1 = sw - 1;
      }
      const fx = sx - sx0;
      if (fx < 0) {
        continue;
      }
      const p00 = src[sy0 * sw + sx0];
      const p10 = src[sy0 * sw + sx1];
      const p01 = src[sy1 * sw + sx0];
      const p11 = src[sy1 * sw + sx1];
      const top = p00 + (p10 - p00) * fx;
      const bottom = p01 + (p11 - p01) * fx;
      const v = top + (bottom - top) * fy;
      out[dy * dw + dx] = v < 0 ? 0 : (v > 255 ? 255 : Math.round(v));
    }
  }
  return out;
}
