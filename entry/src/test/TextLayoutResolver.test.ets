import { describe, it, expect } from '@ohos/hypium';
import { TextLayer } from '../main/ets/models/SharedContracts';
import { createDefaultTextLayer } from '../main/ets/features/editor/text/TextLayerState';
import {
  ContentRect,
  clampTextCenterToContent,
  normalizeToPixel,
  pixelToNormalized,
  resolveTextLayout
} from '../main/ets/features/editor/text/TextLayoutResolver';

function rect(x: number, y: number, width: number, height: number): ContentRect {
  return { x, y, width, height };
}

function sample(): TextLayer {
  const value = createDefaultTextLayer('t1', '题签');
  value.centerX = 0.25;
  value.centerY = 0.75;
  value.fontSizeRatio = 0.08;
  value.rotationDeg = 37;
  return value;
}

export default function textLayoutResolverTest() {
  describe('textLayoutResolverTest', () => {
    it('does not squeeze CJK characters into half-width boxes', 0, () => {
      const layout = resolveTextLayout(rect(0, 0, 1000, 500), createDefaultTextLayer('a', '题签'));
      expect(layout.widthPx >= 120).assertTrue();
    });

    it('uses measured text bounds for rotated drag clamping without moving the saved center', 0, () => {
      const layer = createDefaultTextLayer('a', '题签');
      layer.rotationDeg = 90;
      const content = rect(10, 20, 400, 300);
      const layout = resolveTextLayout(content, layer, { width: 30, height: 40 });
      expect(layout.widthPx).assertEqual(30);
      expect(layout.heightPx).assertEqual(40);
      const clamped = clampTextCenterToContent(content, layout, -999, 999);
      expect(Math.round(clamped.x)).assertEqual(30);
      expect(Math.round(clamped.y)).assertEqual(305);
      expect(layer.centerX).assertEqual(0.5);
      expect(layer.centerY).assertEqual(0.5);
    });

    it('scales portrait and long-photo layouts with the photo long edge', 0, () => {
      const layer = sample();
      const portrait = resolveTextLayout(rect(0, 0, 300, 400), layer);
      const longPhoto = resolveTextLayout(rect(0, 0, 100, 800), layer);
      const output = resolveTextLayout(rect(0, 0, 500, 4000), layer);
      expect(portrait.centerPixelX).assertEqual(75);
      expect(portrait.centerPixelY).assertEqual(300);
      expect(portrait.fontSizePx).assertEqual(32);
      expect(longPhoto.centerPixelX).assertEqual(25);
      expect(longPhoto.centerPixelY).assertEqual(600);
      expect(longPhoto.fontSizePx).assertEqual(64);
      expect(output.centerPixelX).assertEqual(125);
      expect(output.centerPixelY).assertEqual(3000);
      expect(output.fontSizePx).assertEqual(320);
    });

    it('centers an oversized box and handles a zero-sized container', 0, () => {
      const layout = resolveTextLayout(rect(0, 0, 100, 80), sample(), { width: 900, height: 900 });
      const center = clampTextCenterToContent(rect(0, 0, 100, 80), layout, -900, 900);
      expect(center.x).assertEqual(50);
      expect(center.y).assertEqual(40);
      expect(pixelToNormalized(rect(0, 0, 0, 0), 5, 5).x).assertEqual(0.5);
    });
    it('preserves normalized proportions across output sizes', 0, () => {
      const layer = sample();
      const small = resolveTextLayout(rect(10, 20, 400, 300), layer);
      const large = resolveTextLayout(rect(30, 60, 1200, 900), layer);
      expect(large.centerPixelX / 3).assertEqual(small.centerPixelX);
      expect(large.centerPixelY / 3).assertEqual(small.centerPixelY);
      expect(large.fontSizePx / 3).assertEqual(small.fontSizePx);
      expect(large.rotationDeg).assertEqual(37);
    });

    it('converts pixel and normalized centers in both directions', 0, () => {
      const content = rect(100, 50, 800, 400);
      const px = normalizeToPixel(content, 0.25, 0.75);
      expect(px.x).assertEqual(300);
      expect(px.y).assertEqual(350);
      const normalized = pixelToNormalized(content, px.x, px.y);
      expect(normalized.x).assertEqual(0.25);
      expect(normalized.y).assertEqual(0.75);
    });

    it('clamps a dragged center to keep its text box inside content', 0, () => {
      const content = rect(0, 0, 400, 300);
      const layout = resolveTextLayout(content, sample());
      const clamped = clampTextCenterToContent(content, layout, -100, 500);
      expect(clamped.x >= layout.widthPx / 2).assertTrue();
      expect(clamped.y >= layout.heightPx / 2).assertTrue();
      expect(clamped.x <= 400 - layout.widthPx / 2).assertTrue();
      expect(clamped.y <= 300 - layout.heightPx / 2).assertTrue();
    });

    it('keeps the saved center independent from rotation', 0, () => {
      const content = rect(0, 0, 600, 600);
      const a = sample();
      const b = sample();
      b.rotationDeg = -120;
      const first = resolveTextLayout(content, a);
      const second = resolveTextLayout(content, b);
      expect(first.centerPixelX).assertEqual(second.centerPixelX);
      expect(first.centerPixelY).assertEqual(second.centerPixelY);
    });

    it('does not mutate the input layer or content rectangle', 0, () => {
      const content = rect(4, 8, 300, 200);
      const layer = sample();
      const beforeX = layer.centerX;
      const result = resolveTextLayout(content, layer);
      result.centerPixelX = 999;
      expect(layer.centerX).assertEqual(beforeX);
      expect(content.width).assertEqual(300);
    });
  });
}
