import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import {
  ToneCategory,
  ToneMetrics,
  AuditDiagnosis,
  createDefaultToneMetrics,
  createDefaultAuditDiagnosis
} from '../models/ImageToneModels';

export interface ToneAnalysisResult {
  metrics: ToneMetrics;
  audit: AuditDiagnosis;
}

/**
 * 照片直方图明暗分析与极端曝光诊断服务
 */
export class ImageToneAnalyzer {
  /**
   * 从纯亮度样本数组计算直方图指标、调性分类与校勘诊断
   *
   * @param luminanceSamples 8 位亮度值数组 (0..255)
   */
  static analyzeHistogramFromSamples(luminanceSamples: number[] | Uint8Array): ToneAnalysisResult {
    const total = luminanceSamples.length;
    if (total === 0) {
      return {
        metrics: createDefaultToneMetrics(),
        audit: createDefaultAuditDiagnosis()
      };
    }

    let sum = 0;
    let sumSq = 0;
    let shadowCount = 0;          // Y < 40
    let highlightCount = 0;       // Y > 215
    let extremeShadowCount = 0;   // Y <= 15
    let extremeHighlightCount = 0;// Y >= 245
    let midtoneCount = 0;         // 80 <= Y <= 180

    for (let i = 0; i < total; i++) {
      const y = luminanceSamples[i];
      sum += y;
      sumSq += y * y;

      if (y < 40) {
        shadowCount++;
      }
      if (y > 215) {
        highlightCount++;
      }
      if (y <= 15) {
        extremeShadowCount++;
      }
      if (y >= 245) {
        extremeHighlightCount++;
      }
      if (y >= 80 && y <= 180) {
        midtoneCount++;
      }
    }

    const mean = sum / total;
    const variance = Math.max(0, (sumSq / total) - (mean * mean));
    const stdDev = Math.sqrt(variance);

    const shadowRatio = shadowCount / total;
    const highlightRatio = highlightCount / total;
    const extremeShadowRatio = extremeShadowCount / total;
    const extremeHighlightRatio = extremeHighlightCount / total;
    const midtoneRatio = midtoneCount / total;

    // 双峰判定：暗部突出、高光突出、两极分立且反差大
    const isBimodal = (shadowRatio >= 0.18 && highlightRatio >= 0.18 && stdDev >= 55) ||
                      (shadowRatio >= 0.35 && highlightRatio >= 0.35);

    // 调性分类推导
    let category: ToneCategory = 'balanced';
    let label = '平和中正';

    if (isBimodal) {
      category = 'dappled_contrast';
      label = '阴阳错落';
    } else if (mean > 175 && shadowRatio < 0.08) {
      category = 'high_key';
      label = '极目高明';
    } else if (mean < 75 && highlightRatio < 0.08) {
      category = 'low_key';
      label = '玄冥深致';
    } else if (stdDev < 30) {
      category = 'soft_subtle';
      label = '烟云冲和';
    } else if (stdDev >= 45 && shadowRatio > 0.05 && highlightRatio > 0.05) {
      category = 'rich_full';
      label = '气脉丰匀';
    }

    const metrics: ToneMetrics = {
      meanBrightness: Math.round(mean),
      stdDev: Math.round(stdDev),
      shadowRatio: Math.round(shadowRatio * 100) / 100,
      highlightRatio: Math.round(highlightRatio * 100) / 100,
      isBimodal: isBimodal,
      toneCategory: category,
      toneLabel: label
    };

    // 极端直方图诊断
    let audit: AuditDiagnosis = createDefaultAuditDiagnosis();

    if (extremeHighlightRatio >= 0.15 || (mean > 210 && highlightRatio > 0.40)) {
      const pct = Math.max(15, Math.round(extremeHighlightRatio * 100));
      audit = {
        hasIssue: true,
        issueType: 'highlight_clipping',
        title: '官署校勘',
        description: `高光溢出偏多（约 ${pct}%），碎金稍显灼目，局部亮处细节隐没。`,
        recommendation: '建议点击「继续编辑」将「曝光」微调 -15 ~ -20，使白练复归温润。',
        targetParam: 'exposure',
        suggestedDelta: -15
      };
    } else if (extremeShadowRatio >= 0.20 || (mean < 45 && shadowRatio > 0.45)) {
      const pct = Math.max(20, Math.round(extremeShadowRatio * 100));
      audit = {
        hasIssue: true,
        issueType: 'shadow_clipping',
        title: '官署校勘',
        description: `暗部玄墨过厚（约 ${pct}%），阴翳发堵，幽微草木细节难辨。`,
        recommendation: '建议点击「继续编辑」将「亮度/阴影」微调 +15 ~ +20，令暗部细节可鉴。',
        targetParam: 'brightness',
        suggestedDelta: 15
      };
    } else if ((shadowRatio + highlightRatio) >= 0.40 && stdDev >= 75) {
      audit = {
        hasIssue: true,
        issueType: 'harsh_contrast',
        title: '官署校勘',
        description: '阴阳对决过甚，明暗界线略显峭硬，过渡欠缺绵密。',
        recommendation: '建议点击「继续编辑」将「对比度」微调 -10 ~ -15，令层次更显冲和。',
        targetParam: 'contrast',
        suggestedDelta: -10
      };
    } else if (stdDev < 25 && total > 50) {
      audit = {
        hasIssue: true,
        issueType: 'low_contrast',
        title: '官署校勘',
        description: '通篇反差偏弱，烟云微显郁结，神采略欠挺拔。',
        recommendation: '建议点击「继续编辑」将「对比度」微调 +15 ~ +20，提振全幅骨气。',
        targetParam: 'contrast',
        suggestedDelta: 15
      };
    }

    return { metrics, audit };
  }

