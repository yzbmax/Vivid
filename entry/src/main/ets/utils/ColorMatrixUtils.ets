/**
 * 颜色矩阵工具（4x5 颜色矩阵构建与乘法）。
 *
 * 架构迁移（2026-08-26）：从 Worker 逐像素渲染迁移到双图 colorFilter 方案。
 * 本工具为 Image.colorFilter() 提供 4x5 颜色矩阵（20 个数字的数组）。
 *
 * 矩阵格式（行优先，4 行 5 列）：
 *   [R']   [m0  m1  m2  m3  m4 ] [R]
 *   [G'] = [m5  m6  m7  m8  m9 ] [G]
 *   [B']   [m10 m11 m12 m13 m14] [B]
 *   [A']   [m15 m16 m17 m18 m19] [A]
 *                            [1 ]
 *
 * 其中 m4/m9/m14 是 RGB 通道的加性偏移（0-255 范围），m19=1 保持 alpha 不变。
 *
 * 纯函数，无 Kit 依赖，本地单测可加载。
 */

/**
 * 构建调色滤镜矩阵（4x5 = 20 个数字）。
 *
 * 参数范围（对应 AdjustParams 的 -100 ~ 100）：
 * - exposure: -100 ~ 100 → 乘法因子 0 ~ 2（0 为默认=因子 1）
 * - contrast: -100 ~ 100 → 乘法因子 0 ~ 2（0 为默认=因子 1）
 * - saturation: -100 ~ 100 → 乘法因子 0 ~ 2（0 为默认=因子 1）
 * - warmth: -100 ~ 100 → R 通道加性偏移 +255 ~ -255，B 通道反向
 *
 * 处理顺序：曝光 → 对比度 → 饱和度 → 色温（矩阵左乘顺序）。
 *
 * @returns 20 个数字的数组（4x5 矩阵，行优先）
 */
export function buildAdjustmentFilter(
  exposure: number,
  contrast: number,
  saturation: number,
  warmth: number
): number[] {
  // 曝光：乘法因子
  const exposureFactor = 1 + exposure / 100;

  // 对比度：乘法因子 + 偏移（围绕 128 中点）
  const contrastFactor = 1 + contrast / 100;
  const contrastOffset = 128 * (1 - contrastFactor);

  // 饱和度：Rec.709 亮度系数
  const saturationFactor = 1 + saturation / 100;

  // 色温：R/B 通道加性偏移（warmth/300 * 255 ≈ ±85 最大偏移）
  const warmthAmount = warmth / 300;

  // 曝光矩阵（对角线缩放）
  const exposureMatrix: number[] = [
    exposureFactor, 0, 0, 0, 0,
    0, exposureFactor, 0, 0, 0,
    0, 0, exposureFactor, 0, 0,
    0, 0, 0, 1, 0
  ];

  // 对比度矩阵（对角线缩放 + 偏移）
  const contrastMatrix: number[] = [
    contrastFactor, 0, 0, 0, contrastOffset,
    0, contrastFactor, 0, 0, contrastOffset,
    0, 0, contrastFactor, 0, contrastOffset,
    0, 0, 0, 1, 0
  ];

  // 饱和度矩阵（Rec.709 亮度混合）
  const saturationMatrix: number[] = [
    0.213 + 0.787 * saturationFactor, 0.715 * (1 - saturationFactor),
    0.072 * (1 - saturationFactor), 0, 0,
    0.213 * (1 - saturationFactor), 0.715 + 0.285 * saturationFactor,
    0.072 * (1 - saturationFactor), 0, 0,
    0.213 * (1 - saturationFactor), 0.715 * (1 - saturationFactor),
    0.072 + 0.928 * saturationFactor, 0, 0,
    0, 0, 0, 1, 0
  ];

  // 色温矩阵（R/B 通道加性偏移）
  const warmthMatrix: number[] = [
    1, 0, 0, 0, warmthAmount * 255,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, -warmthAmount * 255,
    0, 0, 0, 1, 0
  ];

  // 组合矩阵：曝光 × 对比度 × 饱和度 × 色温
  return multiplyColorMatrices(
    multiplyColorMatrices(exposureMatrix, contrastMatrix),
    multiplyColorMatrices(saturationMatrix, warmthMatrix)
  );
}

/**
 * 4x5 颜色矩阵乘法。
 *
 * 两个 4x5 矩阵相乘，结果仍为 4x5。
 * 矩阵格式：20 个数字的数组，行优先（每行 5 个元素）。
 *
 * @param left 左矩阵（20 个数字）
 * @param right 右矩阵（20 个数字）
 * @returns 结果矩阵（20 个数字）
 */
export function multiplyColorMatrices(left: number[], right: number[]): number[] {
  const output: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  // 4x4 部分相乘
  for (let row = 0; row < 4; row++) {
    for (let col = 0; col < 4; col++) {
      let sum = 0;
      for (let index = 0; index < 4; index++) {
        sum += left[row * 5 + index] * right[index * 5 + col];
      }
      output[row * 5 + col] = sum;
    }

    // 第 5 列（偏移量）：4x4 部分 × 右矩阵第 5 列 + 左矩阵第 5 列
    let offset = left[row * 5 + 4];
    for (let index = 0; index < 4; index++) {
      offset += left[row * 5 + index] * right[index * 5 + 4];
    }
    output[row * 5 + 4] = offset;
  }

  return output;
}
