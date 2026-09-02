import { describe, it, expect } from '@ohos/hypium';
import { TextCompositionService, TextLayoutMetrics } from '../main/ets/services/TextCompositionService';
import { BorderCompositionService, BorderGeometry } from '../main/ets/services/BorderCompositionService';
import { TextLayer, BorderState } from '../main/ets/models/SharedContracts';

export default function editorCompositionModelsTest() {
  describe('EditorCompositionModels', () => {

    // ── 文字图层布局解算测试 ──
    describe('TextLayoutMetrics', () => {
      it('calculates font size relative to long edge (landscape)', 0, () => {
        const layers: TextLayer[] = [{
          id: 't1',
          content: '横图题签',
          fontKey: 'noto_serif_sc',
          colorArgb: 0xFF241918,
          fontSizeRatio: 0.10, // 10% of 2000 = 200px
          centerX: 0.5,
          centerY: 0.5,
          rotationDeg: 0,
          opacity: 1.0
        }];

        const metrics = TextCompositionService.resolveLayoutMetrics(layers, 2000, 1000);
        expect(metrics.length).assertEqual(1);
        expect(metrics[0].fontSizePx).assertEqual(200);
        expect(metrics[0].centerPixelX).assertEqual(1000);
        expect(metrics[0].centerPixelY).assertEqual(500);
      });

      it('calculates font size relative to long edge (portrait)', 0, () => {
        const layers: TextLayer[] = [{
          id: 't2',
          content: '竖图题签',
          fontKey: 'gkai',
          colorArgb: 0xFFB23B2F,
          fontSizeRatio: 0.05, // 5% of 3000 = 150px
          centerX: 0.8,
          centerY: 0.2,
          rotationDeg: 45,
          opacity: 0.8
        }];

        const metrics = TextCompositionService.resolveLayoutMetrics(layers, 1500, 3000);
        expect(metrics.length).assertEqual(1);
        expect(metrics[0].fontSizePx).assertEqual(150);
        expect(metrics[0].centerPixelX).assertEqual(1200);
        expect(metrics[0].centerPixelY).assertEqual(600);
        expect(metrics[0].rotationDeg).assertEqual(45);
        expect(metrics[0].opacity).assertEqual(0.8);
      });

      it('clamps font size ratio to [0.02, 0.20]', 0, () => {
        const layers: TextLayer[] = [
          {
            id: 't-min',
            content: '最小',
            fontKey: 'system_sans',
            colorArgb: 0,
            fontSizeRatio: 0.001, // 应钳制到 0.02
            centerX: 0.5,
            centerY: 0.5,
            rotationDeg: 0,
            opacity: 1.0
          },
          {
            id: 't-max',
            content: '最大',
            fontKey: 'system_sans',
            colorArgb: 0,
            fontSizeRatio: 0.80,  // 应钳制到 0.20
            centerX: 0.5,
            centerY: 0.5,
            rotationDeg: 0,
            opacity: 1.0
          }
        ];

        const metrics = TextCompositionService.resolveLayoutMetrics(layers, 1000, 1000);
        expect(metrics[0].fontSizePx).assertEqual(20);  // 1000 * 0.02
        expect(metrics[1].fontSizePx).assertEqual(200); // 1000 * 0.20
      });
    });

    // ── 边框几何解算测试 ──
    describe('BorderGeometry', () => {
      it('returns identity dimensions for none template', 0, () => {
        const border: BorderState = {
          templateId: 'none',
          widthRatio: 0.1,
          colorArgb: 0xFFFFFFFF,
          shadowStrength: 0
        };

        const geom = BorderCompositionService.resolveGeometry(border, 1200, 800);
        expect(geom.outputWidth).assertEqual(1200);
        expect(geom.outputHeight).assertEqual(800);
        expect(geom.photoOffsetX).assertEqual(0);
        expect(geom.photoOffsetY).assertEqual(0);
      });

      it('calculates 4-side equal margins for paper_white', 0, () => {
        const border: BorderState = {
          templateId: 'paper_white',
          widthRatio: 0.10, // 10% of short edge 800 = 80px
          colorArgb: 0xFFF2F1ED,
          shadowStrength: 0
        };

        const geom = BorderCompositionService.resolveGeometry(border, 1200, 800);
        expect(geom.margins.top).assertEqual(80);
        expect(geom.margins.bottom).assertEqual(80);
        expect(geom.margins.left).assertEqual(80);
        expect(geom.margins.right).assertEqual(80);
        expect(geom.outputWidth).assertEqual(1360); // 1200 + 80 + 80
        expect(geom.outputHeight).assertEqual(960);  // 800 + 80 + 80
        expect(geom.photoOffsetX).assertEqual(80);
        expect(geom.photoOffsetY).assertEqual(80);
      });

      it('calculates asymmetric bottom margin for polaroid', 0, () => {
        const border: BorderState = {
          templateId: 'polaroid',
          widthRatio: 0.10, // 10% of 1000 = 100px base
          colorArgb: 0xFFFFFFFF,
          shadowStrength: 0.2
        };

        const geom = BorderCompositionService.resolveGeometry(border, 1000, 1500);
        expect(geom.margins.top).assertEqual(100);
        expect(geom.margins.left).assertEqual(100);
        expect(geom.margins.right).assertEqual(100);
        expect(geom.margins.bottom).assertEqual(250); // 100 * 2.5
        expect(geom.outputWidth).assertEqual(1200);   // 1000 + 100 + 100
        expect(geom.outputHeight).assertEqual(1850);  // 1500 + 100 + 250
        expect(geom.photoOffsetX).assertEqual(100);
        expect(geom.photoOffsetY).assertEqual(100);
      });

      it('clamps widthRatio to max 0.25', 0, () => {
        const border: BorderState = {
          templateId: 'ink_black',
          widthRatio: 0.50, // 超出 0.25 上限，钳制到 0.25 (200px of 800)
          colorArgb: 0xFF241918,
          shadowStrength: 0
        };

        const geom = BorderCompositionService.resolveGeometry(border, 1000, 800);
        expect(geom.margins.top).assertEqual(200); // 800 * 0.25
        expect(geom.outputWidth).assertEqual(1400); // 1000 + 200 + 200
        expect(geom.outputHeight).assertEqual(1200); // 800 + 200 + 200
      });
    });
  });
}
