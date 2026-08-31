import { describe, it, expect } from '@ohos/hypium';
import {
  cloneAdjustments,
  cloneRegionAdjustments,
  createDefaultAdjustments,
  createDefaultRegionAdjustments,
  AdjustParams,
  RegionAdjustments
} from '../main/ets/models/EditModels';
import { SegmentOutcome, SegmentationOutput, SegErrorCode } from '../main/ets/models/SegmentationModels';

/**
 * 编辑页三 Bug 修复 + 编译修复的本地单测。
 *
 * 覆盖：
 * - cloneAdjustments / cloneRegionAdjustments（替代 ArkTS 不支持的对象展开 `{ ...p }`）
 * - SegmentOutcome class（替代 ArkTS 不支持的对象字面量联合类型）
 *
 * PreviewRenderSession 的 dead 标志因依赖 @kit.ArkTS worker 无法本地单测，
 * 需真机集成验证。
 */
export default function editPageFixesTest() {
  describe('editPageFixesTest', () => {

    // ─────────────────── cloneAdjustments ───────────────────

    it('cloneAdjustments returns an equal but independent copy', 0, () => {
      const src: AdjustParams = { exposure: 0, brightness: 10, contrast: -20, saturation: 30, temperature: -40 };
      const copy = cloneAdjustments(src);
      expect(copy.exposure).assertEqual(0);
      expect(copy.brightness).assertEqual(10);
      expect(copy.contrast).assertEqual(-20);
      expect(copy.saturation).assertEqual(30);
      expect(copy.temperature).assertEqual(-40);
      // 修改副本不影响原对象
      copy.brightness = 99;
      expect(src.brightness).assertEqual(10);
    });

    it('cloneAdjustments with all-zero default is identity', 0, () => {
      const src = createDefaultAdjustments();
      const copy = cloneAdjustments(src);
      expect(copy.brightness).assertEqual(0);
      expect(copy.contrast).assertEqual(0);
      expect(copy.saturation).assertEqual(0);
      expect(copy.temperature).assertEqual(0);
    });

    it('cloneAdjustments returns a distinct object reference', 0, () => {
      const src = createDefaultAdjustments();
      const copy = cloneAdjustments(src);
      expect(copy === src).assertEqual(false);
    });

    it('cloneAdjustments handles boundary values', 0, () => {
      const max: AdjustParams = { exposure: 100, brightness: 100, contrast: 100, saturation: 100, temperature: 100 };
      const min: AdjustParams = { exposure: -100, brightness: -100, contrast: -100, saturation: -100, temperature: -100 };
      const maxCopy = cloneAdjustments(max);
      const minCopy = cloneAdjustments(min);
      expect(maxCopy.exposure).assertEqual(100);
      expect(maxCopy.brightness).assertEqual(100);
      expect(minCopy.temperature).assertEqual(-100);
    });

    // ─────────────────── cloneRegionAdjustments ───────────────────

    it('cloneRegionAdjustments copies both regions', 0, () => {
      const src: RegionAdjustments = {
        subject: { exposure: 0, brightness: 10, contrast: 0, saturation: 0, temperature: 0 },
        background: { exposure: 0, brightness: 0, contrast: -30, saturation: 20, temperature: 0 }
      };
      const copy = cloneRegionAdjustments(src);
      expect(copy.subject.exposure).assertEqual(0);
      expect(copy.subject.brightness).assertEqual(10);
      expect(copy.background.contrast).assertEqual(-30);
      expect(copy.background.saturation).assertEqual(20);
    });

    it('cloneRegionAdjustments subject is independent from source', 0, () => {
      const src = createDefaultRegionAdjustments();
      const copy = cloneRegionAdjustments(src);
      copy.subject.brightness = 50;
      expect(src.subject.brightness).assertEqual(0);
    });

    it('cloneRegionAdjustments background is independent from source', 0, () => {
      const src = createDefaultRegionAdjustments();
      const copy = cloneRegionAdjustments(src);
      copy.background.temperature = -80;
      expect(src.background.temperature).assertEqual(0);
    });

    it('cloneRegionAdjustments regions are independent from each other', 0, () => {
      const src = createDefaultRegionAdjustments();
      const copy = cloneRegionAdjustments(src);
      expect(copy.subject === copy.background).assertEqual(false);
    });

    it('cloneRegionAdjustments returns a distinct object reference', 0, () => {
      const src = createDefaultRegionAdjustments();
      const copy = cloneRegionAdjustments(src);
      expect(copy === src).assertEqual(false);
    });

    // ─────────────────── SegmentOutcome ───────────────────

    it('SegmentOutcome.ready sets status and output', 0, () => {
      const output: SegmentationOutput = {
        rawMask: { width: 100, height: 200, weights: new Uint8Array(0) },
        subjectCount: 3,
        subjectBounds: { left: 10, top: 20, width: 80, height: 160 }
      };
      const outcome = SegmentOutcome.ready(output);
      expect(outcome.status).assertEqual('ready');
      expect(outcome.output === output).assertEqual(true);
      expect(outcome.code).assertEqual(undefined);
    });

    it('SegmentOutcome.noSubject sets status only', 0, () => {
      const outcome = SegmentOutcome.noSubject();
      expect(outcome.status).assertEqual('noSubject');
      expect(outcome.output).assertEqual(undefined);
      expect(outcome.code).assertEqual(undefined);
    });

    it('SegmentOutcome.error sets status and code', 0, () => {
      const outcome = SegmentOutcome.error('TIMEOUT');
      expect(outcome.status).assertEqual('error');
      expect(outcome.code).assertEqual('TIMEOUT');
      expect(outcome.output).assertEqual(undefined);
    });

    it('SegmentOutcome.error works for all error codes', 0, () => {
      const codes: SegErrorCode[] = [
        'INIT_FAILED', 'TIMEOUT', 'SDK_ERROR',
        'NO_SUBJECT', 'INVALID_MASK', 'DECODE_FAILED', 'CANCELLED'
      ];
      for (let i = 0; i < codes.length; i++) {
        const outcome = SegmentOutcome.error(codes[i]);
        expect(outcome.status).assertEqual('error');
        expect(outcome.code).assertEqual(codes[i]);
      }
    });

    it('each SegmentOutcome factory call returns a distinct instance', 0, () => {
      const a = SegmentOutcome.noSubject();
      const b = SegmentOutcome.noSubject();
      expect(a === b).assertEqual(false);
    });

    it('SegmentOutcome default status is noSubject', 0, () => {
      const outcome = new SegmentOutcome();
      expect(outcome.status).assertEqual('noSubject');
      expect(outcome.output).assertEqual(undefined);
      expect(outcome.code).assertEqual(undefined);
    });

    it('SegmentOutcome ready carries the exact output reference', 0, () => {
      const output: SegmentationOutput = {
        rawMask: { width: 10, height: 10, weights: new Uint8Array(100) },
        subjectCount: 1,
        subjectBounds: { left: 0, top: 0, width: 10, height: 10 }
      };
      const outcome = SegmentOutcome.ready(output);
      expect(outcome.output?.subjectCount).assertEqual(1);
      expect(outcome.output?.rawMask.width).assertEqual(10);
      expect(outcome.output?.subjectBounds.left).assertEqual(0);
    });
  });
}
