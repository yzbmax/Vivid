import { describe, it, expect } from '@ohos/hypium';
import {
  mattingListToWeights,
  validateRawMask,
  weightsToGrayRgba,
  weightsToOverlayRgba
} from '../main/ets/utils/MaskDataUtils';
import { RectData } from '../main/ets/models/SegmentationModels';

export default function maskDataUtilsTest() {
  describe('maskDataUtilsTest', () => {
    it('clamps negative and overflowing matting values', 0, () => {
      const out = mattingListToWeights(new Int32Array([-5, 0, 128, 300, 255]));
      expect(out.length).assertEqual(5);
      expect(out[0]).assertEqual(0);
      expect(out[1]).assertEqual(0);
      expect(out[2]).assertEqual(128);
      expect(out[3]).assertEqual(255);
      expect(out[4]).assertEqual(255);
    });

    it('keeps mid-range matting values unchanged', 0, () => {
      const out = mattingListToWeights(new Int32Array([1, 64, 127, 254]));
      expect(out[0]).assertEqual(1);
      expect(out[1]).assertEqual(64);
      expect(out[2]).assertEqual(127);
      expect(out[3]).assertEqual(254);
    });

    it('validates a correct raw mask', 0, () => {
      const bounds: RectData = { left: 1, top: 1, width: 2, height: 2 };
      const v = validateRawMask(4, 4,
        new Uint8Array([0, 0, 0, 0, 0, 10, 20, 0, 0, 30, 40, 0, 0, 0, 0, 0]), bounds);
      expect(v.ok).assertTrue();
    });

    it('rejects non-positive dimensions', 0, () => {
      const bounds: RectData = { left: 0, top: 0, width: 0, height: 0 };
      const v = validateRawMask(0, 4, new Uint8Array(0), bounds);
      expect(v.ok).assertFalse();
    });

    it('rejects weight length mismatch', 0, () => {
      const bounds: RectData = { left: 0, top: 0, width: 2, height: 2 };
      const v = validateRawMask(2, 2, new Uint8Array([255, 255, 255]), bounds);
      expect(v.ok).assertFalse();
    });

    it('rejects all-zero weights', 0, () => {
      const bounds: RectData = { left: 0, top: 0, width: 2, height: 2 };
      const v = validateRawMask(2, 2, new Uint8Array(4), bounds);
      expect(v.ok).assertFalse();
    });

    it('rejects empty subject rectangle', 0, () => {
      const bounds: RectData = { left: 0, top: 0, width: 0, height: 0 };
      const v = validateRawMask(2, 2, new Uint8Array([255, 0, 0, 0]), bounds);
      expect(v.ok).assertFalse();
    });

    it('rejects out-of-bounds rectangles on each edge', 0, () => {
      const w = new Uint8Array([255, 255, 255, 255]);
      const left: RectData = { left: -1, top: 0, width: 2, height: 2 };
      const top: RectData = { left: 0, top: -1, width: 2, height: 2 };
      const right: RectData = { left: 1, top: 0, width: 2, height: 2 };
      const bottom: RectData = { left: 0, top: 1, width: 2, height: 2 };
      expect(validateRawMask(2, 2, w, left).ok).assertFalse();
      expect(validateRawMask(2, 2, w, top).ok).assertFalse();
      expect(validateRawMask(2, 2, w, right).ok).assertFalse();
      expect(validateRawMask(2, 2, w, bottom).ok).assertFalse();
    });

    it('maps weights to grayscale rgba with endpoints', 0, () => {
      const rgba = weightsToGrayRgba(new Uint8Array([0, 128, 255]));
      expect(rgba.length).assertEqual(12);
      expect(rgba[0]).assertEqual(0);
      expect(rgba[3]).assertEqual(255); // alpha opaque
      expect(rgba[4]).assertEqual(128);
      expect(rgba[5]).assertEqual(128);
      expect(rgba[8]).assertEqual(255);
    });

    it('blends overlay colors by real weights at endpoints', 0, () => {
      // 主体红(178,59,47) ↔ 背景青绿(44,98,180)，alphaBase=200
      const rgba = weightsToOverlayRgba(
        new Uint8Array([0, 255, 128]),
        [178, 59, 47], [44, 98, 180], 200);
      // w=0：纯背景色，alpha=0
      expect(rgba[0]).assertEqual(44);
      expect(rgba[1]).assertEqual(98);
      expect(rgba[2]).assertEqual(180);
      expect(rgba[3]).assertEqual(0);
      // w=255：纯主体色，alpha=200
      expect(rgba[4]).assertEqual(178);
      expect(rgba[5]).assertEqual(59);
      expect(rgba[6]).assertEqual(47);
      expect(rgba[7]).assertEqual(200);
      // w=128：约一半混合，约一半透明度
      const halfR = Math.round((178 * 128 + 44 * 127) / 255);
      expect(rgba[8]).assertEqual(halfR);
      const halfA = Math.round((200 * 128) / 255);
      expect(rgba[11]).assertEqual(halfA);
    });
  });
}
