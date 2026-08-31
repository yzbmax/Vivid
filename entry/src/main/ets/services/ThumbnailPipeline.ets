import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { ImageRenderService } from './ImageRenderService';
import { FilterNativeBridge } from '../features/editor/filter/FilterNativeBridge';
import { FilterPreset } from '../features/editor/filter/FilterModels';

export const THUMBNAIL_MAX_LONG_EDGE: number = 256;

export interface ThumbnailItem {
  filterId: string;
  pixelMap: image.PixelMap;
}

export function buildThumbnailCacheKey(photoSessionId: string, preset: FilterPreset): string {
  return `${photoSessionId}_${preset.id}_${preset.version}`;
}

/** Only Original may display the common source image before its cache entry is ready. */
export function canUseSourceThumbnailFallback(filterId: string): boolean {
  return filterId === 'original';
}

/** In-memory thumbnail owner, scoped to one photo editing session. */
export class ThumbnailPipeline {
  private sourcePixelMap: image.PixelMap | undefined;
  private cache: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private sessionId: string = '';

  async loadSource(
    sourceUri: string,
    sessionId: string,
    context?: common.UIAbilityContext
  ): Promise<void> {
    this.clear();
    this.sourcePixelMap = await ImageRenderService.createPreviewSource(
      sourceUri,
      THUMBNAIL_MAX_LONG_EDGE,
      context
    );
    this.sessionId = sessionId;
  }

  async renderPreset(
    context: common.UIAbilityContext,
    preset: FilterPreset
  ): Promise<image.PixelMap | undefined> {
    if (this.sourcePixelMap === undefined || this.sessionId === '') {
      return undefined;
    }
    const key = buildThumbnailCacheKey(this.sessionId, preset);
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      return cached;
    }
    if (preset.id === 'original') {
      this.cache.set(key, this.sourcePixelMap);
      return this.sourcePixelMap;
    }
    if (!(await FilterNativeBridge.loadPreset(context, preset))) {
      return undefined;
    }
    const rendered = await FilterNativeBridge.render(this.sourcePixelMap, preset.id, 1);
    this.cache.set(key, rendered);
    return rendered;
  }

  clear(): void {
    this.cache.forEach((pixelMap: image.PixelMap) => {
      if (pixelMap !== this.sourcePixelMap) {
        pixelMap.release();
      }
    });
    this.cache.clear();
    if (this.sourcePixelMap !== undefined) {
      this.sourcePixelMap.release();
      this.sourcePixelMap = undefined;
    }
    this.sessionId = '';
  }
}
