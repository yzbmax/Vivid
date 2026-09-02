import { describe, it, expect } from '@ohos/hypium';
import {
  buildThumbnailCacheKey,
  canUseSourceThumbnailFallback
} from '../main/ets/services/ThumbnailPipeline';
import { FilterPreset } from '../main/ets/features/editor/filter/FilterModels';

export default function thumbnailPipelineTest() {
  describe('thumbnailPipelineTest', () => {
    it('includes photo session, filter id and version in cache keys', 0, () => {
      const preset: FilterPreset = {
        id: 'test_warm',
        name: '暖阳',
        defaultStrength: 0.75,
        version: 3
      };
      expect(buildThumbnailCacheKey('photo-001', preset)).assertEqual('photo-001_test_warm_3');
    });

    it('changes the key when a preset version changes', 0, () => {
      const first: FilterPreset = {
        id: 'identity', name: 'Identity', defaultStrength: 1, version: 1
      };
      const second: FilterPreset = {
        id: 'identity', name: 'Identity', defaultStrength: 1, version: 2
      };
      expect(buildThumbnailCacheKey('photo-001', first) === buildThumbnailCacheKey('photo-001', second))
        .assertFalse();
    });

    it('never presents the source image as a rendered LUT thumbnail', 0, () => {
      expect(canUseSourceThumbnailFallback('original')).assertTrue();
      expect(canUseSourceThumbnailFallback('fieldnote')).assertFalse();
    });
  });
}