  /**
   * 异步采样图片文件（64x64 微缩略图，约 3ms 极速分析）
   */
  static async analyzeImageTone(imageUri: string): Promise<ToneAnalysisResult> {
    if (!imageUri || imageUri.length === 0) {
      return {
        metrics: createDefaultToneMetrics(),
        audit: createDefaultAuditDiagnosis()
      };
    }

    let file: fs.File | null = null;
    let imageSource: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;

    try {
      if (imageUri.startsWith('file://') || imageUri.startsWith('/')) {
        const filePath = imageUri.startsWith('file://') ? imageUri.substring(7) : imageUri;
        file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        imageSource = image.createImageSource(file.fd);
      } else {
        imageSource = image.createImageSource(imageUri);
      }

      if (!imageSource) {
        return {
          metrics: createDefaultToneMetrics(),
          audit: createDefaultAuditDiagnosis()
        };
      }

      // 解码 64x64 极轻量缩略图
      const decodeOpts: image.DecodingOptions = {
        desiredSize: { width: 64, height: 64 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: false
      };
      pixelMap = await imageSource.createPixelMap(decodeOpts);
      if (!pixelMap) {
        return {
          metrics: createDefaultToneMetrics(),
          audit: createDefaultAuditDiagnosis()
        };
      }

      const byteCount = pixelMap.getPixelBytesNumber();
      const buffer = new ArrayBuffer(byteCount);
      await pixelMap.readPixelsToBuffer(buffer);
      const view = new Uint8Array(buffer);

      const pixelCount = Math.floor(view.length / 4);
      const luminanceSamples = new Uint8Array(pixelCount);

      for (let i = 0; i < pixelCount; i++) {
        const r = view[i * 4];
        const g = view[i * 4 + 1];
        const b = view[i * 4 + 2];
        // 快速整数加权计算亮度 Y = 0.299R + 0.587G + 0.114B
        luminanceSamples[i] = (r * 77 + g * 150 + b * 29) >> 8;
      }

      return ImageToneAnalyzer.analyzeHistogramFromSamples(luminanceSamples);
    } catch (err) {
      console.warn(`[ImageToneAnalyzer] Failed to analyze ${imageUri}: ${JSON.stringify(err)}`);
      return {
        metrics: createDefaultToneMetrics(),
        audit: createDefaultAuditDiagnosis()
      };
    } finally {
      if (pixelMap) {
        try {
          pixelMap.release();
        } catch (_) {}
      }
      if (file) {
        try {
          fs.closeSync(file);
        } catch (_) {}
      }
    }
  }
}
