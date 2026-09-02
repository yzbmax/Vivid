/**
 * 编辑页共享接口冻结（实施计划 §四 / §五·第 0 阶段）。
 *
 * 冻结契约（本文件为开发者 C 独占；A/B 只从本文件 import 类型，不修改本文件）：
 * - EditEntrySource / EditRouteParams / AdjustParams：与实施计划 §四 一字不差。
 * - MockUser 接口 → AuthModels.ets（开发者 A 独占实现），不在此处。
 * - WorkRecord 新增字段（开发者 B 独占实现，C 只导入使用）：
 *     sourceImageUri: string; width: number; height: number; adjustments: AdjustParams;
 *   约束：Resource 样例作品允许 sourceImageUri 为空；新导入作品必须有本地 URI。
 * - MockWorkStore 方法名冻结（B 实现）：list / findById / create / update，见 WorkStoreApi。
 * - C 不直接操作 WorkStore 内部数组，只经 WorkStoreApi 存取作品。
 * - C 侧本轮保存契约：WorkDraft / SaveMode / buildSaveIntent（见文末）。B 的
 *   WorkRecord 扩展字段交付后由适配层把 WorkDraft 映射为 WorkRecord，不修改本文件。
 */

import { WorkRecord, WorkStatus } from './WorkRecord';

/** 进入编辑页的来源：首页选图 或 作品续编。 */
export enum EditEntrySource {
  Picker = 'picker',
  Work = 'work'
}

/**
 * 编辑页底部工具导航的稳定键（实施计划 §四 3.1 冻结契约）。
 * 禁止用显示文案作为路由键；A/B 只从本文件 import 该类型。
 * 0.1.9：原 `template` 已整体迁移为 `border`（"模板"→"边框"）。
 * 旧输入 `template` 由 normalizeEditorToolKey 统一归一化为 `border`。
 */
export type EditorToolKey =
  'filter' | 'subject' | 'background' | 'adjust' |
  'sticker' | 'text' | 'border';

/** 合法 EditorToolKey 集合，用于 parseEditRouteParams 校验。 */
export const EDITOR_TOOL_KEYS: EditorToolKey[] =
  ['filter', 'subject', 'background', 'adjust', 'sticker', 'text', 'border'];

/** 校验字符串是否为合法 EditorToolKey；非法时返回 false。 */
export function isValidEditorToolKey(value: string): boolean {
  for (let i = 0; i < EDITOR_TOOL_KEYS.length; i++) {
    if (EDITOR_TOOL_KEYS[i] === value) {
      return true;
    }
  }
  return false;
}

/**
 * 将原始工具键归一化为合法 EditorToolKey。
 * 集中处理历史兼容：旧值 `template` → `border`（0.1.9 入口迁移）。
 * 未知值回退 `adjust`（与 parseEditRouteParams 既有行为一致）。
 * 禁止在页面里散落字符串兼容判断，统一走本函数。
 */
export function normalizeEditorToolKey(raw: string): EditorToolKey {
  if (raw === 'template') {
    return 'border';
  }
  for (let i = 0; i < EDITOR_TOOL_KEYS.length; i++) {
    if (EDITOR_TOOL_KEYS[i] === raw) {
      return EDITOR_TOOL_KEYS[i];
    }
  }
  return 'adjust';
}

/** EditPage 路由参数契约：B 经 pushUrl params 传入，C 在 aboutToAppear 解析。 */
export interface EditRouteParams {
  source: EditEntrySource;
  /** Stable app-sandbox source used for decoding/rendering. */
  imageUri?: string;
  /** Temporary picker URI used only as an immediate ArkUI display fallback. */
  displayUri?: string;
  workId?: string;
  initialTool?: EditorToolKey;
}

/** Router parameters before validation. */
export interface RawEditRouteParams {
  source?: string;
  imageUri?: string;
  displayUri?: string;
  workId?: string;
  initialTool?: string;
}

