import { BorderState } from '../../../models/SharedContracts';
import { BorderGeometry, RectPx, resolveBorderGeometry } from '../border/BorderLayoutResolver';

export interface PreviewCardSize {
  width: number;
  height: number;
}

/** 原 fitPreviewCard 的纯几何实现，供预览管线和装裱布局共同消费。 */
export function fitPreviewCard(
  containerWidth: number, containerHeight: number, imageWidth: number, imageHeight: number
): PreviewCardSize {
  if (containerWidth <= 0 || containerHeight <= 0) {
    return { width: 0, height: 0 };
  }
  if (imageWidth <= 0 || imageHeight <= 0) {
    return { width: Math.max(1, Math.floor(containerWidth)), height: Math.max(1, Math.floor(containerHeight)) };
  }
  const scale = Math.min(containerWidth / imageWidth, containerHeight / imageHeight);
  return { width: Math.max(1, Math.floor(imageWidth * scale)), height: Math.max(1, Math.floor(imageHeight * scale)) };
}

export interface EditorPreviewLayout {
  geometry: BorderGeometry;
  outputRect: RectPx;
  /** 相对预览容器，而不是外扩画布的照片矩形。 */
  photoRect: RectPx;
}

export function resolveEditorPreviewLayout(
  containerWidth: number, containerHeight: number, photoWidth: number, photoHeight: number, border: BorderState
): EditorPreviewLayout {
  const w = Number.isFinite(containerWidth) ? Math.max(0, containerWidth) : 0;
  const h = Number.isFinite(containerHeight) ? Math.max(0, containerHeight) : 0;
  const known = Number.isFinite(photoWidth) && Number.isFinite(photoHeight) && photoWidth > 0 && photoHeight > 0;
  const geometry = resolveBorderGeometry({ photoWidth: known ? photoWidth : Math.max(1, w),
    photoHeight: known ? photoHeight : Math.max(1, h),
    border: known ? border : { templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0 } });
  const card = fitPreviewCard(w, h, geometry.outputWidth, geometry.outputHeight);
  // 使用单一缩放系数，避免分别取整的宽高使照片比例和文字坐标产生偏差。
  const scale = Math.min(card.width / geometry.outputWidth, card.height / geometry.outputHeight);
  const output: RectPx = { x: (w - geometry.outputWidth * scale) / 2,
    y: (h - geometry.outputHeight * scale) / 2,
    width: geometry.outputWidth * scale, height: geometry.outputHeight * scale };
  return { geometry: geometry, outputRect: output,
    photoRect: { x: output.x + geometry.photoRect.x * scale, y: output.y + geometry.photoRect.y * scale,
      width: geometry.photoRect.width * scale, height: geometry.photoRect.height * scale } };
}
