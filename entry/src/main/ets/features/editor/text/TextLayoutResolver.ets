import {
  TextLayer,
  clampFontSizeRatio,
  clampNormalizedCoord,
  clampTextOpacity,
  clampTextRotation
} from '../../../models/SharedContracts';
import { resolveFontKey } from './FontCatalog';

export interface ContentRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface PixelPoint {
  x: number;
  y: number;
}

/** UI 可传入字体实测尺寸；单位须与 ContentRect 相同。 */
export interface TextBounds {
  width: number;
  height: number;
}

export interface NormalizedPoint {
  x: number;
  y: number;
}

export interface ResolvedTextLayout {
  id: string;
  content: string;
  fontKey: string;
  colorArgb: number;
  centerPixelX: number;
  centerPixelY: number;
  fontSizePx: number;
  widthPx: number;
  heightPx: number;
  rotationDeg: number;
  opacity: number;
}

function safeRect(rect: ContentRect): ContentRect {
  return {
    x: rect.x,
    y: rect.y,
    width: Math.max(0, rect.width),
    height: Math.max(0, rect.height)
  };
}

function lineCount(content: string): number {
  return Math.max(1, content.split(/\r\n|\r|\n/).length);
}

function longestLineLength(content: string): number {
  const lines = content.split(/\r\n|\r|\n/);
  let longest = 0;
  for (let i = 0; i < lines.length; i++) {
    let count = 0;
    for (let j = 0; j < lines[i].length; j++) {
      const code = lines[i].charCodeAt(j);
      if (code >= 0xD800 && code <= 0xDBFF && j + 1 < lines[i].length) {
        const next = lines[i].charCodeAt(j + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          j++;
        }
      }
      count++;
    }
    if (count > longest) {
      longest = count;
    }
  }
  return Math.max(1, longest);
}

export function normalizeToPixel(rect: ContentRect, centerX: number, centerY: number): PixelPoint {
  const safe = safeRect(rect);
  return {
    x: safe.x + safe.width * clampNormalizedCoord(centerX),
    y: safe.y + safe.height * clampNormalizedCoord(centerY)
  };
}

export function pixelToNormalized(rect: ContentRect, pixelX: number, pixelY: number): NormalizedPoint {
  const safe = safeRect(rect);
  if (safe.width <= 0 || safe.height <= 0) {
    return { x: 0.5, y: 0.5 };
  }
  return {
    x: clampNormalizedCoord((pixelX - safe.x) / safe.width),
    y: clampNormalizedCoord((pixelY - safe.y) / safe.height)
  };
}

export function resolveTextLayout(rect: ContentRect, layer: TextLayer, measured?: TextBounds): ResolvedTextLayout {
  const safe = safeRect(rect);
  const longEdge = Math.max(safe.width, safe.height);
  const fontSizePx = Math.max(1, Math.round(longEdge * clampFontSizeRatio(layer.fontSizeRatio)));
  const lines = lineCount(layer.content);
  // 无字体测量器时保守按全角估计，避免中文被挤入半角包围盒。
  const widthPx = measured !== undefined && Number.isFinite(measured.width) && measured.width > 0
    ? measured.width : Math.max(fontSizePx, longestLineLength(layer.content) * fontSizePx);
  const heightPx = measured !== undefined && Number.isFinite(measured.height) && measured.height > 0
    ? measured.height : Math.max(fontSizePx, Math.ceil(lines * fontSizePx * 1.25));
  const center = normalizeToPixel(safe, layer.centerX, layer.centerY);
  return {
    id: layer.id,
    content: layer.content,
    fontKey: resolveFontKey(layer.fontKey),
    colorArgb: layer.colorArgb,
    centerPixelX: center.x,
    centerPixelY: center.y,
    fontSizePx: fontSizePx,
    widthPx: widthPx,
    heightPx: heightPx,
    rotationDeg: clampTextRotation(layer.rotationDeg),
    opacity: clampTextOpacity(layer.opacity)
  };
}

/** 将拖动后的像素中心限制在文字包围盒可以容纳的区域。 */
export function clampTextCenterToContent(
  rect: ContentRect,
  layout: ResolvedTextLayout,
  pixelX: number,
  pixelY: number
): PixelPoint {
  const safe = safeRect(rect);
  const angle = Math.abs(layout.rotationDeg) * Math.PI / 180;
  const rotatedWidth = Math.abs(layout.widthPx * Math.cos(angle)) + Math.abs(layout.heightPx * Math.sin(angle));
  const rotatedHeight = Math.abs(layout.widthPx * Math.sin(angle)) + Math.abs(layout.heightPx * Math.cos(angle));
  const halfWidth = Math.min(rotatedWidth / 2, safe.width / 2);
  const halfHeight = Math.min(rotatedHeight / 2, safe.height / 2);
  const minX = safe.x + halfWidth;
  const maxX = safe.x + safe.width - halfWidth;
  const minY = safe.y + halfHeight;
  const maxY = safe.y + safe.height - halfHeight;
  return {
    x: Math.min(maxX, Math.max(minX, pixelX)),
    y: Math.min(maxY, Math.max(minY, pixelY))
  };
}

export function draggedCenterToNormalized(
  rect: ContentRect,
  layout: ResolvedTextLayout,
  pixelX: number,
  pixelY: number
): NormalizedPoint {
  const clamped = clampTextCenterToContent(rect, layout, pixelX, pixelY);
  return pixelToNormalized(rect, clamped.x, clamped.y);
}