/** Prefer the picker URI when present, otherwise keep the stable sandbox source visible. */
export function resolveDisplayImageSource(imageUri: string, displayUri?: string): string {
  return displayUri !== undefined && displayUri !== '' ? displayUri : imageUri;
}

/**
 * 登录后待续编辑意图（实施计划 §四 3.1 冻结契约）。
 * 仅在进程内保存；不持久化、不写日志、不通过路由参数反复传递。
 * A 的 PendingEditIntentStore 使用本类型。
 */
export interface PendingEditIntent {
  imageUri: string;
  displayUri: string;
  initialTool: EditorToolKey;
  createdAt: number;
}

/** 五项调色参数快照，范围 -100 … +100。 */
export interface AdjustParams {
  exposure: number;
  brightness: number;
  contrast: number;
  saturation: number;
  temperature: number;   // V2 新增：色温，RegionRenderer 像素级渲染使用
}

/** 调色参数边界。 */
export const ADJUST_MIN: number = -100;
export const ADJUST_MAX: number = 100;

/** 默认调色参数（五项全 0）。 */
export const DEFAULT_ADJUSTMENTS: AdjustParams = {
  exposure: 0,
  brightness: 0,
  contrast: 0,
  saturation: 0,
  temperature: 0
};

/** 返回独立默认参数副本，避免共享同一对象引用。 */
export function createDefaultAdjustments(): AdjustParams {
  return { exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 0 };
}

/** 五项参数逐项钳制到 [ADJUST_MIN, ADJUST_MAX] 并取整。 */
export function clampAdjustments(p: AdjustParams): AdjustParams {
  const clamp = (v: number): number =>
    Math.min(ADJUST_MAX, Math.max(ADJUST_MIN, Math.round(v)));
  return {
    exposure: clamp(p.exposure),
    brightness: clamp(p.brightness),
    contrast: clamp(p.contrast),
    saturation: clamp(p.saturation),
    temperature: clamp(p.temperature)
  };
}

/**
 * 由路由 getParams() 原始对象解析编辑页入参；source 缺失或非法时返回 null。
 * initialTool 缺失时为 undefined（由调用方决定默认值）；非法值回退 'adjust'。
 */
export function parseEditRouteParams(raw: RawEditRouteParams): EditRouteParams | null {
  if (raw.source === EditEntrySource.Picker) {
    const result: EditRouteParams = {
      source: EditEntrySource.Picker,
      imageUri: raw.imageUri ?? '',
      displayUri: raw.displayUri ?? ''
    };
    const tool = raw.initialTool;
    if (tool !== undefined && tool !== '') {
      result.initialTool = normalizeEditorToolKey(tool);
    }
    return result;
  }
  if (raw.source === EditEntrySource.Work) {
    const result: EditRouteParams = {
      source: EditEntrySource.Work,
      workId: raw.workId ?? ''
    };
    const tool = raw.initialTool;
    if (tool !== undefined && tool !== '') {
      result.initialTool = normalizeEditorToolKey(tool);
    }
    return result;
  }
  return null;
}

/** 校验编辑页入参，返回错误文案；合法时返回空串。 */
export function editRouteError(route: EditRouteParams | null): string {
  if (route == null) {
    return '路由参数缺失：请从首页选图或作品详情进入编辑页';
  }
  if (route.source === EditEntrySource.Picker && (route.imageUri ?? '') === '') {
    return '未获取到所选图片，请返回重试';
  }
  if (route.source === EditEntrySource.Work && (route.workId ?? '') === '') {
    return '未获取到作品编号，请返回重试';
  }
  return '';
}

/**
 * MockWorkStore 冻结方法契约（实施计划 §四）：B 的 MockWorkStore.ets 实现本接口。
 * C 只经此接口存取作品，不直接操作内部数组。
 * 说明：接口参数用显式 WorkRecord（仓库无 Partial<> 先例）。若 B 导入 AdjustParams
 * 进 WorkRecord 引发类型级循环编译问题，WorkStoreApi 可改由 B 在 MockWorkStore.ets
 * 中定义——冻结的只是方法名，不是接口所在文件。
 */
