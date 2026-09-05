import { describe, it, expect } from '@ohos/hypium';
import {
  BORDER_SHADOW_MAX,
  BORDER_SHADOW_MIN,
  BORDER_WIDTH_RATIO_MAX,
  BORDER_WIDTH_RATIO_MIN,
  BorderState,
  EDITOR_SNAPSHOT_SCHEMA_VERSION,
  EditorSnapshot,
  FILTER_STRENGTH_MAX,
  FILTER_STRENGTH_MIN,
  FilterSnapshot,
  TEXT_COORD_MAX,
  TEXT_COORD_MIN,
  TEXT_FONT_SIZE_RATIO_MAX,
  TEXT_FONT_SIZE_RATIO_MIN,
  TEXT_LAYER_MAX_CHARS,
  TEXT_LAYER_MAX_COUNT,
  TEXT_LAYER_MAX_LINES,
  TEXT_OPACITY_MAX,
  TEXT_OPACITY_MIN,
  TEXT_ROTATION_MAX,
  TEXT_ROTATION_MIN,
  TextLayer,
  clampBorderShadow,
  clampBorderWidthRatio,
  clampFilterStrength,
  clampFontSizeRatio,
  clampNormalizedCoord,
  clampTextOpacity,
  clampTextRotation,
  cloneBorderState,
  cloneEditorSnapshot,
  cloneFilterSnapshot,
  cloneTextLayer,
  cloneTextLayers,
  defaultBorderState,
  defaultEditorSnapshot,
  defaultFilterSnapshot,
  sanitizeTextContent
} from '../main/ets/models/SharedContracts';

