import { describe, it, expect } from '@ohos/hypium';
import {
  ADJUST_MAX,
  ADJUST_MIN,
  DEFAULT_ADJUSTMENTS,
  EditEntrySource,
  clampAdjustments,
  createDefaultAdjustments,
  editRouteError,
  parseEditRouteParams
} from '../main/ets/models/EditModels';

export default function editModelsTest() {
  describe('editModelsTest', () => {
    it('parses a picker route with image uri', 0, () => {
      const route = parseEditRouteParams({ source: 'picker', imageUri: 'file:///tmp/a.jpg' });
      expect(route === null).assertEqual(false);
      expect(route?.source).assertEqual(EditEntrySource.Picker);
      expect(route?.imageUri).assertEqual('file:///tmp/a.jpg');
    });

    it('parses a work route with workId', 0, () => {
      const route = parseEditRouteParams({ source: 'work', workId: '0409-A' });
      expect(route === null).assertEqual(false);
      expect(route?.source).assertEqual(EditEntrySource.Work);
      expect(route?.workId).assertEqual('0409-A');
    });

    it('returns null for missing or unknown source', 0, () => {
      expect(parseEditRouteParams({}) === null).assertEqual(true);
      expect(parseEditRouteParams({ source: 'other' }) === null).assertEqual(true);
    });

    it('reports a message when a route is null', 0, () => {
      expect(editRouteError(null)).assertEqual('路由参数缺失：请从首页选图或作品详情进入编辑页');
    });

    it('reports a message when picker lacks an image uri', 0, () => {
      expect(editRouteError(parseEditRouteParams({ source: 'picker' }))).assertEqual('未获取到所选图片，请返回重试');
    });

    it('reports a message when work lacks a work id', 0, () => {
      expect(editRouteError(parseEditRouteParams({ source: 'work' }))).assertEqual('未获取到作品编号，请返回重试');
    });

    it('returns empty message for a valid route', 0, () => {
      const route = parseEditRouteParams({ source: 'picker', imageUri: 'file:///tmp/a.jpg' });
      expect(editRouteError(route)).assertEqual('');
    });

    it('creates an all-zero default adjustment set', 0, () => {
      const p = createDefaultAdjustments();
      expect(p.exposure).assertEqual(0);
      expect(p.brightness).assertEqual(0);
      expect(p.contrast).assertEqual(0);
      expect(p.saturation).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.exposure).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.brightness).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.contrast).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.saturation).assertEqual(0);
    });

    it('returns an independent object on each default call', 0, () => {
      const a = createDefaultAdjustments();
      const b = createDefaultAdjustments();
      expect(a === b).assertEqual(false);
    });

    it('clamps adjustments into the -100..100 range', 0, () => {
      const out = clampAdjustments({ exposure: 120, brightness: -120, contrast: 50, saturation: 0 });
      expect(out.exposure).assertEqual(ADJUST_MAX);
      expect(out.brightness).assertEqual(ADJUST_MIN);
      expect(out.contrast).assertEqual(50);
      expect(out.saturation).assertEqual(0);
    });

    it('rounds and clamps fractional values', 0, () => {
      const out = clampAdjustments({ exposure: 101.6, brightness: -99.4, contrast: 99.6, saturation: -100.5 });
      expect(out.exposure).assertEqual(100);
      expect(out.brightness).assertEqual(-99);
      expect(out.contrast).assertEqual(100);
      expect(out.saturation).assertEqual(-100);
    });
  });
}
