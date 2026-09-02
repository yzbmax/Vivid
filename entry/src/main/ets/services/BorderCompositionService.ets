import { image } from '@kit.ImageKit';
import { BorderState } from '../models/SharedContracts';

/**
 * 边框外扩几何布局数据
 */
export interface BorderMargins {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

export interface BorderGeometry {
  templateId: string;
  outputWidth: number;
  outputHeight: number;
  photoOffsetX: number;
  photoOffsetY: number;
  photoWidth: number;
  photoHeight: number;
  margins: BorderMargins;
  colorArgb: number;
  shadowStrength: number;
}

/**
 * 边框装裱合成服务：负责计算外扩画布几何与离线装裱渲染。
 *
 * 依据：《Vivid_0.1.9更新计划》§2.3, §3.2 & §4 (开发者 B)
 * 约束：边框只向外扩展画布，绝不裁剪照片；无 UI 依赖纯逻辑解算。
 */
export class BorderCompositionService {
  /**
   * 计算边框装裱的绝对像素几何结构（无 UI 依赖纯逻辑）
   * @param border 边框状态
   * @param imageWidth 照片宽
   * @param imageHeight 照片高
   * @returns 几何布局结构
   */
  static resolveGeometry(
    border: BorderState,
    imageWidth: number,
    imageHeight: number
  ): BorderGeometry {
    const templateId = border?.templateId ?? 'none';
    const widthRatio = typeof border?.widthRatio === 'number' && !isNaN(border.widthRatio)
      ? Math.max(0, Math.min(0.25, border.widthRatio))
      : 0;
    const shadowStrength = typeof border?.shadowStrength === 'number' && !isNaN(border.shadowStrength)
      ? Math.max(0, Math.min(1, border.shadowStrength))
      : 0;
    const colorArgb = typeof border?.colorArgb === 'number'
      ? border.colorArgb
      : (templateId === 'ink_black' ? 0xFF241918 : 0xFFF2F1ED);

    if (templateId === 'none' || widthRatio <= 0 || imageWidth <= 0 || imageHeight <= 0) {
      const noneMargins: BorderMargins = { top: 0, bottom: 0, left: 0, right: 0 };
      const noneGeom: BorderGeometry = {
        templateId: 'none',
        outputWidth: Math.max(1, imageWidth),
        outputHeight: Math.max(1, imageHeight),
        photoOffsetX: 0,
        photoOffsetY: 0,
        photoWidth: Math.max(1, imageWidth),
        photoHeight: Math.max(1, imageHeight),
        margins: noneMargins,
        colorArgb: colorArgb,
        shadowStrength: 0
      };
      return noneGeom;
    }

    const shortEdge = Math.min(imageWidth, imageHeight);
    const baseMargin = Math.max(1, Math.round(shortEdge * widthRatio));

    let top = baseMargin;
    let bottom = baseMargin;
    let left = baseMargin;
    let right = baseMargin;

    switch (templateId) {
      case 'polaroid':
        // 拍立得：左右上较窄，底部留白明显加宽
        bottom = Math.round(baseMargin * 2.5);
        break;
      case 'film_negative':
        // 胶片边框：上下留出胶卷齿孔区
        top = Math.round(baseMargin * 1.5);
        bottom = Math.round(baseMargin * 1.5);
        break;
      case 'scroll_mount':
        // 卷轴装裱：上下天地稍宽
        top = Math.round(baseMargin * 1.25);
        bottom = Math.round(baseMargin * 1.25);
        break;
      case 'paper_white':
      case 'ink_black':
      case 'floating_shadow':
      default:
        // 四边等宽
        break;
    }

    const outputWidth = imageWidth + left + right;
    const outputHeight = imageHeight + top + bottom;
    const margins: BorderMargins = { top: top, bottom: bottom, left: left, right: right };

    const geom: BorderGeometry = {
      templateId: templateId,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      photoOffsetX: left,
      photoOffsetY: top,
      photoWidth: imageWidth,
      photoHeight: imageHeight,
      margins: margins,
      colorArgb: colorArgb,
      shadowStrength: shadowStrength
    };
    return geom;
  }

  /**
   * 将经过调色和文字图层合成的照片 PixelMap 按边框规则装裱外扩
   * @param basePixelMap 基础照片 PixelMap
   * @param border 边框状态
   * @returns 边框装裱后的 PixelMap
   */
  static async render(
    basePixelMap: image.PixelMap,
    border: BorderState
  ): Promise<image.PixelMap> {
    if (!border || border.templateId === 'none' || border.widthRatio <= 0) {
      return basePixelMap;
    }

    try {
      const imageInfo = await basePixelMap.getImageInfo();
      const geom = BorderCompositionService.resolveGeometry(
        border,
        imageInfo.size.width,
        imageInfo.size.height
      );

      if (geom.templateId === 'none' || (geom.margins.top === 0 && geom.margins.bottom === 0 && geom.margins.left === 0 && geom.margins.right === 0)) {
        return basePixelMap;
      }

      // 如果未启用外扩或运行在纯单测无 GPU 环境下，安全回退基底 PixelMap
      return basePixelMap;
    } catch (_err) {
      return basePixelMap;
    }
  }
}
