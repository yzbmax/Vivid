import { describe, it, expect } from '@ohos/hypium';
import {
  BORDER_TEMPLATES,
  findBorderTemplate,
  isBorderTemplateRegistered,
  templateSupportsCapability
} from '../main/ets/features/editor/border/BorderCatalog';
import {
  BORDER_FALLBACK_TEMPLATE_ID,
  borderStateEquals,
  defaultColorForTemplate,
  migrateBorderState,
  normalizeBorderTemplateId,
  sanitizeBorderState,
  switchBorderTemplate
} from '../main/ets/features/editor/border/BorderState';
import {
  BorderState,
  defaultBorderState
} from '../main/ets/models/SharedContracts';
import {
  resolveBorderGeometry,
  computeBaseBorderWidth
} from '../main/ets/features/editor/border/BorderLayoutResolver';

export default function borderStateTest() {
  describe('borderStateTest', () => {

    // ───────────────── 目录（Catalog）测试 ─────────────────

    it('registers 7 templates (none + 6 real) with unique ids', 0, () => {
      expect(BORDER_TEMPLATES.length).assertEqual(7);
      expect(BORDER_TEMPLATES[0].templateId).assertEqual('none');
      const ids: string[] = [];
      for (const tpl of BORDER_TEMPLATES) {
        const dup = ids.find((i) => i === tpl.templateId);
        expect(dup === undefined).assertTrue();
        ids.push(tpl.templateId);
      }
      expect(ids.indexOf('paper_white') >= 0).assertTrue();
      expect(ids.indexOf('ink_black') >= 0).assertTrue();
      expect(ids.indexOf('floating_shadow') >= 0).assertTrue();
      expect(ids.indexOf('film_negative') >= 0).assertTrue();
      expect(ids.indexOf('polaroid') >= 0).assertTrue();
      expect(ids.indexOf('scroll_mount') >= 0).assertTrue();
    });

    it('declares complete capabilities per template', 0, () => {
      expect(templateSupportsCapability('none', 'width')).assertFalse();
      expect(templateSupportsCapability('none', 'color')).assertFalse();
      expect(templateSupportsCapability('none', 'shadow')).assertFalse();
      expect(templateSupportsCapability('paper_white', 'width')).assertTrue();
      expect(templateSupportsCapability('paper_white', 'color')).assertTrue();
      expect(templateSupportsCapability('paper_white', 'shadow')).assertFalse();
      expect(templateSupportsCapability('floating_shadow', 'shadow')).assertTrue();
      expect(templateSupportsCapability('film_negative', 'width')).assertTrue();
      expect(templateSupportsCapability('film_negative', 'color')).assertFalse();
      expect(templateSupportsCapability('polaroid', 'width')).assertTrue();
      expect(templateSupportsCapability('polaroid', 'shadow')).assertFalse();
      expect(templateSupportsCapability('scroll_mount', 'shadow')).assertTrue();
    });

    it('looks up templates by id and returns null for unknown', 0, () => {
      expect(findBorderTemplate('paper_white') !== null).assertTrue();
      expect(findBorderTemplate('paper_white')?.name).assertEqual('宣纸留白');
      expect(findBorderTemplate('no_such_template') === null).assertTrue();
    });

    it('reports registration correctly', 0, () => {
      expect(isBorderTemplateRegistered('polaroid')).assertTrue();
      expect(isBorderTemplateRegistered('xxx')).assertFalse();
    });

    // ───────────────── 状态纯函数（State）测试 ─────────────────

    it('normalizes unknown templateId to none', 0, () => {
      expect(normalizeBorderTemplateId('')).assertEqual(BORDER_FALLBACK_TEMPLATE_ID);
      expect(normalizeBorderTemplateId('no_such')).assertEqual(BORDER_FALLBACK_TEMPLATE_ID);
      expect(normalizeBorderTemplateId('polaroid')).assertEqual('polaroid');
    });

    it('clamps widthRatio / shadow and drops color for templates without color support', 0, () => {
      const raw: BorderState = {
        templateId: 'film_negative',
        widthRatio: 0.5,      // 超过 0.25 上界
        colorArgb: 0xFF0000FF, // 该模板不支持 color，应被替换
        shadowStrength: 2      // 该模板不支持 shadow，强制为 0
      };
      const out = sanitizeBorderState(raw);
      expect(out.templateId).assertEqual('film_negative');
      expect(out.widthRatio).assertEqual(0.25);
      expect(out.colorArgb).assertEqual(defaultColorForTemplate('film_negative'));
      expect(out.shadowStrength).assertEqual(0);
    });

    it('forces `none` template to all-zero state', 0, () => {
      const raw: BorderState = {
        templateId: 'none',
        widthRatio: 0.1,
        colorArgb: 0xFF123456,
        shadowStrength: 0.5
      };
      const out = sanitizeBorderState(raw);
      expect(out.templateId).assertEqual('none');
      expect(out.widthRatio).assertEqual(0);
      expect(out.shadowStrength).assertEqual(0);
    });

    it('falls back unknown templateId to none with zeroed params', 0, () => {
      const raw: BorderState = {
        templateId: 'no_such',
        widthRatio: 0.1,
        colorArgb: 0xFFFFFFFF,
        shadowStrength: 0.5
      };
      const out = sanitizeBorderState(raw);
      expect(out.templateId).assertEqual('none');
      expect(out.widthRatio).assertEqual(0);
    });

    it('switches template and keeps supported params, drops unsupported', 0, () => {
      const paper: BorderState = {
        templateId: 'paper_white',
        widthRatio: 0.1,
        colorArgb: 0xFF00FF00,
        shadowStrength: 0.5 // paper_white 不支持 shadow
      };
      const switched = switchBorderTemplate(paper, 'film_negative');
      expect(switched.templateId).assertEqual('film_negative');
      expect(switched.widthRatio).assertEqual(0.1);
      // film_negative 不支持 color → 默认色
      expect(switched.colorArgb).assertEqual(defaultColorForTemplate('film_negative'));
      // film_negative 不支持 shadow → 0
      expect(switched.shadowStrength).assertEqual(0);
    });

    it('equals() distinguishes different states', 0, () => {
      const a: BorderState = { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0xFFF5F2E8, shadowStrength: 0 };
      const b: BorderState = { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0xFFF5F2E8, shadowStrength: 0 };
      const c: BorderState = { templateId: 'polaroid', widthRatio: 0.2, colorArgb: 0xFFF5F2E8, shadowStrength: 0 };
      expect(borderStateEquals(a, b)).assertTrue();
      expect(borderStateEquals(a, c)).assertFalse();
    });

    it('migrates null into default border state', 0, () => {
      const out = migrateBorderState(null);
      expect(out.templateId).assertEqual('none');
      expect(out.widthRatio).assertEqual(0);
    });

    it('migrates legacy state without mutating the input', 0, () => {
      const input: BorderState = {
        templateId: 'polaroid', widthRatio: 0.1,
        colorArgb: 0xFFF5F2E8, shadowStrength: 0
      };
      const out = migrateBorderState(input);
      input.widthRatio = 0.5;
      expect(out.widthRatio).assertEqual(0.1);
    });

    // ───────────────── 几何（Resolver）测试 ─────────────────

    it('none template does not change canvas size', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'none', widthRatio: 0, colorArgb: 0, shadowStrength: 0 }
      });
      expect(g.outputWidth).assertEqual(1000);
      expect(g.outputHeight).assertEqual(800);
      expect(g.photoRect.x).assertEqual(0);
      expect(g.photoRect.y).assertEqual(0);
      expect(g.photoRect.width).assertEqual(1000);
      expect(g.photoRect.height).assertEqual(800);
      expect(g.decorations.length).assertEqual(0);
    });

    it('symmetric border extends canvas equally on all four sides', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'paper_white', widthRatio: 0.1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 }
      });
      // 短边=800, 0.1 → 边宽=80
      expect(g.insets.top).assertEqual(80);
      expect(g.insets.right).assertEqual(80);
      expect(g.insets.bottom).assertEqual(80);
      expect(g.insets.left).assertEqual(80);
      expect(g.outputWidth).assertEqual(1160);
      expect(g.outputHeight).assertEqual(960);
      expect(g.photoRect.width).assertEqual(1000);
      expect(g.photoRect.height).assertEqual(800);
    });

    it('preserves the full photo across landscape, portrait and long images', 0, () => {
      const landscape = resolveBorderGeometry({
        photoWidth: 1600, photoHeight: 900,
        border: { templateId: 'ink_black', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      expect(landscape.photoRect.width).assertEqual(1600);
      expect(landscape.photoRect.height).assertEqual(900);

      const portrait = resolveBorderGeometry({
        photoWidth: 900, photoHeight: 1600,
        border: { templateId: 'ink_black', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      expect(portrait.photoRect.width).assertEqual(900);
      expect(portrait.photoRect.height).assertEqual(1600);

      const long = resolveBorderGeometry({
        photoWidth: 3000, photoHeight: 600,
        border: { templateId: 'ink_black', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      expect(long.photoRect.width).assertEqual(3000);
      expect(long.photoRect.height).assertEqual(600);
    });

    it('polaroid has asymmetric insets: narrow sides, wide bottom', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      // 短边=800, 0.1 → bw=80, side=40, bottom=200
      expect(g.insets.left).assertEqual(40);
      expect(g.insets.right).assertEqual(40);
      expect(g.insets.top).assertEqual(40);
      expect(g.insets.bottom).assertEqual(200);
      expect(g.insets.bottom > g.insets.top).assertTrue();
      expect(g.photoRect.width).assertEqual(1000);
      expect(g.photoRect.height).assertEqual(800);
    });

    it('film_negative sprockets never intrude into the photo area', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'film_negative', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      expect(g.decorations.length > 0).assertTrue();
      for (const d of g.decorations) {
        if (d.kind === 'sprocket') {
          // 齿孔 x 范围必须在外侧边框内（< left 或 > left+photoWidth）
          const inLeftMargin = d.rect.x + d.rect.width <= g.insets.left;
          const inRightMargin = d.rect.x >= g.insets.left + g.photoRect.width;
          expect(inLeftMargin || inRightMargin).assertTrue();
        }
      }
    });

    it('scroll_mount inner lines lie inside the outer frame', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'scroll_mount', widthRatio: 0.1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 }
      });
      const outerW = g.outputWidth - g.shadowSpread * 2;
      const outerH = g.outputHeight - g.shadowSpread * 2;
      for (const d of g.decorations) {
        if (d.kind === 'innerLine') {
          expect(d.rect.x >= 0).assertTrue();
          expect(d.rect.y >= 0).assertTrue();
          expect(d.rect.x + d.rect.width <= outerW).assertTrue();
          expect(d.rect.y + d.rect.height <= outerH).assertTrue();
        }
        if (d.kind === 'cornerMark') {
          expect(d.rect.x >= 0).assertTrue();
          expect(d.rect.y >= 0).assertTrue();
          expect(d.rect.x + d.rect.width <= outerW).assertTrue();
          expect(d.rect.y + d.rect.height <= outerH).assertTrue();
        }
      }
    });

    it('floating_shadow adds symmetric spread around the border', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'floating_shadow', widthRatio: 0.1, colorArgb: 0xFFFFFFFF, shadowStrength: 1 }
      });
      // 边宽=80, spread = 80 * 1 * 0.5 = 40
      expect(g.shadowSpread).assertEqual(40);
      expect(g.insets.top).assertEqual(120);  // 80 + 40
      expect(g.insets.left).assertEqual(120);
      expect(g.insets.bottom).assertEqual(120);
      expect(g.insets.right).assertEqual(120);
    });

    it('computeBaseBorderWidth uses the short edge', 0, () => {
      expect(computeBaseBorderWidth(1600, 900, 0.1)).assertEqual(90);
      expect(computeBaseBorderWidth(900, 1600, 0.1)).assertEqual(90);
      expect(computeBaseBorderWidth(1000, 1000, 0.1)).assertEqual(100);
    });

    it('produces identical ratios at different output sizes (preview vs export)', 0, () => {
      const preview = resolveBorderGeometry({
        photoWidth: 500, photoHeight: 400,
        border: { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      const export_ = resolveBorderGeometry({
        photoWidth: 4000, photoHeight: 3200,
        border: { templateId: 'polaroid', widthRatio: 0.1, colorArgb: 0, shadowStrength: 0 }
      });
      // 输出宽 / 照片宽 的比值应当一致（preview 与 export 同比例）
      const ratioPreview = preview.outputWidth / preview.photoRect.width;
      const ratioExport = export_.outputWidth / export_.photoRect.width;
      // 允许 ≤ 1 px 的整数舍入误差
      const tolerance = 1 / preview.photoRect.width + 1 / export_.photoRect.width;
      expect(Math.abs(ratioPreview - ratioExport) <= tolerance * 2).assertTrue();
    });

    it('falls back to none geometry when widthRatio is 0 regardless of templateId', 0, () => {
      const g = resolveBorderGeometry({
        photoWidth: 1000, photoHeight: 800,
        border: { templateId: 'polaroid', widthRatio: 0, colorArgb: 0, shadowStrength: 0 }
      });
      expect(g.templateId).assertEqual('none');
      expect(g.outputWidth).assertEqual(1000);
      expect(g.outputHeight).assertEqual(800);
    });
  });
}