export interface WorkStoreApi {
  list(): WorkRecord[];
  findById(id: string): WorkRecord | null;
  create(rec: WorkRecord): WorkRecord;
  update(id: string, patch: WorkRecord): WorkRecord;
}

// ───────────────────────── 编辑状态纯逻辑（第 1/2 阶段）─────────────────────────

/** 滑块取值格式化：0 → '00'，15 → '+15'，-8 → '-08'，100 → '+100'，-100 → '-100'。 */
export function formatAdjustValue(v: number): string {
  const clamped = Math.round(Math.min(ADJUST_MAX, Math.max(ADJUST_MIN, v)));
  const sign = clamped > 0 ? '+' : (clamped < 0 ? '-' : '');
  const abs = Math.abs(clamped);
  const digits = abs < 10 ? `0${abs}` : `${abs}`;
  return `${sign}${digits}`;
}

/** 参数 → 预览效果的纯映射结果。 */
export interface AdjustEffects {
  /** 明暗覆盖层透明度 [0,1]，0=无。 */
  luminanceAlpha: number;
  /** true=白色覆盖层（提亮），false=黑色覆盖层（压暗）。 */
  luminanceLight: boolean;
  /** 组件对比度，1=原始，范围 [0.1, 1.9]。 */
  contrast: number;
  /** 组件饱和度，1=原始，范围 [0.2, 1.8]。 */
  saturate: number;
  /** V2 新增：色温暖度偏移，[-0.12, 0.12]。正=暖，负=冷。 */
  warmth: number;
}

/**
 * 由四项调色参数计算预览效果，每项都产生可见反馈：
 * 曝光 + 亮度 → 明暗覆盖层；对比度 → 组件 contrast()；饱和度 → 组件 saturate()。
 * 四个参数都从原图与当前参数重新计算，不把滑动累积写回源图。
 */
export function mapParamsToEffects(p: AdjustParams): AdjustEffects {
  const e = clampAdjustments(p);
  const lum = (e.exposure * 0.30 + e.brightness * 0.25) / 100; // [-0.55, 0.55]
  const luminanceAlpha = Math.round(Math.min(0.6, Math.abs(lum)) * 1000) / 1000;
  const luminanceLight = lum >= 0;
  const contrast = Math.round((1 + (e.contrast / 100) * 0.9) * 1000) / 1000; // [0.1, 1.9]
  const saturate = Math.round((1 + (e.saturation / 100) * 0.8) * 1000) / 1000; // [0.2, 1.8]
  const warmth = Math.round((e.temperature / 100) * 0.12 * 1000) / 1000; // [-0.12, 0.12]
  return { luminanceAlpha, luminanceLight, contrast, saturate, warmth };
}

/** 保存动作：新建 或 续编更新。 */
export enum SaveMode {
  Create = 'create',
  Update = 'update'
}

/**
 * C 侧保存用的作品草稿（本轮独立契约）。B 的 WorkRecord 扩展字段交付后，
 * 由适配层把 WorkDraft 映射为 WorkRecord，字段与冻结契约一致。
 */
export interface WorkDraft {
  id: string;
  title: string;
  sourceImageUri: string;
  width: number;
  height: number;
  adjustments: AdjustParams;
  status: WorkStatus;
  createdAt: number;
  updatedAt: number;
}

/** buildSaveIntent 的结果：保存方向 + 草稿。 */
export interface SaveIntent {
  mode: SaveMode;
  id?: string;
  draft: WorkDraft;
}

/**
 * 构造保存意图（正式保存）：
 * - source=Work 且有 workId → 续编更新（不重复建卡，计划书 §三 B 验收）。
 * - 否则 → 新建，标题「未题新卷」、状态已封缄。
 * now 由调用方传入，保证纯函数可单测。
 */
