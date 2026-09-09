import { describe, it, expect } from '@ohos/hypium';
import { image } from '@kit.ImageKit';
import {
  PREVIEW_MAX_LONG_EDGE,
  OwnedRenderResult,
  PreviewPipeline,
  RenderGeneration,
  fitPreviewCard,
  fitPreviewDimensions,
  hasRenderablePreview,
  keepLatest,
  shouldRenderUriFallback
} from '../main/ets/services/PreviewPipeline';

export default function previewPipelineTest() {
  describe('previewPipelineTest', () => {
    it('fits landscape images to the 1440px long edge', 0, () => {
      const size = fitPreviewDimensions(4000, 3000);
      expect(size.width).assertEqual(PREVIEW_MAX_LONG_EDGE);
      expect(size.height).assertEqual(1080);
    });

    it('fits portrait images without upscaling', 0, () => {
      const size = fitPreviewDimensions(800, 1200);
      expect(size.width).assertEqual(800);
      expect(size.height).assertEqual(1200);
    });

    it('rounds dimensions and preserves a square', 0, () => {
      const size = fitPreviewDimensions(2001, 2001);
      expect(size.width).assertEqual(PREVIEW_MAX_LONG_EDGE);
      expect(size.height).assertEqual(PREVIEW_MAX_LONG_EDGE);
    });

    it('gives an undecoded preview a non-zero bootstrap size', 0, () => {
      const size = fitPreviewCard(440, 580, 0, 0);
      expect(size.width).assertEqual(440);
      expect(size.height).assertEqual(580);
    });

    it('fits a portrait preview inside the measured container', 0, () => {
      const size = fitPreviewCard(440, 580, 1084, 1440);
      expect(size.width).assertEqual(436);
      expect(size.height).assertEqual(580);
    });

    it('renders a decoded PixelMap even when the fallback URI is empty', 0, () => {
      expect(hasRenderablePreview('', true)).assertTrue();
      expect(hasRenderablePreview('', false)).assertFalse();
    });

    it('does not start a URI image request while PixelMap decoding is in progress', 0, () => {
      expect(shouldRenderUriFallback('file://media/Photo/1', false, true)).assertFalse();
      expect(shouldRenderUriFallback('file://media/Photo/1', false, false)).assertTrue();
      expect(shouldRenderUriFallback('file://media/Photo/1', true, false)).assertFalse();
    });

    it('invalidates stale render generations', 0, () => {
      const generations = new RenderGeneration();
      const first = generations.begin();
      const second = generations.begin();
      expect(generations.isCurrent(first)).assertFalse();
      expect(generations.isCurrent(second)).assertTrue();
    });

    it('releases a result that finishes after a newer request', 0, async () => {
      const generations = new RenderGeneration();
      let released = 0;
      let resolveFirst: ((value: string) => void) | undefined;
      const firstPromise = keepLatest(
        generations,
        () => new Promise<string>((resolve) => { resolveFirst = resolve; }),
        () => { released += 1; }
      );
      generations.begin();
      if (resolveFirst !== undefined) {
        resolveFirst('stale');
      }
      const result = await firstPromise;
      expect(result).assertUndefined();
      expect(released).assertEqual(1);
    });

    it('releases only rendered results when replacing the visible preview', 0, () => {
      const released: string[] = [];
      const owner = new OwnedRenderResult<string>((value: string) => released.push(value));
      owner.replace('first-filter');
      owner.replace('second-filter');
      expect(released.length).assertEqual(1);
      expect(released[0]).assertEqual('first-filter');
      owner.clear();
      expect(released.length).assertEqual(2);
      expect(released[1]).assertEqual('second-filter');
    });

    it('conflates rapid renders and executes only the latest pending task', 0, async (): Promise<void> => {
      const pipeline = new PreviewPipeline();
      const mockSource = { release: (): void => {} } as image.PixelMap;
      pipeline.setSourcePixelMapForTest(mockSource);

      const executedTasks: string[] = [];
      let resolveFirst: ((pm: image.PixelMap) => void) | undefined;

      const p1 = pipeline.render((): Promise<image.PixelMap> => new Promise<image.PixelMap>((res: (pm: image.PixelMap) => void): void => {
        executedTasks.push('task1');
        resolveFirst = res;
      }));

      const p2 = pipeline.render((): Promise<image.PixelMap> => {
        executedTasks.push('task2');
        return Promise.resolve({ release: (): void => {} } as image.PixelMap);
      });

      const p3 = pipeline.render((): Promise<image.PixelMap> => {
        executedTasks.push('task3');
        return Promise.resolve({ release: (): void => {} } as image.PixelMap);
      });

      expect(executedTasks.length).assertEqual(1);
      expect(executedTasks[0]).assertEqual('task1');

      const pm1 = { release: (): void => {} } as image.PixelMap;
      if (resolveFirst !== undefined) {
        resolveFirst(pm1);
      }

      const res1 = await p1;
      const res2 = await p2;
      const res3 = await p3;

      expect(res1).assertUndefined();
      expect(res2).assertUndefined();
      expect(res3 !== undefined).assertTrue();
      expect(executedTasks.length).assertEqual(2);
      expect(executedTasks[0]).assertEqual('task1');
      expect(executedTasks[1]).assertEqual('task3');
    });
  });
}
