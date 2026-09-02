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

    // ──────── Vivid 0.1.9：8 款新增 LUT 缓存键（任务 4）────────

    it('produces unique cache keys for the 8 new Vivid 0.1.9 presets', 0, () => {
      const newPresetIds: string[] = [
        'jade_mist', 'cinnabar_glow', 'ink_noir', 'rice_paper',
        'tea_film', 'celadon_cool', 'amber_hour', 'moonlit_blue'
      ];
      const seen: string[] = [];
      for (const id of newPresetIds) {
        const preset: FilterPreset = { id: id, name: id, defaultStrength: 0.7, version: 1 };
        const key = buildThumbnailCacheKey('session-1', preset);
        // 格式：sessionId + preset.id + preset.version
        expect(key).assertEqual('session-1_' + id + '_1');
        const dup = seen.find((s) => s === key);
        expect(dup === undefined).assertTrue();
        seen.push(key);
      }
    });

    it('does not fall back to source thumbnail for any new 0.1.9 preset', 0, () => {
      expect(canUseSourceThumbnailFallback('jade_mist')).assertFalse();
      expect(canUseSourceThumbnailFallback('ink_noir')).assertFalse();
      expect(canUseSourceThumbnailFallback('moonlit_blue')).assertFalse();
    });
  });
}