export function buildSaveIntent(
  source: EditEntrySource,
  workId: string,
  imageUri: string,
  params: AdjustParams,
  now: number
): SaveIntent {
  const clamped = clampAdjustments(params);
  if (source === EditEntrySource.Work && workId !== '') {
    const draft: WorkDraft = {
      id: workId,
      title: '未题新卷',
      sourceImageUri: imageUri,
      width: 0,
      height: 0,
      adjustments: clamped,
      status: WorkStatus.Sealed,
      createdAt: 0,
      updatedAt: now
    };
    return { mode: SaveMode.Update, id: workId, draft };
  }
  const draft: WorkDraft = {
    id: `MOCK-${now}`,
    title: '未题新卷',
    sourceImageUri: imageUri,
    width: 0,
    height: 0,
    adjustments: clamped,
    status: WorkStatus.Sealed,
    createdAt: now,
    updatedAt: now
  };
  return { mode: SaveMode.Create, draft };
}

/**
 * 构造草稿保存意图（放弃返回时自动调用）：
 * - source=Work 且有 workId → 续编更新，状态降为 Draft。
 * - 否则 → 新建草稿，标题「未题草卷」。
 * now 由调用方传入，保证纯函数可单测。
 */
export function buildDraftIntent(
  source: EditEntrySource,
  workId: string,
  imageUri: string,
  params: AdjustParams,
  now: number
): SaveIntent {
  const clamped = clampAdjustments(params);
  if (source === EditEntrySource.Work && workId !== '') {
    const draft: WorkDraft = {
      id: workId,
      title: '未题草卷',
      sourceImageUri: imageUri,
      width: 0,
      height: 0,
      adjustments: clamped,
      status: WorkStatus.Draft,
      createdAt: 0,
      updatedAt: now
    };
    return { mode: SaveMode.Update, id: workId, draft };
  }
  const draft: WorkDraft = {
    id: `MOCK-${now}`,
    title: '未题草卷',
    sourceImageUri: imageUri,
    width: 0,
    height: 0,
    adjustments: clamped,
    status: WorkStatus.Draft,
    createdAt: now,
    updatedAt: now
  };
  return { mode: SaveMode.Create, draft };
}

// ───────────────────────── 编辑页布局常量（第 3 轮样式）─────────────────────────

/** 底部工具导航条目。 */
export interface EditorTool {
  key: EditorToolKey;
  label: string;
}

/** 编辑页底部工具导航（7 项），当前活动工具「调节」。 */
export const EDITOR_TOOLS: EditorTool[] = [
  { key: 'filter', label: '滤镜' },
  { key: 'subject', label: '主体' },
  { key: 'background', label: '背景' },
  { key: 'adjust', label: '调节' },
  { key: 'sticker', label: '贴纸' },
  { key: 'text', label: '文字' },
  { key: 'border', label: '边框' }
];

/** 调节工具下的调整类型定义。 */
export interface AdjustTypeDef {
  key: string;
  label: string;
  unit: string;
}

/** 「调节」工具内的五种调整类型（V2 新增 temperature）。 */
export const ADJUST_TYPES: AdjustTypeDef[] = [
  { key: 'exposure', label: '曝光', unit: 'EXP' },
  { key: 'brightness', label: '亮度', unit: 'LUM' },
  { key: 'contrast', label: '对比度', unit: 'CON' },
  { key: 'saturation', label: '饱和度', unit: 'SAT' },
  { key: 'temperature', label: '色温', unit: 'TMP' }
];

// ───────────────────────── V2 区域调色类型（主体/背景分离）─────────────────────────

/** 区域键：主体 或 背景。 */
export type RegionKey = 'subject' | 'background';

/** 双区域调色参数（主体和背景各自独立）。 */
export interface RegionAdjustments {
  subject: AdjustParams;
  background: AdjustParams;
}

/** 返回独立的默认双区域参数（五项全 0）。 */
export function createDefaultRegionAdjustments(): RegionAdjustments {
  return {
    subject: createDefaultAdjustments(),
    background: createDefaultAdjustments()
  };
}

