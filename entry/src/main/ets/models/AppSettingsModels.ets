/** 导出设置的稳定枚举与编码映射。 */

export enum ExportQuality {
  Standard = 'standard',
  High = 'high',
  Ultra = 'ultra'
}

export enum ExportFormat {
  JPEG = 'jpeg',
  PNG = 'png'
}

export interface AppExportSettings {
  quality: ExportQuality;
  format: ExportFormat;
}

export interface ExportProfile {
  mimeType: 'image/jpeg' | 'image/png';
  extension: '.jpg' | '.png';
  /** 0 means that the renderer keeps the source dimensions. */
  maxLongEdge: number;
  /** PNG uses this as a lossless intent marker; the encoder may ignore it. */
  encoderQuality: number;
}

export const DEFAULT_EXPORT_SETTINGS: AppExportSettings = {
  quality: ExportQuality.Standard,
  format: ExportFormat.JPEG
};

/** Convert user-facing settings into the renderer/exporter contract. */
export function toExportProfile(settings: AppExportSettings): ExportProfile {
  let maxLongEdge: number = 1920;
  let encoderQuality: number = 85;

  if (settings.quality === ExportQuality.High) {
    maxLongEdge = 2560;
    encoderQuality = 92;
  } else if (settings.quality === ExportQuality.Ultra) {
    maxLongEdge = 0;
    encoderQuality = 98;
  }

  if (settings.format === ExportFormat.PNG) {
    encoderQuality = 100;
    return {
      mimeType: 'image/png',
      extension: '.png',
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
