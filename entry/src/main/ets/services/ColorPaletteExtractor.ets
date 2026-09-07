import { TraditionalColorItem } from '../models/ColophonModels';
import { findClosestTraditionalColor, TRADITIONAL_COLORS } from '../models/TraditionalColorCatalog';

export interface RgbSample {
  r: number;
  g: number;
  b: number;
}

/**
 * 图像色彩提取与国色映射服务
 */
export class ColorPaletteExtractor {
  /**
   * 从 RGB 样本数组中提取 4~5 个最具有代表性且互不重合的中国传统色
   */
  static extractPaletteFromSamples(samples: RgbSample[], maxColors: number = 5): TraditionalColorItem[] {
    if (!samples || samples.length === 0) {
      return ColorPaletteExtractor.getDefaultFallbackPalette(maxColors);
    }

    // 1. 颜色桶量化（4-bit per channel）聚类统计
    const histogram: Map<number, number> = new Map<number, number>();
    const binSumR: Map<number, number> = new Map<number, number>();
    const binSumG: Map<number, number> = new Map<number, number>();
    const binSumB: Map<number, number> = new Map<number, number>();

    for (let i = 0; i < samples.length; i++) {
      const s = samples[i];
      // 将 0..255 量化为 0..15
      const qr = Math.floor(s.r / 16);
      const qg = Math.floor(s.g / 16);
      const qb = Math.floor(s.b / 16);
      const key = (qr << 8) | (qg << 4) | qb;

      const count = histogram.get(key) ?? 0;
      histogram.set(key, count + 1);
      binSumR.set(key, (binSumR.get(key) ?? 0) + s.r);
      binSumG.set(key, (binSumG.get(key) ?? 0) + s.g);
      binSumB.set(key, (binSumB.get(key) ?? 0) + s.b);
    }

    // 2. 按出现频次倒序排序
    const sortedKeys: number[] = Array.from(histogram.keys()).sort((a: number, b: number) => {
      const ca = histogram.get(a) ?? 0;
      const cb = histogram.get(b) ?? 0;
      return cb - ca;
    });

    const chosenColors: TraditionalColorItem[] = [];
    const usedNames: Set<string> = new Set<string>();

    for (let i = 0; i < sortedKeys.length; i++) {
      if (chosenColors.length >= maxColors) {
        break;
      }
      const key = sortedKeys[i];
      const count = histogram.get(key) ?? 1;
      const avgR = Math.round((binSumR.get(key) ?? 0) / count);
      const avgG = Math.round((binSumG.get(key) ?? 0) / count);
      const avgB = Math.round((binSumB.get(key) ?? 0) / count);

      const matched = findClosestTraditionalColor(avgR, avgG, avgB);

      // 去重：同一国色名不重复入选
      if (!usedNames.has(matched.name)) {
        // 色距多样性筛选：与已选入颜色保持一定感知差
        let isDistinct = true;
        for (let j = 0; j < chosenColors.length; j++) {
          const c = chosenColors[j];
          const dist = Math.abs(c.r - matched.r) + Math.abs(c.g - matched.g) + Math.abs(c.b - matched.b);
          if (dist < 40) {
            isDistinct = false;
            break;
          }
        }
        if (isDistinct || chosenColors.length < 2) {
          chosenColors.push(matched);
          usedNames.add(matched.name);
        }
      }
    }

    // 若不足，用保底经典国色补齐
    if (chosenColors.length < maxColors) {
      const fallbacks = ColorPaletteExtractor.getDefaultFallbackPalette(maxColors);
      for (let i = 0; i < fallbacks.length; i++) {
        if (chosenColors.length >= maxColors) {
          break;
        }
        if (!usedNames.has(fallbacks[i].name)) {
          chosenColors.push(fallbacks[i]);
          usedNames.add(fallbacks[i].name);
        }
      }
    }

    return chosenColors;
  }

  /**
   * 保底经典和谐国色配搭
   */
  static getDefaultFallbackPalette(count: number = 5): TraditionalColorItem[] {
    const candidates = [
      TRADITIONAL_COLORS[0], // 缃色
      TRADITIONAL_COLORS[1], // 苍绿
      TRADITIONAL_COLORS[2], // 黄栌
      TRADITIONAL_COLORS[4], // 松烟
      TRADITIONAL_COLORS[6]  // 朱砂
    ];
    return candidates.slice(0, count);
  }
}
