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
 */

import { WorkRecord } from './WorkRecord';

/** 进入编辑页的来源：首页选图 或 作品续编。 */
export enum EditEntrySource {
  Picker = 'picker',
  Work = 'work'
}

/** EditPage 路由参数契约：B 经 pushUrl params 传入，C 在 aboutToAppear 解析。 */
export interface EditRouteParams {
  source: EditEntrySource;
  imageUri?: string;
  workId?: string;
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

/** 由路由 getParams() 原始对象解析编辑页入参；source 缺失或非法时返回 null。 */
export function parseEditRouteParams(raw: Record<string, string>): EditRouteParams | null {
  if (raw['source'] === EditEntrySource.Picker) {
    return { source: EditEntrySource.Picker, imageUri: raw['imageUri'] ?? '' };
  }
  if (raw['source'] === EditEntrySource.Work) {
    return { source: EditEntrySource.Work, workId: raw['workId'] ?? '' };
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