/** 深拷贝 AdjustParams（ArkTS 不支持对象展开 { ...obj }）。 */
export function cloneAdjustments(p: AdjustParams): AdjustParams {
  return {
    exposure: p.exposure,
    brightness: p.brightness,
    contrast: p.contrast,
    saturation: p.saturation,
    temperature: p.temperature
  };
}

/** 深拷贝 RegionAdjustments（两个子对象各自独立）。 */
export function cloneRegionAdjustments(src: RegionAdjustments): RegionAdjustments {
  return {
    subject: cloneAdjustments(src.subject),
    background: cloneAdjustments(src.background)
  };
}

/**
 * 区域调整类型（4 项，不含 exposure）。
 * exposure 是纯 CSS 预览参数（通过叠加透明度层模拟），不参与 Worker 像素级渲染。
 * 区域模式需要像素精确，所以排除 exposure。
 */
export const REGION_ADJUST_TYPES: AdjustTypeDef[] = [
  { key: 'brightness', label: '亮度', unit: 'LUM' },
  { key: 'contrast', label: '对比度', unit: 'CON' },
  { key: 'saturation', label: '饱和度', unit: 'SAT' },
  { key: 'temperature', label: '色温', unit: 'TMP' }
];

// ───────────────────────── 贴纸（自由贴签）类型定义 ─────────────────────────

/** 贴纸分类键。 */
export type StickerCategory = 'seal' | 'corner' | 'label' | 'auspicious';

/** 贴纸渲染类型（决定 StickerLayer 如何绘制）。 */
export enum StickerRenderType {
  /** 印章：红底白字方框，纯代码绘制（复用 SealBadge 模式）。 */
  SealStamp = 'seal_stamp',
  /** 角花：SVG/PNG 图片资源。 */
  CornerFlower = 'corner_flower',
  /** 标签条：宣纸底+墨字，纯代码绘制。 */
  LabelStrip = 'label_strip',
  /** 吉祥图：SVG/PNG 图案。 */
  AuspiciousIcon = 'auspicious_icon'
}

/** 贴纸模板（从模板创建实例）。 */
export interface StickerTemplate {
  id: string;
  name: string;
  category: StickerCategory;
  renderType: StickerRenderType;
  /** 图片资源（SealStamp / LabelStrip 为 null，纯代码绘制）。 */
  resource: Resource | null;
  /** 印章文字 / 标签文字。 */
  textContent: string;
  /** 默认显示尺寸（vp）。 */
  defaultSize: number;
}

/** 贴纸实例（放置在预览区的一个贴纸）。 */
export interface StickerItem {
  /** 唯一实例 id。 */
  instanceId: string;
  /** 对应模板 id。 */
  templateId: string;
  /** 像素偏移（相对预览区左上角）。 */
  posX: number;
  posY: number;
  /** 显示尺寸（vp）。 */
  size: number;
  /** 旋转角度（度）。 */
  rotation: number;
  /** 透明度 0.3~1.0。 */
  opacity: number;
  /** 层级（越大越靠前）。 */
  zIndex: number;
}

/** 贴纸分类定义。 */
export interface StickerCategoryDef {
  key: StickerCategory;
  label: string;
}

/** 贴纸分类列表。 */
export const STICKER_CATEGORIES: StickerCategoryDef[] = [
  { key: 'seal', label: '闲章' },
  { key: 'corner', label: '角花' },
  { key: 'label', label: '签条' },
  { key: 'auspicious', label: '吉祥' }
];

/** 贴纸数量上限。 */
export const STICKER_MAX_COUNT: number = 12;

