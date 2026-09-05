import { image } from '@kit.ImageKit';
import { TextLayer } from '../models/SharedContracts';
import { LengthMetricsUnit } from '@kit.ArkUI';
import { findFontEntry, resolveFontKey } from '../features/editor/text/FontCatalog';
import { validateTextContent } from '../features/editor/text/TextLayerState';

/**
 * 文字布局计算结果（用于确定性离线绘制与单测验证）
 */
export interface TextLayoutMetrics {
  id: string;
  content: string;
  fontKey: string;
  colorArgb: number;
  fontSizePx: number;
  centerPixelX: number;
  centerPixelY: number;
  rotationDeg: number;
  opacity: number;
}

/**
 * 文字图层合成服务：负责将文字图层按规范离线绘制到 PixelMap 上。
 *
 * 依据：《Vivid_0.1.9更新计划》§3.2 & §4 (开发者 B)
 * 纯逻辑解耦：解算逻辑不依赖 ArkUI，确保预览与导出 100% 坐标对齐。
 */
export class TextCompositionService {
  /**
   * 计算所有文字图层的像素绝对布局（无 UI 依赖纯逻辑）
   * @param textLayers 文字图层列表
   * @param imageWidth 照片像素宽
   * @param imageHeight 照片像素高
   * @returns 布局指标列表
   */
  static resolveLayoutMetrics(
    textLayers: TextLayer[],
    imageWidth: number,
    imageHeight: number
  ): TextLayoutMetrics[] {
    if (!textLayers || textLayers.length === 0 || imageWidth <= 0 || imageHeight <= 0) {
      return [];
    }

    const longEdge = Math.max(imageWidth, imageHeight);

    return textLayers.slice(0, 8).map((layer: TextLayer) => {
      // 字号：照片长边的 2% - 20%
      const ratio = typeof layer.fontSizeRatio === 'number' && !isNaN(layer.fontSizeRatio)
        ? Math.max(0.02, Math.min(0.20, layer.fontSizeRatio))
        : 0.06;
      const fontSizePx = Math.max(1, Math.round(longEdge * ratio));

      // 归一化中心坐标 [0, 1] 映射到像素
      const cx = typeof layer.centerX === 'number' && !isNaN(layer.centerX)
        ? Math.max(0, Math.min(1, layer.centerX))
        : 0.5;
      const cy = typeof layer.centerY === 'number' && !isNaN(layer.centerY)
        ? Math.max(0, Math.min(1, layer.centerY))
        : 0.5;

      const centerPixelX = Math.round(imageWidth * cx);
      const centerPixelY = Math.round(imageHeight * cy);

      // 旋转 [-180, 180]
      const rotation = typeof layer.rotationDeg === 'number' && !isNaN(layer.rotationDeg)
        ? Math.max(-180, Math.min(180, layer.rotationDeg))
        : 0;

      // 透明度 [0.3, 1.0]
      const opacity = typeof layer.opacity === 'number' && !isNaN(layer.opacity)
        ? Math.max(0.3, Math.min(1, layer.opacity))
        : 1.0;

      const metric: TextLayoutMetrics = {
        id: layer.id,
        content: layer.content ?? '',
        fontKey: layer.fontKey ?? 'system_sans',
        colorArgb: typeof layer.colorArgb === 'number' ? layer.colorArgb : 0xFF241918,
        fontSizePx: fontSizePx,
        centerPixelX: centerPixelX,
        centerPixelY: centerPixelY,
        rotationDeg: rotation,
        opacity: opacity
      };
      return metric;
    });
  }

  /**
   * 将文字图层合成到 basePixelMap 上
   * @param basePixelMap 经过滤镜与调色的基础 PixelMap
   * @param textLayers 文字图层列表
   * @returns 合成后的 PixelMap
   */
  static async render(
    basePixelMap: image.PixelMap,
    textLayers: TextLayer[],
    unavailableFontKeys: string[] = []
  ): Promise<image.PixelMap> {
    if (!textLayers || textLayers.length === 0) {
      return basePixelMap;
    }

    for (const layer of textLayers) {
      if (!validateTextContent(layer.content).valid) {
        throw new Error('Invalid text layer content');
      }
    }
    const info = await basePixelMap.getImageInfo();
    const w = info.size.width;
    const h = info.size.height;
    const canvas = new OffscreenCanvasRenderingContext2D(w, h, new RenderingContextSettings(true), LengthMetricsUnit.PX);
    canvas.drawImage(basePixelMap, 0, 0, w, h);
    const metrics = TextCompositionService.resolveLayoutMetrics(textLayers, w, h);
    for (const metric of metrics) {
      const family = findFontEntry(resolveFontKey(metric.fontKey, unavailableFontKeys))?.family ?? 'HarmonyOS Sans SC';
      canvas.save();
      canvas.translate(metric.centerPixelX, metric.centerPixelY);
      canvas.rotate(metric.rotationDeg * Math.PI / 180);
      canvas.globalAlpha = metric.opacity;
      canvas.fillStyle = 'rgba(' + ((metric.colorArgb >>> 16) & 255) + ',' + ((metric.colorArgb >>> 8) & 255)
        + ',' + (metric.colorArgb & 255) + ',' + ((metric.colorArgb >>> 24) / 255) + ')';
      canvas.font = metric.fontSizePx + 'px "' + family + '"';
      canvas.textAlign = 'center';
      canvas.textBaseline = 'middle';
      const lines = metric.content.replace(/\r\n|\r/g, '\n').split('\n');
      const lineHeight = metric.fontSizePx * 1.25;
      for (let i = 0; i < lines.length; i++) {
        canvas.fillText(lines[i], 0, (i - (lines.length - 1) / 2) * lineHeight);
      }
      canvas.restore();
    }
    return canvas.getPixelMap(0, 0, w, h);
  }
}
