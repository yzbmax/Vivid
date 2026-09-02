import { describe, it, expect } from '@ohos/hypium';
import {
  ADJUST_MAX,
  ADJUST_MIN,
  ADJUST_TYPES,
  DEFAULT_ADJUSTMENTS,
  EDITOR_TOOLS,
  EDITOR_TOOL_KEYS,
  EditEntrySource,
  SaveMode,
  buildDraftIntent,
  buildSaveIntent,
  clampAdjustments,
  createDefaultAdjustments,
  editRouteError,
  formatAdjustValue,
  isValidEditorToolKey,
  normalizeEditorToolKey,
  mapParamsToEffects,
  parseEditRouteParams,
  resolveDisplayImageSource,
  RawEditRouteParams
} from '../main/ets/models/EditModels';
import { WorkStatus } from '../main/ets/models/WorkRecord';
import { EditWorkStore } from '../main/ets/models/EditWorkStore';

export default function editModelsTest() {
  describe('editModelsTest', () => {
    it('parses a picker route with image uri', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'picker',
        imageUri: '/data/cache/a.image',
        displayUri: 'file://media/Photo/1'
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.source).assertEqual(EditEntrySource.Picker);
      expect(route?.imageUri).assertEqual('/data/cache/a.image');
      expect(route?.displayUri).assertEqual('file://media/Photo/1');
    });

    it('parses a work route with workId', 0, () => {
      const raw: RawEditRouteParams = { source: 'work', workId: '0409-A' };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.source).assertEqual(EditEntrySource.Work);
      expect(route?.workId).assertEqual('0409-A');
    });

    it('returns null for missing or unknown source', 0, () => {
      const empty: RawEditRouteParams = {};
      const unknown: RawEditRouteParams = { source: 'other' };
      expect(parseEditRouteParams(empty) === null).assertEqual(true);
      expect(parseEditRouteParams(unknown) === null).assertEqual(true);
    });

    it('reports a message when a route is null', 0, () => {
      expect(editRouteError(null)).assertEqual('路由参数缺失：请从首页选图或作品详情进入编辑页');
    });

    it('reports a message when picker lacks an image uri', 0, () => {
      const raw: RawEditRouteParams = { source: 'picker' };
      expect(editRouteError(parseEditRouteParams(raw))).assertEqual('未获取到所选图片，请返回重试');
    });

    it('reports a message when work lacks a work id', 0, () => {
      const raw: RawEditRouteParams = { source: 'work' };
      expect(editRouteError(parseEditRouteParams(raw))).assertEqual('未获取到作品编号，请返回重试');
    });

    it('returns empty message for a valid route', 0, () => {
      const raw: RawEditRouteParams = { source: 'picker', imageUri: 'file:///tmp/a.jpg' };
      const route = parseEditRouteParams(raw);
      expect(editRouteError(route)).assertEqual('');
    });

    it('falls back to the stable processing path when display uri is absent', 0, () => {
      expect(resolveDisplayImageSource('/data/cache/a.image', '')).assertEqual('/data/cache/a.image');
      expect(resolveDisplayImageSource('/data/cache/a.image', 'file://media/Photo/1'))
        .assertEqual('file://media/Photo/1');
    });

    it('creates an all-zero default adjustment set', 0, () => {
      const p = createDefaultAdjustments();
      expect(p.exposure).assertEqual(0);
      expect(p.brightness).assertEqual(0);
      expect(p.contrast).assertEqual(0);
      expect(p.saturation).assertEqual(0);
      expect(p.temperature).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.exposure).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.brightness).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.contrast).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.saturation).assertEqual(0);
      expect(DEFAULT_ADJUSTMENTS.temperature).assertEqual(0);
    });

    it('returns an independent object on each default call', 0, () => {
      const a = createDefaultAdjustments();
      const b = createDefaultAdjustments();
      expect(a === b).assertEqual(false);
    });

    it('clamps adjustments into the -100..100 range', 0, () => {
      const out = clampAdjustments({ exposure: 120, brightness: -120, contrast: 50, saturation: 0, temperature: 0 });
      expect(out.exposure).assertEqual(ADJUST_MAX);
      expect(out.brightness).assertEqual(ADJUST_MIN);
      expect(out.contrast).assertEqual(50);
      expect(out.saturation).assertEqual(0);
    });

    it('rounds and clamps fractional values', 0, () => {
      const out = clampAdjustments({ exposure: 101.6, brightness: -99.4, contrast: 99.6, saturation: -100.5, temperature: 0 });
      expect(out.exposure).assertEqual(100);
      expect(out.brightness).assertEqual(-99);
      expect(out.contrast).assertEqual(100);
      expect(out.saturation).assertEqual(-100);
    });

    it('formats adjust values as signed two-digit strings', 0, () => {
      expect(formatAdjustValue(0)).assertEqual('00');
      expect(formatAdjustValue(15)).assertEqual('+15');
      expect(formatAdjustValue(7)).assertEqual('+07');
      expect(formatAdjustValue(-8)).assertEqual('-08');
      expect(formatAdjustValue(100)).assertEqual('+100');
      expect(formatAdjustValue(-100)).assertEqual('-100');
      expect(formatAdjustValue(150)).assertEqual('+100');
      expect(formatAdjustValue(-150)).assertEqual('-100');
    });

    it('maps default params to a neutral effect', 0, () => {
      const fx = mapParamsToEffects(createDefaultAdjustments());
      expect(fx.luminanceAlpha).assertEqual(0);
      expect(fx.luminanceLight).assertEqual(true);
      expect(fx.contrast).assertEqual(1);
      expect(fx.saturate).assertEqual(1);
      expect(fx.warmth).assertEqual(0);
    });

    it('maps exposure to a light or dark overlay', 0, () => {
      const light = mapParamsToEffects({ exposure: 100, brightness: 0, contrast: 0, saturation: 0, temperature: 0 });
      expect(light.luminanceAlpha).assertEqual(0.3);
      expect(light.luminanceLight).assertEqual(true);
      const dark = mapParamsToEffects({ exposure: -100, brightness: 0, contrast: 0, saturation: 0, temperature: 0 });
      expect(dark.luminanceAlpha).assertEqual(0.3);
      expect(dark.luminanceLight).assertEqual(false);
    });

    it('combines exposure and brightness into luminance overlay', 0, () => {
      const fx = mapParamsToEffects({ exposure: 100, brightness: 100, contrast: 0, saturation: 0, temperature: 0 });
      expect(fx.luminanceAlpha).assertEqual(0.55);
      expect(fx.luminanceLight).assertEqual(true);
    });

    it('maps contrast and saturation to component effects', 0, () => {
      const up = mapParamsToEffects({ exposure: 0, brightness: 0, contrast: 100, saturation: 100, temperature: 0 });
      expect(up.contrast).assertEqual(1.9);
      expect(up.saturate).assertEqual(1.8);
      const down = mapParamsToEffects({ exposure: 0, brightness: 0, contrast: -100, saturation: -100, temperature: 0 });
      expect(down.contrast).assertEqual(0.1);
      expect(down.saturate).assertEqual(0.2);
    });

    it('maps temperature to warmth effect', 0, () => {
      const warm = mapParamsToEffects({ exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 100 });
      expect(warm.warmth).assertEqual(0.12);
      const cool = mapParamsToEffects({ exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: -100 });
      expect(cool.warmth).assertEqual(-0.12);
    });

    it('builds a create intent from a picker source', 0, () => {
      const intent = buildSaveIntent(EditEntrySource.Picker, '', 'file:///tmp/a.jpg',
        { exposure: 150, brightness: 0, contrast: 0, saturation: 0, temperature: 0 }, 1000);
      expect(intent.mode).assertEqual(SaveMode.Create);
      expect(intent.draft.id).assertEqual('MOCK-1000');
      expect(intent.draft.title).assertEqual('未题新卷');
      expect(intent.draft.sourceImageUri).assertEqual('file:///tmp/a.jpg');
      expect(intent.draft.adjustments.exposure).assertEqual(100);
      expect(intent.draft.status).assertEqual(WorkStatus.Sealed);
      expect(intent.draft.createdAt).assertEqual(1000);
      expect(intent.draft.updatedAt).assertEqual(1000);
    });

    it('builds an update intent from a work source', 0, () => {
      const intent = buildSaveIntent(EditEntrySource.Work, '0409-A', 'file:///tmp/a.jpg',
        { exposure: 10, brightness: -20, contrast: 30, saturation: 0, temperature: 0 }, 2000);
      expect(intent.mode).assertEqual(SaveMode.Update);
      expect(intent.id).assertEqual('0409-A');
      expect(intent.draft.id).assertEqual('0409-A');
      expect(intent.draft.createdAt).assertEqual(0);
      expect(intent.draft.updatedAt).assertEqual(2000);
      expect(intent.draft.adjustments.brightness).assertEqual(-20);
    });

    it('treats a work source without id as a create', 0, () => {
      const intent = buildSaveIntent(EditEntrySource.Work, '', 'file:///tmp/a.jpg',
        createDefaultAdjustments(), 3000);
      expect(intent.mode).assertEqual(SaveMode.Create);
    });

    it('builds a draft create intent from a picker source', 0, () => {
      const intent = buildDraftIntent(EditEntrySource.Picker, '', 'file:///tmp/a.jpg',
        { exposure: 50, brightness: 0, contrast: 0, saturation: 0, temperature: 0 }, 4000);
      expect(intent.mode).assertEqual(SaveMode.Create);
      expect(intent.draft.id).assertEqual('MOCK-4000');
      expect(intent.draft.title).assertEqual('未题草卷');
      expect(intent.draft.sourceImageUri).assertEqual('file:///tmp/a.jpg');
      expect(intent.draft.adjustments.exposure).assertEqual(50);
      expect(intent.draft.status).assertEqual(WorkStatus.Draft);
      expect(intent.draft.createdAt).assertEqual(4000);
      expect(intent.draft.updatedAt).assertEqual(4000);
    });

    it('builds a draft update intent from a work source', 0, () => {
      const intent = buildDraftIntent(EditEntrySource.Work, '0409-C', 'file:///tmp/b.jpg',
        { exposure: 0, brightness: 30, contrast: -10, saturation: 0, temperature: 0 }, 5000);
      expect(intent.mode).assertEqual(SaveMode.Update);
      expect(intent.id).assertEqual('0409-C');
      expect(intent.draft.id).assertEqual('0409-C');
      expect(intent.draft.title).assertEqual('未题草卷');
      expect(intent.draft.status).assertEqual(WorkStatus.Draft);
      expect(intent.draft.createdAt).assertEqual(0);
      expect(intent.draft.updatedAt).assertEqual(5000);
      expect(intent.draft.adjustments.brightness).assertEqual(30);
    });

    it('treats a work source without id as a draft create', 0, () => {
      const intent = buildDraftIntent(EditEntrySource.Work, '', 'file:///tmp/a.jpg',
        createDefaultAdjustments(), 6000);
      expect(intent.mode).assertEqual(SaveMode.Create);
      expect(intent.draft.status).assertEqual(WorkStatus.Draft);
      expect(intent.draft.title).assertEqual('未题草卷');
    });

    it('stub store creates and finds a draft', 0, () => {
      EditWorkStore.clear();
      const created = EditWorkStore.create({
        id: 'MOCK-1',
        title: '未题新卷',
        sourceImageUri: 'file:///tmp/a.jpg',
        width: 0,
        height: 0,
        adjustments: createDefaultAdjustments(),
        status: WorkStatus.Sealed,
        createdAt: 1,
        updatedAt: 1
      });
      expect(EditWorkStore.findById('MOCK-1') === null).assertEqual(false);
      expect(EditWorkStore.findById('MOCK-1')?.id).assertEqual('MOCK-1');
      expect(created.id).assertEqual('MOCK-1');
    });

    it('stub store updates an existing draft without duplicating', 0, () => {
      EditWorkStore.clear();
      EditWorkStore.create({
        id: 'MOCK-2',
        title: '未题新卷',
        sourceImageUri: 'file:///tmp/a.jpg',
        width: 0,
        height: 0,
        adjustments: createDefaultAdjustments(),
        status: WorkStatus.Sealed,
        createdAt: 1,
        updatedAt: 1
      });
      const patch = EditWorkStore.update('MOCK-2', {
        id: 'MOCK-2',
        title: '未题新卷',
        sourceImageUri: 'file:///tmp/a.jpg',
        width: 0,
        height: 0,
        adjustments: { exposure: 20, brightness: 0, contrast: 0, saturation: 0, temperature: 0 },
        status: WorkStatus.Sealed,
        createdAt: 1,
        updatedAt: 99
      });
      expect(patch === null).assertEqual(false);
      expect(patch?.adjustments.exposure).assertEqual(20);
      expect(patch?.updatedAt).assertEqual(99);
      expect(EditWorkStore.list().length).assertEqual(1);
    });

    it('stub store update returns null for an unknown id', 0, () => {
      EditWorkStore.clear();
      const missing = EditWorkStore.update('NOPE', {
        id: 'NOPE',
        title: '',
        sourceImageUri: '',
        width: 0,
        height: 0,
        adjustments: createDefaultAdjustments(),
        status: WorkStatus.Sealed,
        createdAt: 0,
        updatedAt: 0
      });
      expect(missing === null).assertEqual(true);
    });

    it('defines the seven editor tools with adjust active by default', 0, () => {
      expect(EDITOR_TOOLS.length).assertEqual(7);
      expect(EDITOR_TOOLS[3].key).assertEqual('adjust');
      expect(EDITOR_TOOLS[3].label).assertEqual('调节');
      expect(EDITOR_TOOLS[0].label).assertEqual('滤镜');
      // 0.1.9 入口迁移：末项为 `border` / "边框"，不再有 `template`
      expect(EDITOR_TOOLS[6].key).assertEqual('border');
      expect(EDITOR_TOOLS[6].label).assertEqual('边框');
      for (let i = 0; i < EDITOR_TOOLS.length; i++) {
        expect(EDITOR_TOOLS[i].key === 'template').assertEqual(false);
      }
    });

    it('defines the five adjust types (V2: + temperature)', 0, () => {
      expect(ADJUST_TYPES.length).assertEqual(5);
      expect(ADJUST_TYPES[0].key).assertEqual('exposure');
      expect(ADJUST_TYPES[1].key).assertEqual('brightness');
      expect(ADJUST_TYPES[2].key).assertEqual('contrast');
      expect(ADJUST_TYPES[3].key).assertEqual('saturation');
      expect(ADJUST_TYPES[4].key).assertEqual('temperature');
    });

    it('defines seven valid editor tool keys', 0, () => {
      expect(EDITOR_TOOL_KEYS.length).assertEqual(7);
      expect(isValidEditorToolKey('filter')).assertEqual(true);
      expect(isValidEditorToolKey('subject')).assertEqual(true);
      expect(isValidEditorToolKey('background')).assertEqual(true);
      expect(isValidEditorToolKey('adjust')).assertEqual(true);
      expect(isValidEditorToolKey('sticker')).assertEqual(true);
      expect(isValidEditorToolKey('text')).assertEqual(true);
      expect(isValidEditorToolKey('border')).assertEqual(true);
      // 0.1.9 入口迁移：旧 `template` 不再是公开工具键
      expect(isValidEditorToolKey('template')).assertEqual(false);
    });

    it('rejects invalid editor tool keys', 0, () => {
      expect(isValidEditorToolKey('')).assertEqual(false);
      expect(isValidEditorToolKey('unknown')).assertEqual(false);
      expect(isValidEditorToolKey('ADJUST')).assertEqual(false);
      expect(isValidEditorToolKey('滤镜')).assertEqual(false);
    });

    it('normalizes legacy template key to border', 0, () => {
      // 0.1.9 入口迁移：旧 `template` 必须统一归一化为 `border`
      expect(normalizeEditorToolKey('template')).assertEqual('border');
    });

    it('passes through valid editor tool keys unchanged', 0, () => {
      expect(normalizeEditorToolKey('filter')).assertEqual('filter');
      expect(normalizeEditorToolKey('subject')).assertEqual('subject');
      expect(normalizeEditorToolKey('background')).assertEqual('background');
      expect(normalizeEditorToolKey('adjust')).assertEqual('adjust');
      expect(normalizeEditorToolKey('sticker')).assertEqual('sticker');
      expect(normalizeEditorToolKey('text')).assertEqual('text');
      expect(normalizeEditorToolKey('border')).assertEqual('border');
    });

    it('falls back to adjust for unknown tool keys', 0, () => {
      expect(normalizeEditorToolKey('')).assertEqual('adjust');
      expect(normalizeEditorToolKey('unknown_tool')).assertEqual('adjust');
      expect(normalizeEditorToolKey('TEMPLATE')).assertEqual('adjust');
      expect(normalizeEditorToolKey('模板')).assertEqual('adjust');
    });

    it('parses legacy template initialTool as border', 0, () => {
      // 历史路由、旧作品、待处理编辑意图中的 `template` 必须归一化为 `border`
      const picker: RawEditRouteParams = {
        source: 'picker',
        imageUri: 'file:///tmp/a.jpg',
        initialTool: 'template'
      };
      const pickerRoute = parseEditRouteParams(picker);
      expect(pickerRoute === null).assertEqual(false);
      expect(pickerRoute?.initialTool).assertEqual('border');

      const work: RawEditRouteParams = {
        source: 'work',
        workId: '0409-A',
        initialTool: 'template'
      };
      const workRoute = parseEditRouteParams(work);
      expect(workRoute === null).assertEqual(false);
      expect(workRoute?.initialTool).assertEqual('border');
    });

    it('parses initialTool when present and valid', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'picker',
        imageUri: 'file:///tmp/a.jpg',
        initialTool: 'filter'
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.initialTool).assertEqual('filter');
    });

    it('falls back to adjust when initialTool is invalid', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'picker',
        imageUri: 'file:///tmp/a.jpg',
        initialTool: 'unknown_tool'
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.initialTool).assertEqual('adjust');
    });

    it('leaves initialTool undefined when not provided', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'picker',
        imageUri: 'file:///tmp/a.jpg'
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.initialTool).assertEqual(undefined);
    });

    it('parses initialTool for work source routes', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'work',
        workId: '0409-A',
        initialTool: 'subject'
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.source).assertEqual(EditEntrySource.Work);
      expect(route?.workId).assertEqual('0409-A');
      expect(route?.initialTool).assertEqual('subject');
    });

    it('falls back to adjust for invalid initialTool on work route', 0, () => {
      const raw: RawEditRouteParams = {
        source: 'work',
        workId: '0409-A',
        initialTool: ''
      };
      const route = parseEditRouteParams(raw);
      expect(route === null).assertEqual(false);
      expect(route?.initialTool).assertEqual(undefined);
    });
  });
}
