import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { ImageRenderService } from './ImageRenderService';

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

/**
 * Resolves an explicit preview card size inside the measured editor area.
 * Before the Image component reports its natural size, the full container is
 * used as a non-zero bootstrap size so ArkUI can mount and decode the source.
 */
export function fitPreviewCard(
  containerWidth: number,
  containerHeight: number,
  imageWidth: number,
  imageHeight: number
): PreviewDimensions {
  if (containerWidth <= 0 || containerHeight <= 0) {
    return { width: 0, height: 0 };
  }
  if (imageWidth <= 0 || imageHeight <= 0) {
    return {
      width: Math.max(1, Math.floor(containerWidth)),
      height: Math.max(1, Math.floor(containerHeight))
    };
  }
  const scale = Math.min(containerWidth / imageWidth, containerHeight / imageHeight);
  return {
    width: Math.max(1, Math.floor(imageWidth * scale)),
    height: Math.max(1, Math.floor(imageHeight * scale))
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

  replace(next: T): T {
    this.clear();
    this.current = next;
    return next;
  }

  clear(): void {
    if (this.current !== undefined) {
      this.releaseResult(this.current);
      this.current = undefined;
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
    return keepLatest(
      this.generations,
      () => renderTask(source),
      (stale: image.PixelMap) => stale.release()
    );
  }

  cancelPendingRenders(): void {
    this.generations.invalidate();
  }

  releaseSource(): void {
    if (this.sourcePixelMap !== undefined) {
      this.sourcePixelMap.release();
      this.sourcePixelMap = undefined;
    }
  }

  dispose(): void {
    this.generations.invalidate();
    this.releaseSource();
  }
}
