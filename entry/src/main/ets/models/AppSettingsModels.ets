/** 导出设置的稳定枚举与编码映射。 */

export enum ExportQuality {
  Standard = 'standard',
  High = 'high',
  Ultra = 'ultra'
}

export enum ExportFormat {
  ORIGINAL = 'original',
  JPEG = 'jpeg',
  PNG = 'png',
  WEBP = 'webp',
  HEIF = 'heif'
}

export interface AppExportSettings {
  quality: ExportQuality;
  format: ExportFormat;
}

export interface ExportProfile {
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp' | 'image/heif';
  extension: '.jpg' | '.png' | '.webp' | '.heic';
  /** 0 means that the renderer keeps the source dimensions. */
  maxLongEdge: number;
  /** PNG uses this as a lossless intent marker; the encoder may ignore it. */
  encoderQuality: number;
}

export const DEFAULT_EXPORT_SETTINGS: AppExportSettings = {
  quality: ExportQuality.Standard,
  format: ExportFormat.JPEG
};

/**
 * 根据源图 URI 或文件路径推断其原始图像格式。
 * 若无法识别或为空，安全回退到 JPEG。
 */
export function resolveSourceFormat(sourceUri?: string): ExportFormat {
  if (!sourceUri || sourceUri.trim().length === 0) {
    return ExportFormat.JPEG;
  }
  const lower: string = sourceUri.trim().toLowerCase();
  if (lower.endsWith('.png') || lower.includes('.png')) {
    return ExportFormat.PNG;
  }
  if (lower.endsWith('.webp') || lower.includes('.webp')) {
    return ExportFormat.WEBP;
  }
  if (lower.endsWith('.heic') || lower.includes('.heic') || lower.endsWith('.heif') || lower.includes('.heif')) {
    return ExportFormat.HEIF;
  }
  return ExportFormat.JPEG;
}

/** Convert user-facing settings into the renderer/exporter contract. */
export function toExportProfile(settings: AppExportSettings, sourceUri?: string): ExportProfile {
  let maxLongEdge: number = 1920;
  let encoderQuality: number = 85;

  if (settings.quality === ExportQuality.High) {
    maxLongEdge = 2560;
    encoderQuality = 92;
  } else if (settings.quality === ExportQuality.Ultra) {
    maxLongEdge = 0;
    encoderQuality = 98;
  }

  let effectiveFormat: ExportFormat = settings.format;
  if (effectiveFormat === ExportFormat.ORIGINAL) {
    effectiveFormat = resolveSourceFormat(sourceUri);
  }

  if (effectiveFormat === ExportFormat.PNG) {
    encoderQuality = 100;
    return {
      mimeType: 'image/png',
      extension: '.png',
      maxLongEdge: maxLongEdge,
      encoderQuality: encoderQuality
    };
  }

  if (effectiveFormat === ExportFormat.WEBP) {
    return {
      mimeType: 'image/webp',
      extension: '.webp',
      maxLongEdge: maxLongEdge,
      encoderQuality: encoderQuality
    };
  }

  if (effectiveFormat === ExportFormat.HEIF) {
    return {
      mimeType: 'image/heif',
      extension: '.heic',
      maxLongEdge: maxLongEdge,
      encoderQuality: encoderQuality
    };
  }

  return {
    mimeType: 'image/jpeg',
    extension: '.jpg',
    maxLongEdge: maxLongEdge,
    encoderQuality: encoderQuality
  };
}

export interface ImageDimensions {
  width: number;
  height: number;
}

/**
 * 根据原始尺寸和导出画质规制计算目标输出尺寸。
 * 保持原始宽高比与横竖构图。
 */
export function resolveExportDimensions(
  quality: ExportQuality,
  width?: number,
  height?: number
): ImageDimensions {
  let srcW = (width !== undefined && width > 0) ? Math.round(width) : 4000;
  let srcH = (height !== undefined && height > 0) ? Math.round(height) : 3000;

  const longEdge = Math.max(srcW, srcH);
  const shortEdge = Math.max(1, Math.min(srcW, srcH));
  const aspectRatio = longEdge / shortEdge;

  let outLongEdge = longEdge;
  if (quality === ExportQuality.High) {
    outLongEdge = Math.min(2560, longEdge);
  } else if (quality === ExportQuality.Standard) {
    outLongEdge = Math.min(1920, longEdge);
  }

  const outShortEdge = Math.max(1, Math.round(outLongEdge / aspectRatio));

  if (srcW >= srcH) {
    return { width: outLongEdge, height: outShortEdge };
  } else {
    return { width: outShortEdge, height: outLongEdge };
  }
}

/**
 * 根据画质、格式以及源图尺寸计算预估导出的文件字节大小。
 * 针对照片细节和不同编码格式的真实压缩比进行加权估算。
 */
export function estimateExportFileSize(
  quality: ExportQuality,
  format: ExportFormat,
  width?: number,
  height?: number,
  sourceUri?: string
): number {
  const dims = resolveExportDimensions(quality, width, height);
  const pixelCount = dims.width * dims.height;

  let targetFormat = format;
  if (targetFormat === ExportFormat.ORIGINAL) {
    targetFormat = resolveSourceFormat(sourceUri);
  }

  // 依据真实摄影图像的字节/像素 (bpp) 经验参数
  if (targetFormat === ExportFormat.PNG) {
    return Math.round(pixelCount * 1.15);
  }

  if (targetFormat === ExportFormat.WEBP) {
    if (quality === ExportQuality.Ultra) {
      return Math.round(pixelCount * 0.25);
    }
    if (quality === ExportQuality.High) {
      return Math.round(pixelCount * 0.15);
    }
    return Math.round(pixelCount * 0.09);
  }

  if (targetFormat === ExportFormat.HEIF) {
    if (quality === ExportQuality.Ultra) {
      return Math.round(pixelCount * 0.19);
    }
    if (quality === ExportQuality.High) {
      return Math.round(pixelCount * 0.11);
    }
    return Math.round(pixelCount * 0.07);
  }

  // JPEG 默认
  if (quality === ExportQuality.Ultra) {
    return Math.round(pixelCount * 0.36);
  }
  if (quality === ExportQuality.High) {
    return Math.round(pixelCount * 0.22);
  }
  return Math.round(pixelCount * 0.14);
}

/**
 * 格式化预估体积为易读字符串（如 "约 2.4 MB" 或 "约 450 KB"）
 */
export function formatEstimatedFileSize(bytes: number): string {
  if (bytes < 1024 * 1024) {
    const kb = Math.max(1, Math.round(bytes / 1024));
    return `约 ${kb} KB`;
  }
  const mb = (bytes / (1024 * 1024)).toFixed(1);
  return `约 ${mb} MB`;
}
