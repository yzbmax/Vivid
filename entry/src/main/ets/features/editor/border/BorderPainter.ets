import { BorderState } from '../../../models/SharedContracts';
import { BorderGeometry } from './BorderLayoutResolver';
import { sanitizeBorderState } from './BorderState';
import { Theme } from '../../../components/common/Theme';

/** 预览与导出共用像素单位绘制过程；不绘制照片，不覆盖已有调色、贴纸或文字。 */
export function paintBorder(
  context: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
  geometry: BorderGeometry, border: BorderState, scale: number = 1
): void {
  if (geometry.templateId === 'none' || scale <= 0) {
    return;
  }
  const safe = sanitizeBorderState(border);
  const w = geometry.outputWidth * scale;
  const h = geometry.outputHeight * scale;
  const spread = geometry.shadowSpread * scale;
  context.save();
  // 实色衬底使 JPEG 与 PNG 的阴影区域保持一致。
  context.fillStyle = Theme.PAPER_SURFACE;
  context.fillRect(0, 0, w, h);
  if (spread > 0) {
    context.shadowColor = 'rgba(36,25,24,' + (safe.shadowStrength * 0.6) + ')';
    context.shadowBlur = spread;
    context.shadowOffsetY = spread * 0.3;
  }
  context.fillStyle = 'rgba(' + ((safe.colorArgb >>> 16) & 255) + ',' + ((safe.colorArgb >>> 8) & 255)
    + ',' + (safe.colorArgb & 255) + ',' + ((safe.colorArgb >>> 24) / 255) + ')';
  context.fillRect(spread, spread, w - 2 * spread, h - 2 * spread);
  context.shadowBlur = 0;
  context.shadowOffsetY = 0;
  context.shadowColor = 'rgba(0,0,0,0)';
  for (const decoration of geometry.decorations) {
    const r = decoration.rect;
    // 卷轴装饰的原点是外框内缘；投影在其外围扩展。
    const offset = geometry.templateId === 'scroll_mount' ? spread : 0;
    const x = r.x * scale + offset;
    const y = r.y * scale + offset;
    if (decoration.kind === 'filmNumber') {
      context.fillStyle = Theme.PAPER_SURFACE;
      context.font = Math.max(1, r.height * scale) + 'px monospace';
      context.textAlign = 'center';
      context.textBaseline = 'middle';
      context.fillText('VIVID 01', x + r.width * scale / 2, y + r.height * scale / 2);
    } else {
      context.fillStyle = decoration.kind === 'sprocket' ? Theme.PAPER_SURFACE : Theme.SEAL_RED;
      context.fillRect(x, y, r.width * scale, r.height * scale);
    }
  }
  context.restore();
}
