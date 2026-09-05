import { describe, it, expect } from '@ohos/hypium';
import { TextLayer } from '../main/ets/models/SharedContracts';
import {
  addTextLayer,
  createDefaultTextLayer,
  deleteTextLayer,
  selectTextLayer,
  updateTextLayer,
  applyTextInput,
  validateTextContent
} from '../main/ets/features/editor/text/TextLayerState';
import {
  FONT_CATALOG,
  TEXT_COLOR_PALETTE,
  fontFallbackChain,
  resolveFontKey
} from '../main/ets/features/editor/text/FontCatalog';

function layer(id: string, content: string): TextLayer {
  return createDefaultTextLayer(id, content);
}

export default function textLayerStateTest() {
  describe('textLayerStateTest', () => {
    it('previews typing immediately and saving the same input does not add a duplicate', 0, () => {
      const first = applyTextInput([], '', '题', 'new');
      expect(first.layers[0].content).assertEqual('题');
      const typed = applyTextInput(first.layers, 'new', '题签', 'unused');
      expect(typed.layers[0].content).assertEqual('题签');
      const saved = applyTextInput(typed.layers, 'new', '题签', 'unused');
      expect(saved.layers.length).assertEqual(1);
      expect(saved.selectedId).assertEqual('new');
      expect(first.layers[0].content).assertEqual('题');
    });

    it('keeps the last valid live text when a replacement is invalid', 0, () => {
      const source: TextLayer[] = [layer('a', '原文')];
      const invalid = applyTextInput(source, 'a', '字'.repeat(81), 'unused');
      expect(invalid.error.length > 0).assertTrue();
      expect(invalid.layers[0].content).assertEqual('原文');
      expect(invalid.selectedId).assertEqual('a');
    });
    it('rejects blank content, 81 characters and four lines', 0, () => {
      expect(validateTextContent('   ').valid).assertFalse();
      expect(validateTextContent('字'.repeat(81)).valid).assertFalse();
      expect(validateTextContent('一\n二\n三\n四').valid).assertFalse();
    });

    it('counts Unicode code points without truncating valid emoji content', 0, () => {
      const content = '😀'.repeat(80);
      expect(addTextLayer([], content, 'emoji').layers[0].content).assertEqual(content);
      expect(validateTextContent('😀'.repeat(81)).valid).assertFalse();
      expect(validateTextContent('甲\n乙\n丙').valid).assertTrue();
    });

    it('rejects a fourth line with pasted CR or CRLF line endings', 0, () => {
      expect(validateTextContent('甲\r乙\r丙\r丁').valid).assertFalse();
      expect(validateTextContent('甲\r\n乙\r\n丙\r\n丁').valid).assertFalse();
    });

    it('uses the next available font after registration failures', 0, () => {
      expect(resolveFontKey('gkai', ['gkai'])).assertEqual('noto_serif_sc');
      expect(resolveFontKey('gkai', ['gkai', 'noto_serif_sc'])).assertEqual('system_sans');
      expect(resolveFontKey('noto_serif_latin', ['noto_serif_latin'])).assertEqual('noto_serif_sc');
    });

    it('copies every layer and preserves array stacking order on update', 0, () => {
      const source: TextLayer[] = [layer('a', '甲'), layer('b', '乙')];
      const result = updateTextLayer(source, 'a', { fontKey: 'unknown', colorArgb: 0, fontSizeRatio: -1,
        rotationDeg: -999, opacity: 2 });
      expect(result.layers[0].id).assertEqual('a');
      expect(result.layers[1].id).assertEqual('b');
      expect(result.layers[0].fontKey).assertEqual('system_sans');
      expect(result.layers[0].colorArgb).assertEqual(0xFF241918);
      expect(result.layers[0].fontSizeRatio).assertEqual(0.02);
      expect(result.layers[0].rotationDeg).assertEqual(-180);
      expect(result.layers[0].opacity).assertEqual(1);
      result.layers[1].content = '修改副本';
      expect(source[1].content).assertEqual('乙');
      expect(deleteTextLayer(source, 'a', 'b').selectedId).assertEqual('b');
    });

    it('creates a centered layer with the agreed defaults', 0, () => {
      const created = createDefaultTextLayer('t1', '题签');
      expect(created.id).assertEqual('t1');
      expect(created.fontKey).assertEqual('system_sans');
      expect(created.colorArgb).assertEqual(0xFF241918);
      expect(created.fontSizeRatio).assertEqual(0.06);
      expect(created.centerX).assertEqual(0.5);
      expect(created.centerY).assertEqual(0.5);
      expect(created.rotationDeg).assertEqual(0);
      expect(created.opacity).assertEqual(1);
    });

    it('uses the fixed font fallback chain and eight-color palette', 0, () => {
      expect(FONT_CATALOG.length).assertEqual(5);
      expect(TEXT_COLOR_PALETTE.length).assertEqual(8);
      expect(resolveFontKey('missing-font')).assertEqual('system_sans');
      expect(fontFallbackChain('gkai')[0]).assertEqual('gkai');
      expect(fontFallbackChain('gkai')[2]).assertEqual('system_sans');
    });

    it('adds valid layers and rejects duplicate ids and the ninth layer', 0, () => {
      let layers: TextLayer[] = [];
      const first = addTextLayer(layers, '甲', 'same');
      expect(first.error).assertEqual('');
      layers = first.layers;
      const duplicate = addTextLayer(layers, '乙', 'same');
      expect(duplicate.error.length > 0).assertTrue();
      expect(duplicate.layers.length).assertEqual(1);
      for (let i = 1; i < 8; i++) {
        layers = addTextLayer(layers, '字', 't' + i).layers;
      }
      const ninth = addTextLayer(layers, '超限', 't8');
      expect(ninth.error.length > 0).assertTrue();
      expect(ninth.layers.length).assertEqual(8);
    });

    it('updates with validation and clamps numeric parameters without mutating input', 0, () => {
      const source: TextLayer[] = [layer('t1', '原文')];
      const result = updateTextLayer(source, 't1', {
        content: '新文',
        fontSizeRatio: 2,
        centerX: -1,
        centerY: 3,
        rotationDeg: 999,
        opacity: 0
      });
      expect(result.error).assertEqual('');
      expect(result.layers[0].content).assertEqual('新文');
      expect(result.layers[0].fontSizeRatio).assertEqual(0.2);
      expect(result.layers[0].centerX).assertEqual(0);
      expect(result.layers[0].centerY).assertEqual(1);
      expect(result.layers[0].rotationDeg).assertEqual(180);
      expect(result.layers[0].opacity).assertEqual(0.3);
      expect(source[0].content).assertEqual('原文');
    });

    it('does not apply invalid content updates', 0, () => {
      const source: TextLayer[] = [layer('t1', '保留')];
      const result = updateTextLayer(source, 't1', { content: '  ' });
      expect(result.error.length > 0).assertTrue();
      expect(result.layers[0].content).assertEqual('保留');
    });

    it('selects and deletes with next-then-previous fallback', 0, () => {
      const source: TextLayer[] = [layer('a', '甲'), layer('b', '乙'), layer('c', '丙')];
      expect(selectTextLayer(source, 'b')).assertEqual('b');
      const afterMiddle = deleteTextLayer(source, 'b', 'b');
      expect(afterMiddle.layers.length).assertEqual(2);
      expect(afterMiddle.selectedId).assertEqual('c');
      const afterLast = deleteTextLayer(afterMiddle.layers, 'c', 'c');
      expect(afterLast.selectedId).assertEqual('a');
      const afterAll = deleteTextLayer([layer('only', '独')], 'only', 'only');
      expect(afterAll.selectedId).assertEqual(null);
      expect(source.length).assertEqual(3);
    });
  });
}
