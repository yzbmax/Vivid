import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AdjustParams } from '../models/EditModels';
import { ExportProfile } from '../models/AppSettingsModels';
import { FilterNativeBridge } from '../features/editor/filter/FilterNativeBridge';
import { isPhotoPickerUri } from './PhotoPickerService';

/**
 * 图片渲染服务：根据源图和调色参数生成可编码的 PixelMap。
 *
 * 职责：
 * 1. 从 sourceImageUri 加载图片
 * 2. 应用 adjustments 参数（曝光、亮度、对比度、饱和度）
 * 3. 按 ExportProfile 调整尺寸
 * 4. 返回可编码的 PixelMap
 */
export class ImageRenderService {
  /** Decode a bounded-size source PixelMap for the interactive preview. */
  static async createPreviewSource(
    sourceUri: string,
    maxLongEdge: number = 1440,
    context?: common.UIAbilityContext
  ): Promise<image.PixelMap> {
    return ImageRenderService.loadPixelMap(sourceUri, maxLongEdge, context);
  }

  /**
   * 从源图 + 调色参数生成可编码的 PixelMap
   * @param sourceUri 源图 URI（从 PhotoPicker 获取）
   * @param params 调色参数
   * @param profile 导出配置
   * @returns 处理后的 PixelMap
   */
  static async render(
    sourceUri: string,
    params: AdjustParams,
    profile: ExportProfile,
    filterId: string = 'original',
    strength: number = 0,
    preserveSourceSize: boolean = false,
    context?: common.UIAbilityContext
  ): Promise<image.PixelMap> {
    const maxLongEdge = preserveSourceSize ? 0 : profile.maxLongEdge;
    let pixelMap = await ImageRenderService.loadPixelMap(sourceUri, maxLongEdge, context);

    // Export starts from a fresh source PixelMap; the preview PixelMap is never reused.
    if (filterId !== 'original' && strength > 0) {
      try {
        const filtered = await FilterNativeBridge.render(pixelMap, filterId, strength);
        pixelMap.release();
        pixelMap = filtered;
      } catch (_err) {
        pixelMap.release();
        throw new Error('Native filter render failed');
      }
    }

    // 4. 应用调色参数
    const adjusted = await ImageRenderService.applyAdjustments(pixelMap, params);
    if (adjusted !== pixelMap) {
      pixelMap.release();
    }
    return adjusted;
  }

  private static async loadPixelMap(
    sourceUri: string,
    maxLongEdge: number,
    context?: common.UIAbilityContext
  ): Promise<image.PixelMap> {
    // Picker URIs are materialized by PhotoPickerService before navigation.
    // Never pass a provider URI into ImageKit or MediaAssetManager from the
    // editor lifecycle; a stale temporary grant must fail safely instead.
    if (isPhotoPickerUri(sourceUri)) {
      throw new Error('Photo picker URI was not materialized');
    }

    const sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
    const imageSource = image.createImageSource(sourceFile.fd);
    try {
      const imageInfo = await imageSource.getImageInfo();
      const longEdge = Math.max(imageInfo.size.width, imageInfo.size.height);

      const decodingOptions: image.DecodingOptions = {
        editable: true,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      if (maxLongEdge > 0 && longEdge > maxLongEdge) {
        const scale = maxLongEdge / longEdge;
        decodingOptions.desiredSize = {
          width: Math.max(1, Math.round(imageInfo.size.width * scale)),
          height: Math.max(1, Math.round(imageInfo.size.height * scale))
        };
      }

      return await imageSource.createPixelMap(decodingOptions);
    } finally {
      await imageSource.release();
      fs.closeSync(sourceFile.fd);
    }
  }

  /**
   * 应用调色参数到 PixelMap
   *
   * 使用颜色矩阵实现对比度、饱和度、曝光和亮度。
   * effectKit 的 setColorMatrix 接受 4x5 颜色变换矩阵。
   */
  private static async applyAdjustments(
    pixelMap: image.PixelMap,
    params: AdjustParams
  ): Promise<image.PixelMap> {
    // 如果所有参数都是默认值，直接返回原图
    if (
      params.exposure === 0 &&
      params.brightness === 0 &&
      params.contrast === 0 &&
      params.saturation === 0
    ) {
      return pixelMap;
    }

    // 构建组合颜色矩阵：先饱和度，再对比度，再亮度/曝光
    const saturation = 1 + (params.saturation / 100) * 0.8; // [0.2, 1.8]
    const contrast = 1 + (params.contrast / 100) * 0.9; // [0.1, 1.9]

    // 曝光 + 亮度 → 明暗偏移 [-0.55, 0.55]
    const lumOffset =
      (params.exposure * 0.30 + params.brightness * 0.25) / 100;

    // 构建 4x5 颜色矩阵（行优先，每行5个元素）
    const matrix = ImageRenderService.buildCombinedMatrix(
      saturation, contrast, lumOffset
    );

    // 使用 effectKit 应用颜色矩阵
    const effect = effectKit.createEffect(pixelMap);
    if (effect == null) {
      // effectKit 不可用时返回原图
      return pixelMap;
    }

    effect.setColorMatrix(matrix);
    const result = await effect.getEffectPixelMap();

    return result;
  }

  /**
   * 构建组合颜色矩阵：饱和度 × 对比度 + 亮度偏移
   */
  private static buildCombinedMatrix(
    saturation: number,
    contrast: number,
    lumOffset: number
  ): number[] {
    // 亮度矩阵（对角线 + 偏移）
    // contrast × saturation 矩阵
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    // 饱和度矩阵
    const s00 = (1 - saturation) * lumR + saturation;
    const s01 = (1 - saturation) * lumG;
    const s02 = (1 - saturation) * lumB;
    const s10 = (1 - saturation) * lumR;
    const s11 = (1 - saturation) * lumG + saturation;
    const s12 = (1 - saturation) * lumB;
    const s20 = (1 - saturation) * lumR;
    const s21 = (1 - saturation) * lumG;
    const s22 = (1 - saturation) * lumB + saturation;

    // 对比度矩阵（对角线缩放）
    const ct = (1 - contrast) / 2;

    // 组合：对比度 × 饱和度，然后加亮度偏移
    // 对比度作用于 RGB 通道
    const r0 = contrast * s00;
    const r1 = contrast * s01;
    const r2 = contrast * s02;
    const rOffset = ct + lumOffset;

    const g0 = contrast * s10;
    const g1 = contrast * s11;
    const g2 = contrast * s12;
    const gOffset = ct + lumOffset;

    const b0 = contrast * s20;
    const b1 = contrast * s21;
    const b2 = contrast * s22;
    const bOffset = ct + lumOffset;

    // 4x5 矩阵（行优先）
    return [
      r0, r1, r2, 0, rOffset,
      g0, g1, g2, 0, gOffset,
      b0, b1, b2, 0, bOffset,
      0, 0, 0, 1, 0
    ];
  }
}
