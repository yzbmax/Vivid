import { describe, it, expect } from '@ohos/hypium';
import { defaultBorderState } from '../main/ets/models/SharedContracts';
import { switchBorderTemplate } from '../main/ets/features/editor/border/BorderState';
import { resolveEditorPreviewLayout } from '../main/ets/features/editor/preview/EditorPreviewLayout';

export default function editorPreviewLayoutTest() {
  describe('editorPreviewLayoutTest', () => {
    it('fits 16:9 within both bounds without changing its aspect ratio', 0, () => {
      const layout = resolveEditorPreviewLayout(320, 400, 1600, 900, defaultBorderState());
      expect(layout.outputRect.x).assertEqual(0);
      expect(layout.outputRect.y).assertEqual(110);
      expect(layout.photoRect.width).assertEqual(320);
      expect(layout.photoRect.height).assertEqual(180);
    });
    it('fits 5:4 and a tall photo inside a height-constrained panel', 0, () => {
      const wide = resolveEditorPreviewLayout(320, 200, 1000, 800, defaultBorderState());
      expect(wide.photoRect.width).assertEqual(250);
      expect(wide.photoRect.height).assertEqual(200);
      expect(wide.outputRect.x).assertEqual(35);
      const tall = resolveEditorPreviewLayout(320, 200, 400, 1600, defaultBorderState());
      expect(tall.photoRect.width).assertEqual(50);
      expect(tall.photoRect.height).assertEqual(200);
      expect(tall.outputRect.x).assertEqual(135);
    });
    it('fits the expanded border canvas and locates text inside the inset photo', 0, () => {
      const layout = resolveEditorPreviewLayout(600, 650, 1000, 1000,
        { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 });
      // Shared resolver: 50/50/50/250 insets => 1100 x 1300, scale .5.
      expect(layout.outputRect.x).assertEqual(25);
      expect(layout.outputRect.width).assertEqual(550);
      expect(layout.outputRect.height).assertEqual(650);
      expect(layout.photoRect.x).assertEqual(50);
      expect(layout.photoRect.y).assertEqual(25);
      expect(layout.photoRect.width).assertEqual(500);
      expect(layout.photoRect.height).assertEqual(500);
    });
    it('keeps an undecoded photo mountable and avoids NaN for an unmeasured container', 0, () => {
      const unknown = resolveEditorPreviewLayout(320, 200, 0, 0, defaultBorderState());
      expect(unknown.photoRect.width).assertEqual(320);
      expect(unknown.photoRect.height).assertEqual(200);
      const hidden = resolveEditorPreviewLayout(0, 0, 1000, 800, defaultBorderState());
      expect(hidden.photoRect.width).assertEqual(0);
      expect(hidden.outputRect.height).assertEqual(0);
    });
    it('selecting a border from none produces a visible width and template-appropriate color', 0, () => {
      const border = switchBorderTemplate(defaultBorderState(), 'ink_black');
      expect(border.widthRatio > 0).assertTrue();
      expect(border.colorArgb).assertEqual(0xFF1A1A1A);
      const layout = resolveEditorPreviewLayout(320, 400, 1000, 800, border);
      expect(layout.photoRect.width < layout.outputRect.width).assertTrue();
      const floating = switchBorderTemplate(defaultBorderState(), 'floating_shadow');
      expect(floating.shadowStrength > 0).assertTrue();
    });
  });
}
