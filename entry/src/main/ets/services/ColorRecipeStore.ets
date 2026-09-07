import { ColorRecipe } from '../models/ColorRecipe';
import { AdjustParams } from '../models/EditModels';
import { RegionAdjustParams } from '../models/SharedContracts';

/**
 * 调色配方存储管理服务（内存与跨页面共享）
 */
export class ColorRecipeStore {
  private static cachedRecipe: ColorRecipe | undefined = undefined;

  /**
   * 复制当前调色配方
   */
  static copyRecipe(
    adjustments: AdjustParams,
    filterId: string,
    filterStrength: number,
    regionAdjustments?: RegionAdjustParams,
    name?: string
  ): void {
    ColorRecipeStore.cachedRecipe = {
      version: 1,
      name,
      adjustments: {
        exposure: adjustments.exposure,
        brightness: adjustments.brightness,
        contrast: adjustments.contrast,
        saturation: adjustments.saturation,
        temperature: adjustments.temperature
      },
      filterId: filterId || 'original',
      filterStrength: filterStrength !== undefined ? filterStrength : 1.0,
      regionAdjustments: regionAdjustments ? JSON.parse(JSON.stringify(regionAdjustments)) : undefined,
      timestamp: Date.now()
    };
    try {
      AppStorage.setOrCreate<boolean>('vivid_has_recipe', true);
    } catch (_e) {}
  }

  /**
   * 是否存在已复制的配方
   */
  static hasRecipe(): boolean {
    return ColorRecipeStore.cachedRecipe !== undefined;
  }

  /**
   * 获取已复制的配方
   */
  static getRecipe(): ColorRecipe | undefined {
    return ColorRecipeStore.cachedRecipe;
  }

  /**
   * 清空剪贴板配方
   */
  static clear(): void {
    ColorRecipeStore.cachedRecipe = undefined;
    try {
      AppStorage.setOrCreate<boolean>('vivid_has_recipe', false);
    } catch (_e) {}
  }
}
