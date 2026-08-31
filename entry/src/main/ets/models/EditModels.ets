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
 */
export type EditorToolKey =
  'filter' | 'subject' | 'background' | 'adjust' |
  'sticker' | 'text' | 'template';

/** 合法 EditorToolKey 集合，用于 parseEditRouteParams 校验。 */
export const EDITOR_TOOL_KEYS: EditorToolKey[] =
  ['filter', 'subject', 'background', 'adjust', 'sticker', 'text', 'template'];

/** 校验字符串是否为合法 EditorToolKey；非法时返回 false。 */
export function isValidEditorToolKey(value: string): boolean {
  for (let i = 0; i < EDITOR_TOOL_KEYS.length; i++) {
    if (EDITOR_TOOL_KEYS[i] === value) {
      return true;
    }
  }
  return false;
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

/** 四项调色参数快照，范围 -100 … +100。 */
export interface AdjustParams {
  exposure: number;
  brightness: number;
  contrast: number;
  saturation: number;
}

/** 调色参数边界。 */
export const ADJUST_MIN: number = -100;
export const ADJUST_MAX: number = 100;

/** 默认调色参数（四项全 0）。 */
export const DEFAULT_ADJUSTMENTS: AdjustParams = {
  exposure: 0,
  brightness: 0,
  contrast: 0,
  saturation: 0
};

/** 返回独立默认参数副本，避免共享同一对象引用。 */
export function createDefaultAdjustments(): AdjustParams {
  return { exposure: 0, brightness: 0, contrast: 0, saturation: 0 };
}

/** 四项参数逐项钳制到 [ADJUST_MIN, ADJUST_MAX] 并取整。 */
export function clampAdjustments(p: AdjustParams): AdjustParams {
  const clamp = (v: number): number =>
    Math.min(ADJUST_MAX, Math.max(ADJUST_MIN, Math.round(v)));
  return {
    exposure: clamp(p.exposure),
    brightness: clamp(p.brightness),
    contrast: clamp(p.contrast),
    saturation: clamp(p.saturation)
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
      result.initialTool = isValidEditorToolKey(tool) ? tool as EditorToolKey : 'adjust';
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
      result.initialTool = isValidEditorToolKey(tool) ? tool as EditorToolKey : 'adjust';
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
  return { luminanceAlpha, luminanceLight, contrast, saturate };
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
  { key: 'template', label: '模板' }
];

/** 调节工具下的调整类型定义。 */
export interface AdjustTypeDef {
  key: string;
  label: string;
  unit: string;
}

/** 「调节」工具内的四种调整类型。 */
export const ADJUST_TYPES: AdjustTypeDef[] = [
  { key: 'exposure', label: '曝光', unit: 'EXP' },
  { key: 'brightness', label: '亮度', unit: 'LUM' },
  { key: 'contrast', label: '对比度', unit: 'CON' },
  { key: 'saturation', label: '饱和度', unit: 'SAT' }
];