/** 贴纸模板库（初始 14 枚）。 */
export const STICKER_TEMPLATES: StickerTemplate[] = [
  // ── 闲章（纯代码绘制，无需图片资源）──
  { id: 'seal-01', name: '雅正', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '雅', defaultSize: 48 },
  { id: 'seal-02', name: '墨戏', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '墨', defaultSize: 48 },
  { id: 'seal-03', name: '清玩', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '清', defaultSize: 48 },
  { id: 'seal-04', name: '静心', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '静', defaultSize: 48 },
  { id: 'seal-05', name: '怡然', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '怡', defaultSize: 48 },
  { id: 'seal-06', name: '逸趣', category: 'seal', renderType: StickerRenderType.SealStamp, resource: null, textContent: '逸', defaultSize: 48 },

  // ── 角花（需 SVG 资源）──
  { id: 'corner-01', name: '回纹角花', category: 'corner', renderType: StickerRenderType.CornerFlower, resource: $r('app.media.sticker_corner_hui'), textContent: '', defaultSize: 64 },
  { id: 'corner-02', name: '云纹角花', category: 'corner', renderType: StickerRenderType.CornerFlower, resource: $r('app.media.sticker_corner_yun'), textContent: '', defaultSize: 64 },
  { id: 'corner-03', name: '梅花角花', category: 'corner', renderType: StickerRenderType.CornerFlower, resource: $r('app.media.sticker_corner_mei'), textContent: '', defaultSize: 64 },
  { id: 'corner-04', name: '莲花角花', category: 'corner', renderType: StickerRenderType.CornerFlower, resource: $r('app.media.sticker_corner_lian'), textContent: '', defaultSize: 64 },

  // ── 签条（纯代码绘制，无需图片资源）──
  { id: 'label-01', name: '题签', category: 'label', renderType: StickerRenderType.LabelStrip, resource: null, textContent: '题签', defaultSize: 48 },
  { id: 'label-02', name: '品名', category: 'label', renderType: StickerRenderType.LabelStrip, resource: null, textContent: '品名', defaultSize: 48 },

  // ── 吉祥图（需 SVG 资源）──
  { id: 'ausp-01', name: '如意', category: 'auspicious', renderType: StickerRenderType.AuspiciousIcon, resource: $r('app.media.sticker_ausp_ruyi'), textContent: '', defaultSize: 56 },
  { id: 'ausp-02', name: '祥云', category: 'auspicious', renderType: StickerRenderType.AuspiciousIcon, resource: $r('app.media.sticker_ausp_cloud'), textContent: '', defaultSize: 56 }
];

/**
 * 根据模板 id 查找模板。
 * 未找到时返回 null。
 */
export function findStickerTemplate(templateId: string): StickerTemplate | null {
  for (let i = 0; i < STICKER_TEMPLATES.length; i++) {
    if (STICKER_TEMPLATES[i].id === templateId) {
      return STICKER_TEMPLATES[i];
    }
  }
  return null;
}

/**
 * 创建贴纸实例（默认放置在预览区中心）。
 * centerX / centerY 为预览区中心像素坐标。
 */
export function createStickerInstance(templateId: string, centerX: number, centerY: number): StickerItem {
  const tpl = findStickerTemplate(templateId);
  const defaultSize = tpl != null ? tpl.defaultSize : 48;
  const microRotate = Math.floor(Math.random() * 7) - 3; // -3~+3 微倾（印章感）
  return {
    instanceId: 'sticker-' + Date.now().toString() + '-' + Math.floor(Math.random() * 1000).toString(),
    templateId: templateId,
    posX: centerX - defaultSize / 2,
    posY: centerY - defaultSize / 2,
    size: defaultSize,
    rotation: microRotate,
    opacity: 1.0,
    zIndex: Date.now()
  };
}

/** 按分类过滤模板。 */
export function filterTemplatesByCategory(category: StickerCategory): StickerTemplate[] {
  const result: StickerTemplate[] = [];
  for (let i = 0; i < STICKER_TEMPLATES.length; i++) {
    if (STICKER_TEMPLATES[i].category === category) {
      result.push(STICKER_TEMPLATES[i]);
    }
  }
  return result;
}
