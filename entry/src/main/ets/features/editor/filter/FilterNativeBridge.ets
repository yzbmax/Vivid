import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import nativeFilter from 'libvivid_image.so';
import { FilterPreset } from './FilterModels';

interface NativeFilterApi {
  loadLut(filterId: string, cubeText: string): boolean;
  render(pixelMap: image.PixelMap, filterId: string, strength: number): Promise<image.PixelMap>;
  clear(): void;
}

const nativeApi = nativeFilter as NativeFilterApi;

function decodeAscii(bytes: Uint8Array): string {
  let result = '';
  const chunkSize = 8192;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    let chunk = '';
    const end = Math.min(bytes.length, offset + chunkSize);
    for (let i = offset; i < end; i++) {
      chunk += String.fromCharCode(bytes[i]);
    }
    result += chunk;
  }
  return result;
}

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
    const bytes = await context.resourceManager.getRawFileContent(preset.lutPath);
    const loaded = nativeApi.loadLut(preset.id, decodeAscii(bytes));
    console.info(`Filter LUT load: id=${preset.id} bytes=${bytes.length} loaded=${loaded}`);
    if (loaded) {
      FilterNativeBridge.loadedFilterIds.push(preset.id);
    }
    return loaded;
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
