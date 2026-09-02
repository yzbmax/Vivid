import { describe, it, expect } from '@ohos/hypium';
import {
  applyConfidenceCurve,
  defaultMaskTuning,
  resizeMaskBilinear
} from '../main/ets/utils/MaskProcessor';
import { MaskTuningConfig } from '../main/ets/models/SegmentationModels';

/** 2×2 蒙版：[[0,64],[192,255]]。 */
function makeGradMask(): Uint8Array {
  return new Uint8Array([0, 64, 192, 255]);
}

export default function maskProcessorTest() {
  describe('maskProcessorTest', () => {
    it('is identity with default tuning config', 0, () => {
      const src = makeGradMask();
      const out = applyConfidenceCurve(src, defaultMaskTuning());
      for (let i = 0; i < src.length; i++) {
        expect(out[i]).assertEqual(src[i]);
      }
    });

    it('suppresses low-confidence noise without touching strong subject', 0, () => {
      const src = new Uint8Array([10, 40, 230, 255]);
      const cfg: MaskTuningConfig = { lowConfidence: 60, highConfidence: 220 };
      const out = applyConfidenceCurve(src, cfg);
      // 低置信被压低（< 原值），高置信保持/抬升
      expect(out[0] < 10).assertTrue();
      expect(out[1] < 40).assertTrue();
      expect(out[2] >= 230).assertTrue();
      expect(out[3]).assertEqual(255);
    });

    it('keeps soft edges continuous (no binarization red line)', 0, () => {
      const src = new Uint8Array([100, 110, 120, 130]);
      const cfg: MaskTuningConfig = { lowConfidence: 60, highConfidence: 220 };
      const out = applyConfidenceCurve(src, cfg);
      // 相邻值仍单调递增且差值有界——边缘未被二值化
      expect(out[1] > out[0]).assertTrue();
      expect(out[2] > out[1]).assertTrue();
      expect(out[3] > out[2]).assertTrue();
      expect(out[3] - out[0] < 80).assertTrue();
    });

    it('returns a copy for same-size resize', 0, () => {
      const src = makeGradMask();
      const out = resizeMaskBilinear(src, 2, 2, 2, 2);
      expect(out.length).assertEqual(4);
      for (let i = 0; i < 4; i++) {
        expect(out[i]).assertEqual(src[i]);
      }
      // 拷贝语义：改 out 不影响 src
      out[0] = 99;
      expect(src[0]).assertEqual(0);
    });

    it('upsamples preserving corner values approximately', 0, () => {
      const src = makeGradMask(); // 2×2 → 4×4
      const out = resizeMaskBilinear(src, 2, 2, 4, 4);
      expect(out.length).assertEqual(16);
      // 角落像素中心对齐后应接近原角值
      expect(Math.abs(out[0] - src[0]) <= 2).assertTrue();
      expect(Math.abs(out[3] - src[1]) <= 2).assertTrue();
      expect(Math.abs(out[12] - src[2]) <= 2).assertTrue();
      expect(Math.abs(out[15] - src[3]) <= 2).assertTrue();
      // 中间是插值（介于最小与最大之间）
      const mid = out[5];
      expect(mid >= 0).assertTrue();
      expect(mid <= 255).assertTrue();
    });

    it('downsamples to target size', 0, () => {
      const big = new Uint8Array(16);
      for (let i = 0; i < 16; i++) {
        big[i] = (i * 16) % 256;
      }
      const out = resizeMaskBilinear(big, 4, 4, 2, 2);
      expect(out.length).assertEqual(4);
      for (let i = 0; i < 4; i++) {
        if (out[i] < 0 || out[i] > 255) {
          expect(out[i]).assertEqual(-1); // 显式失败
          break;
        }
      }
    });

    it('handles empty input safely', 0, () => {
      expect(resizeMaskBilinear(new Uint8Array(0), 0, 0, 4, 4).length).assertEqual(0);
    });
  });
}
