import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import nativeFilter from 'libvivid_image.so';
import { FilterPreset } from './FilterModels';
import { decodeLutAscii } from './FilterLutUtils';

interface NativeFilterApi {
  loadLut(filterId: string, cubeText: string): boolean;
  render(pixelMap: image.PixelMap, filterId: string, strength: number): Promise<image.PixelMap>;
  clear(): void;
}

const nativeApi = nativeFilter as NativeFilterApi;

/** ArkTS-side resource loading and the single native render entry point. */
export class FilterNativeBridge {
  private static loadedFilterIds: string[] = [];

  static async loadPreset(context: common.UIAbilityContext, preset: FilterPreset): Promise<boolean> {
    if (preset.lutPath === undefined) {
      return true;
    }
    if (FilterNativeBridge.loadedFilterIds.includes(preset.id)) {
      return true;
    }
    try {
      const bytes = await context.resourceManager.getRawFileContent(preset.lutPath);
      const loaded = nativeApi.loadLut(preset.id, decodeLutAscii(bytes));
      console.info(`Filter LUT load: id=${preset.id} bytes=${bytes.length} loaded=${loaded}`);
      if (loaded) {
        FilterNativeBridge.loadedFilterIds.push(preset.id);
      }
      return loaded;
    } catch (err) {
      console.error(`Filter LUT load error for ${preset.id}: ${JSON.stringify(err)}`);
      return false;
    }
  }

  static async render(
    pixelMap: image.PixelMap,
    filterId: string,
    strength: number
  ): Promise<image.PixelMap> {
    console.info(`Filter render requested: id=${filterId} strength=${strength}`);
    const output = await nativeApi.render(pixelMap, filterId, strength);
    console.info(`Filter render completed: id=${filterId} strength=${strength}`);
    return output;
  }

  static clear(): void {
    nativeApi.clear();
    FilterNativeBridge.loadedFilterIds = [];
  }
}
