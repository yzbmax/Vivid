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
  private generation: number = 0;
  private activeRenders: number = 0;
  private retiredSources: image.PixelMap[] = [];

  async loadSource(
    sourceUri: string,
    sessionId: string,
    context?: common.UIAbilityContext
  ): Promise<void> {
    this.clear();
    const generation = this.generation;
    const source = await ImageRenderService.createPreviewSource(
      sourceUri,
      THUMBNAIL_MAX_LONG_EDGE,
      context
    );
    if (generation !== this.generation) {
      source.release();
      return;
    }
    this.sourcePixelMap = source;
    this.sessionId = sessionId;
  }

  async renderPreset(
    context: common.UIAbilityContext,
    preset: FilterPreset
  ): Promise<image.PixelMap | undefined> {
    if (this.sourcePixelMap === undefined || this.sessionId === '') {
      return undefined;
    }
    const source = this.sourcePixelMap;
    const generation = this.generation;
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
    if (generation !== this.generation) {
      return undefined;
    }
    this.activeRenders++;
    try {
      const rendered = await FilterNativeBridge.render(source, preset.id, 1);
      if (generation !== this.generation) {
        if (rendered !== source) {
          rendered.release();
        }
        return undefined;
      }
      this.cache.set(key, rendered);
      return rendered;
    } finally {
      this.activeRenders--;
      if (this.activeRenders === 0) {
        for (const retired of this.retiredSources) {
          retired.release();
        }
        this.retiredSources = [];
      }
    }
  }

  clear(): void {
    this.generation++;
    this.cache.forEach((pixelMap: image.PixelMap) => {
      if (pixelMap !== this.sourcePixelMap) {
        pixelMap.release();
      }
    });
    this.cache.clear();
    if (this.sourcePixelMap !== undefined) {
      if (this.activeRenders > 0) {
        this.retiredSources.push(this.sourcePixelMap);
      } else {
        this.sourcePixelMap.release();
      }
      this.sourcePixelMap = undefined;
    }
    this.sessionId = '';
  }
}