export default function sharedContractsTest() {
  describe('sharedContractsTest', () => {

    // ───────────────── FilterSnapshot ─────────────────

    it('clamps filter strength within 0..1', 0, () => {
      expect(clampFilterStrength(-0.5)).assertEqual(FILTER_STRENGTH_MIN);
      expect(clampFilterStrength(0)).assertEqual(FILTER_STRENGTH_MIN);
      expect(clampFilterStrength(0.5)).assertEqual(0.5);
      expect(clampFilterStrength(1)).assertEqual(FILTER_STRENGTH_MAX);
      expect(clampFilterStrength(1.5)).assertEqual(FILTER_STRENGTH_MAX);
    });

    it('treats NaN filter strength as 0', 0, () => {
      expect(clampFilterStrength(Number.NaN)).assertEqual(0);
    });

    it('provides a safe default filter snapshot', 0, () => {
      const d = defaultFilterSnapshot();
      expect(d.filterId).assertEqual('original');
      expect(d.strength).assertEqual(0);
    });

    it('returns an independent copy from defaultFilterSnapshot', 0, () => {
      const a = defaultFilterSnapshot();
      const b = defaultFilterSnapshot();
      expect(a === b).assertEqual(false);
    });

    it('clones a filter snapshot deeply', 0, () => {
      const src: FilterSnapshot = { filterId: 'jade_mist', strength: 0.68 };
      const copy = cloneFilterSnapshot(src);
      expect(copy.filterId).assertEqual('jade_mist');
      expect(copy.strength).assertEqual(0.68);
      expect(copy === src).assertEqual(false);
    });

    // ───────────────── TextLayer ─────────────────

    it('exposes text layer limits as named constants', 0, () => {
      expect(TEXT_LAYER_MAX_COUNT).assertEqual(8);
      expect(TEXT_LAYER_MAX_CHARS).assertEqual(80);
      expect(TEXT_LAYER_MAX_LINES).assertEqual(3);
    });

    it('clamps font size ratio to 0.02..0.20', 0, () => {
      expect(clampFontSizeRatio(-1)).assertEqual(TEXT_FONT_SIZE_RATIO_MIN);
      expect(clampFontSizeRatio(0)).assertEqual(TEXT_FONT_SIZE_RATIO_MIN);
      expect(clampFontSizeRatio(0.05)).assertEqual(0.05);
      expect(clampFontSizeRatio(0.2)).assertEqual(TEXT_FONT_SIZE_RATIO_MAX);
      expect(clampFontSizeRatio(0.5)).assertEqual(TEXT_FONT_SIZE_RATIO_MAX);
    });

    it('treats NaN font size ratio as minimum', 0, () => {
      expect(clampFontSizeRatio(Number.NaN)).assertEqual(TEXT_FONT_SIZE_RATIO_MIN);
    });

    it('clamps rotation to -180..180', 0, () => {
      expect(clampTextRotation(-270)).assertEqual(TEXT_ROTATION_MIN);
      expect(clampTextRotation(-90)).assertEqual(-90);
      expect(clampTextRotation(0)).assertEqual(0);
      expect(clampTextRotation(90)).assertEqual(90);
      expect(clampTextRotation(270)).assertEqual(TEXT_ROTATION_MAX);
    });

    it('treats NaN rotation as 0', 0, () => {
      expect(clampTextRotation(Number.NaN)).assertEqual(0);
    });

    it('clamps text opacity to 0.30..1.00', 0, () => {
      expect(clampTextOpacity(0)).assertEqual(TEXT_OPACITY_MIN);
      expect(clampTextOpacity(0.5)).assertEqual(0.5);
      expect(clampTextOpacity(1)).assertEqual(TEXT_OPACITY_MAX);
      expect(clampTextOpacity(1.5)).assertEqual(TEXT_OPACITY_MAX);
    });

    it('treats NaN text opacity as maximum', 0, () => {
      expect(clampTextOpacity(Number.NaN)).assertEqual(TEXT_OPACITY_MAX);
    });

    it('clamps normalized coordinates to 0..1', 0, () => {
      expect(clampNormalizedCoord(-0.2)).assertEqual(TEXT_COORD_MIN);
      expect(clampNormalizedCoord(0.5)).assertEqual(0.5);
      expect(clampNormalizedCoord(1.5)).assertEqual(TEXT_COORD_MAX);
    });

    it('treats NaN coordinate as 0.5 (center)', 0, () => {
      expect(clampNormalizedCoord(Number.NaN)).assertEqual(0.5);
    });

    it('sanitizes empty content to empty string', 0, () => {
      expect(sanitizeTextContent('')).assertEqual('');
    });

    it('keeps short content intact', 0, () => {
      expect(sanitizeTextContent('题签')).assertEqual('题签');
    });

    it('truncates content over 80 characters', 0, () => {
      const long = '字'.repeat(100);
      const out = sanitizeTextContent(long);
      expect(out.length).assertEqual(TEXT_LAYER_MAX_CHARS);
    });

    it('clones a text layer deeply without sharing references', 0, () => {
      const src: TextLayer = {
        id: 't1',
        content: '题签',
        fontKey: 'gkai',
        colorArgb: 0xFF000000,
        fontSizeRatio: 0.08,
        centerX: 0.5,
        centerY: 0.5,
        rotationDeg: 0,
        opacity: 1.0
      };
      const copy = cloneTextLayer(src);
      expect(copy === src).assertEqual(false);
      expect(copy.id).assertEqual('t1');
      expect(copy.content).assertEqual('题签');
      expect(copy.fontKey).assertEqual('gkai');
      expect(copy.fontSizeRatio).assertEqual(0.08);
    });

    it('clones a text layer array without sharing elements', 0, () => {
      const a: TextLayer = {
        id: 't1', content: '甲', fontKey: 'gkai', colorArgb: 0xFF000000,
        fontSizeRatio: 0.05, centerX: 0.3, centerY: 0.3, rotationDeg: 0, opacity: 1.0
      };
      const b: TextLayer = {
        id: 't2', content: '乙', fontKey: 'system_sans', colorArgb: 0xFFFFFFFF,
        fontSizeRatio: 0.1, centerX: 0.7, centerY: 0.7, rotationDeg: 45, opacity: 0.8
      };
      const src: TextLayer[] = [a, b];
      const copy = cloneTextLayers(src);
      expect(copy.length).assertEqual(2);
      expect(copy === src).assertEqual(false);
      expect(copy[0] === src[0]).assertEqual(false);
      expect(copy[1] === src[1]).assertEqual(false);
      expect(copy[0].id).assertEqual('t1');
      expect(copy[1].id).assertEqual('t2');
    });

    it('returns an independent empty array when cloning empty input', 0, () => {
      const copy = cloneTextLayers([]);
      expect(copy.length).assertEqual(0);
    });

    // ───────────────── BorderState ─────────────────

    it('clamps border width ratio to 0..0.25', 0, () => {
      expect(clampBorderWidthRatio(-0.1)).assertEqual(BORDER_WIDTH_RATIO_MIN);
      expect(clampBorderWidthRatio(0)).assertEqual(BORDER_WIDTH_RATIO_MIN);
      expect(clampBorderWidthRatio(0.1)).assertEqual(0.1);
      expect(clampBorderWidthRatio(0.25)).assertEqual(BORDER_WIDTH_RATIO_MAX);
      expect(clampBorderWidthRatio(0.5)).assertEqual(BORDER_WIDTH_RATIO_MAX);
    });

    it('treats NaN border width as 0', 0, () => {
      expect(clampBorderWidthRatio(Number.NaN)).assertEqual(0);
    });

    it('clamps border shadow to 0..1', 0, () => {
      expect(clampBorderShadow(-0.5)).assertEqual(BORDER_SHADOW_MIN);
      expect(clampBorderShadow(0.5)).assertEqual(0.5);
      expect(clampBorderShadow(1)).assertEqual(BORDER_SHADOW_MAX);
      expect(clampBorderShadow(1.5)).assertEqual(BORDER_SHADOW_MAX);
    });

    it('treats NaN border shadow as 0', 0, () => {
      expect(clampBorderShadow(Number.NaN)).assertEqual(0);
    });

    it('provides a safe default border state (none)', 0, () => {
      const d = defaultBorderState();
      expect(d.templateId).assertEqual('none');
      expect(d.widthRatio).assertEqual(0);
      expect(d.shadowStrength).assertEqual(0);
    });

    it('returns an independent object from defaultBorderState', 0, () => {
      const a = defaultBorderState();
      const b = defaultBorderState();
      expect(a === b).assertEqual(false);
    });

    it('clones a border state deeply', 0, () => {
      const src: BorderState = {
        templateId: 'polaroid',
        widthRatio: 0.1,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0.4
      };
      const copy = cloneBorderState(src);
      expect(copy === src).assertEqual(false);
      expect(copy.templateId).assertEqual('polaroid');
      expect(copy.widthRatio).assertEqual(0.1);
      expect(copy.shadowStrength).assertEqual(0.4);
    });

    // ───────────────── EditorSnapshot ─────────────────

    it('fixes schemaVersion at 1 for 0.1.9', 0, () => {
      expect(EDITOR_SNAPSHOT_SCHEMA_VERSION).assertEqual(1);
    });

    it('provides a safe default editor snapshot', 0, () => {
      const d = defaultEditorSnapshot();
      expect(d.schemaVersion).assertEqual(EDITOR_SNAPSHOT_SCHEMA_VERSION);
      expect(d.filter.filterId).assertEqual('original');
      expect(d.filter.strength).assertEqual(0);
      expect(d.textLayers.length).assertEqual(0);
      expect(d.border.templateId).assertEqual('none');
    });

    it('returns independent defaults on each call', 0, () => {
      const a = defaultEditorSnapshot();
      const b = defaultEditorSnapshot();
      expect(a === b).assertEqual(false);
      expect(a.filter === b.filter).assertEqual(false);
      expect(a.textLayers === b.textLayers).assertEqual(false);
      expect(a.border === b.border).assertEqual(false);
    });

    it('clones an editor snapshot deeply (all layers independent)', 0, () => {
      const src: EditorSnapshot = {
        schemaVersion: 1,
        filter: { filterId: 'jade_mist', strength: 0.68 },
        textLayers: [{
          id: 't1', content: '题签', fontKey: 'gkai', colorArgb: 0xFF000000,
          fontSizeRatio: 0.08, centerX: 0.5, centerY: 0.5, rotationDeg: 0, opacity: 1.0
        }],
        border: { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0xFFFFFFFF, shadowStrength: 0.4 }
      };
      const copy = cloneEditorSnapshot(src);
      expect(copy === src).assertEqual(false);
      expect(copy.filter === src.filter).assertEqual(false);
      expect(copy.textLayers === src.textLayers).assertEqual(false);
      expect(copy.textLayers[0] === src.textLayers[0]).assertEqual(false);
      expect(copy.border === src.border).assertEqual(false);
      expect(copy.filter.filterId).assertEqual('jade_mist');
      expect(copy.textLayers[0].id).assertEqual('t1');
      expect(copy.border.templateId).assertEqual('polaroid');
    });

    it('preserves field values after deep clone when source is mutated', 0, () => {
      const src: EditorSnapshot = defaultEditorSnapshot();
      const copy = cloneEditorSnapshot(src);
      // 修改源对象不应影响副本
      src.filter.filterId = 'ink_noir';
      src.filter.strength = 0.9;
      src.border.templateId = 'scroll_mount';
      expect(copy.filter.filterId).assertEqual('original');
      expect(copy.filter.strength).assertEqual(0);
      expect(copy.border.templateId).assertEqual('none');
    });
  });
}
