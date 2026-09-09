import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { ImageRenderService } from './ImageRenderService';
export { fitPreviewCard } from '../features/editor/preview/EditorPreviewLayout';

/** Preview renders never decode a source image beyond this long edge. */
export const PREVIEW_MAX_LONG_EDGE: number = 1440;

export interface PreviewDimensions {
  width: number;
  height: number;
}

/** A decoded PixelMap is a complete preview source and must not depend on a URI fallback. */
export function hasRenderablePreview(imageSrc: string, pixelMapAvailable: boolean): boolean {
  return pixelMapAvailable || imageSrc !== '';
}

/** URI fallback is used only after the authoritative PixelMap load has finished and failed. */
export function shouldRenderUriFallback(
  imageSrc: string,
  pixelMapAvailable: boolean,
  previewLoading: boolean
): boolean {
  return !previewLoading && !pixelMapAvailable && imageSrc !== '';
}

/**
 * Computes a preview decode size without upscaling smaller images.
 * Invalid dimensions return a zero-sized result so callers can fail safely.
 */
export function fitPreviewDimensions(
  width: number,
  height: number,
  maxLongEdge: number = PREVIEW_MAX_LONG_EDGE
): PreviewDimensions {
  if (width <= 0 || height <= 0 || maxLongEdge <= 0) {
    return { width: 0, height: 0 };
  }
  const longEdge = Math.max(width, height);
  if (longEdge <= maxLongEdge) {
    return { width: Math.round(width), height: Math.round(height) };
  }
  const scale = maxLongEdge / longEdge;
  return {
    width: Math.max(1, Math.round(width * scale)),
    height: Math.max(1, Math.round(height * scale))
  };
}

/** Monotonically increasing token used to discard out-of-order renders. */
export class RenderGeneration {
  private renderGeneration: number = 0;

  begin(): number {
    this.renderGeneration += 1;
    return this.renderGeneration;
  }

  invalidate(): number {
    return this.begin();
  }

  isCurrent(generation: number): boolean {
    return generation === this.renderGeneration;
  }
}

/** Owns only generated render results; the immutable source PixelMap is never released here. */
export class OwnedRenderResult<T> {
  private current: T | undefined = undefined;
  private releaseResult: (value: T) => void;

  constructor(releaseResult: (value: T) => void) {
    this.releaseResult = releaseResult;
  }

  replace(next: T, borrowed?: T): T {
    if (next === this.current) {
      return next;
    }
    const previous = this.current;
    // 原图由 PreviewPipeline 持有，不能随临时滤镜结果一起释放。
    this.current = next === borrowed ? undefined : next;
    if (previous !== undefined) {
      this.releaseResult(previous);
    }
    return next;
  }

  clear(): void {
    if (this.current !== undefined) {
      const target = this.current;
      this.current = undefined;
      this.releaseResult(target);
    }
  }
}

/**
 * Runs one render and releases its result if a newer request won the race.
 * The release callback is deliberately injected so this helper remains unit-testable.
 */
export async function keepLatest<T>(
  generations: RenderGeneration,
  render: () => Promise<T>,
  release: (value: T) => void
): Promise<T | undefined> {
  const generation = generations.begin();
  const result = await render();
  if (!generations.isCurrent(generation)) {
    release(result);
    return undefined;
  }
  return result;
}

/** Owns the downscaled source PixelMap and protects the UI from stale results. */
export class PreviewPipeline {
  private sourcePixelMap: image.PixelMap | undefined;
  private generations: RenderGeneration = new RenderGeneration();
  private isRendering: boolean = false;
  private pendingTask: ((source: image.PixelMap) => Promise<image.PixelMap>) | undefined = undefined;
  private pendingResolves: Array<(result: image.PixelMap | undefined) => void> = [];

  async loadSource(
    sourceUri: string,
    context?: common.UIAbilityContext
  ): Promise<image.PixelMap> {
    const next = await ImageRenderService.createPreviewSource(
      sourceUri,
      PREVIEW_MAX_LONG_EDGE,
      context
    );
    this.releaseSource();
    this.sourcePixelMap = next;
    this.generations.invalidate();
    return next;
  }

  async render(
    renderTask: (source: image.PixelMap) => Promise<image.PixelMap>
  ): Promise<image.PixelMap | undefined> {
    const source = this.sourcePixelMap;
    if (source === undefined) {
      return undefined;
    }

    if (this.isRendering) {
      // 正在高频切换中，提前结算上一轮等待中的过时请求（丢弃中间帧，杜绝并发堆叠）
      const superseded = this.pendingResolves;
      this.pendingResolves = [];
      for (let i = 0; i < superseded.length; i++) {
        superseded[i](undefined);
      }

      return new Promise<image.PixelMap | undefined>((resolve: (value: image.PixelMap | undefined) => void): void => {
        this.pendingTask = renderTask;
        this.pendingResolves.push(resolve);
      });
    }

    this.isRendering = true;
    try {
      let currentTask: ((source: image.PixelMap) => Promise<image.PixelMap>) | undefined = renderTask;
      let lastResult: image.PixelMap | undefined = undefined;

      while (currentTask !== undefined) {
        const activeTask: (source: image.PixelMap) => Promise<image.PixelMap> = currentTask;
        currentTask = undefined;

        lastResult = await keepLatest<image.PixelMap>(
          this.generations,
          (): Promise<image.PixelMap> => {
            return activeTask(source);
          },
          (stale: image.PixelMap): void => {
            if (stale !== source) {
              stale.release();
            }
          }
        );

        // 如果在当前渲染执行期间又有最新请求进来，继续执行最新请求，丢弃中间结果
        if (this.pendingTask !== undefined) {
          currentTask = this.pendingTask;
          this.pendingTask = undefined;
          if (lastResult !== undefined && lastResult !== source) {
            lastResult.release();
            lastResult = undefined;
          }
        }
      }

      if (this.pendingResolves.length > 0) {
        const waiting = this.pendingResolves;
        this.pendingResolves = [];
        for (let i = 0; i < waiting.length; i++) {
          waiting[i](lastResult);
        }
        return undefined;
      }

      return lastResult;
    } finally {
      this.isRendering = false;
      this.pendingTask = undefined;
      const leftover = this.pendingResolves;
      this.pendingResolves = [];
      for (let i = 0; i < leftover.length; i++) {
        leftover[i](undefined);
      }
    }
  }

  cancelPendingRenders(): void {
    this.generations.invalidate();
    this.pendingTask = undefined;
    const waiting = this.pendingResolves;
    this.pendingResolves = [];
    for (let i = 0; i < waiting.length; i++) {
      waiting[i](undefined);
    }
  }

  releaseSource(): void {
    if (this.sourcePixelMap !== undefined) {
      this.sourcePixelMap.release();
      this.sourcePixelMap = undefined;
    }
  }

  setSourcePixelMapForTest(source: image.PixelMap | undefined): void {
    this.sourcePixelMap = source;
  }

  dispose(): void {
    this.cancelPendingRenders();
    this.releaseSource();
  }
}
