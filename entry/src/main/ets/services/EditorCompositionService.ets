import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { AdjustParams } from '../models/EditModels';
import { ExportProfile } from '../models/AppSettingsModels';
import { EditorSnapshot, cloneEditorSnapshot } from '../models/SharedContracts';
import { ImageRenderService } from './ImageRenderService';
import { TextCompositionService } from './TextCompositionService';
import { BorderCompositionService } from './BorderCompositionService';

/**
 * 合成渲染结果
 */
export interface CompositionRenderResult {
  pixelMap: image.PixelMap;
  width: number;
  height: number;
}

/**
 * 统一高清合成服务（EditorCompositionService）
 *
 * 依据：《Vivid_0.1.9更新计划》§3.2 & §4 (开发者 B)
 *
 * 统一确定性管线：
 * 1. 原图解码 (loadPixelMap)
 * 2. LUT 滤镜 (FilterNativeBridge)
 * 3. 调色参数 (applyAdjustments)
 * 4. 文字图层合成 (TextCompositionService)
 * 5. 边框画布外扩装裱 (BorderCompositionService)
 */
export class EditorCompositionService {
  /**
   * 统一全分辨率合成
   * @param sourceUri 源图 URI
   * @param adjustments 调色参数
   * @param snapshot 统一编辑快照（滤镜、文字、边框）
   * @param profile 导出配置
   * @param preserveSourceSize 是否保留原图分辨率
   * @param context 应用上下文
   * @returns 合成结果（包含最终 PixelMap 与尺寸）
   */
  static async render(
    sourceUri: string,
    adjustments: AdjustParams,
    snapshot: EditorSnapshot,
    profile: ExportProfile,
    preserveSourceSize: boolean = false,
    context?: common.UIAbilityContext
  ): Promise<CompositionRenderResult> {
    const safeSnapshot = cloneEditorSnapshot(snapshot);
    const filterId = safeSnapshot.filter.filterId ?? 'original';
    const strength = safeSnapshot.filter.strength ?? 0;

    let basePixelMap: image.PixelMap | null = null;
    let textedPixelMap: image.PixelMap | null = null;
    let finalPixelMap: image.PixelMap | null = null;

    try {
      // 1-3. 解码 + 滤镜 + 调色
      basePixelMap = await ImageRenderService.render(
        sourceUri,
        adjustments,
        profile,
        filterId,
        strength,
        preserveSourceSize,
        context
      );

      // 4. 文字图层
      textedPixelMap = await TextCompositionService.render(
        basePixelMap,
        safeSnapshot.textLayers
      );

      // 5. 边框装裱
      finalPixelMap = await BorderCompositionService.render(
        textedPixelMap,
        safeSnapshot.border
      );

      const info = await finalPixelMap.getImageInfo();

      const res: CompositionRenderResult = {
        pixelMap: finalPixelMap,
        width: info.size.width,
        height: info.size.height
      };
      return res;
    } catch (err) {
      // 异常时安全清理中间 PixelMap 防止内存泄漏
      if (finalPixelMap && finalPixelMap !== textedPixelMap && finalPixelMap !== basePixelMap) {
        finalPixelMap.release();
      }
      if (textedPixelMap && textedPixelMap !== basePixelMap) {
        textedPixelMap.release();
      }
      if (basePixelMap) {
        basePixelMap.release();
      }
      throw new Error(`Composition failed: ${(err as Error)?.message ?? 'UNKNOWN'}`);
    }
  }
}
