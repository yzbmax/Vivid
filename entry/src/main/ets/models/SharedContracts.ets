/**
 * 编辑页共享契约（实施计划 §三）。
 *
 * 本文件由开发者 C 独占维护。A/B 只允许 import 本文件中的类型与纯函数，
 * 不得直接修改本文件。任何共享字段变化须三人评审后由 C 追加兼容字段。
 *
 * 契约：
 * - FilterSnapshot   滤镜状态（当前滤镜 id + 强度）。
 * - TextLayer        单个文字图层（A 创建，B 持久化，C 在快照中引用）。
 * - BorderState      边框状态（模板 id + 参数）。
 * - EditorSnapshot   完整编辑快照（含 schemaVersion，用于保存、恢复、导出）。
 *
 * 所有写入入口必须深拷贝数组与对象；非法数值在编辑会话进入时钳制；
 * 未知滤镜 / 字体 / 边框 id 使用下方安全默认值，不得因资源缺失崩溃。
 */

// ───────────────────────── 滤镜快照 ─────────────────────────

/** 当前选择的滤镜 id 与强度。strength 范围 0…1。 */
export interface FilterSnapshot {
  filterId: string;
  strength: number;
}

/** 滤镜强度下界。 */
export const FILTER_STRENGTH_MIN: number = 0;
/** 滤镜强度上界。 */
export const FILTER_STRENGTH_MAX: number = 1;

/** 钳制滤镜强度到 [0, 1]。 */
export function clampFilterStrength(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.min(FILTER_STRENGTH_MAX, Math.max(FILTER_STRENGTH_MIN, value));
}

/** 未知滤镜 id 时的安全默认（原图，强度 0）。 */
export function defaultFilterSnapshot(): FilterSnapshot {
  return { filterId: 'original', strength: 0 };
}

/** 深拷贝 FilterSnapshot。 */
export function cloneFilterSnapshot(src: FilterSnapshot): FilterSnapshot {
  return { filterId: src.filterId, strength: src.strength };
}

// ───────────────────────── 文字图层 ─────────────────────────

/** 单个文字图层。坐标为归一化中心坐标（相对照片内容区域，0…1）。 */
export interface TextLayer {
  id: string;
  /** 1–80 个 Unicode 字符，最多 3 行。 */
  content: string;
  /** 字体目录键，来自 A 的 FontCatalog。未知键由调用方回退到安全字体。 */
  fontKey: string;
  /** ARGB 颜色。 */
  colorArgb: number;
  /** 字号相对照片长边的比例，0.02…0.20。 */
  fontSizeRatio: number;
  /** 归一化中心 X，0…1，相对照片内容区域。 */
  centerX: number;
  /** 归一化中心 Y，0…1，相对照片内容区域。 */
  centerY: number;
  /** 旋转角度（度），-180…180。 */
  rotationDeg: number;
  /** 不透明度，0.30…1.00。 */
  opacity: number;
}

/** 单张作品文字图层上限。 */
export const TEXT_LAYER_MAX_COUNT: number = 8;
/** 单个文字图层字符上限。 */
export const TEXT_LAYER_MAX_CHARS: number = 80;
/** 单个文字图层最大行数。 */
export const TEXT_LAYER_MAX_LINES: number = 3;

/** 字号比例下界（照片长边的 2%）。 */
export const TEXT_FONT_SIZE_RATIO_MIN: number = 0.02;
/** 字号比例上界（照片长边的 20%）。 */
export const TEXT_FONT_SIZE_RATIO_MAX: number = 0.20;
/** 旋转角度下界（度）。 */
export const TEXT_ROTATION_MIN: number = -180;
/** 旋转角度上界（度）。 */
export const TEXT_ROTATION_MAX: number = 180;
/** 不透明度下界。 */
export const TEXT_OPACITY_MIN: number = 0.30;
/** 不透明度上界。 */
export const TEXT_OPACITY_MAX: number = 1.00;
/** 归一化坐标下界。 */
export const TEXT_COORD_MIN: number = 0;
/** 归一化坐标上界。 */
export const TEXT_COORD_MAX: number = 1;

/** 钳制字号比例。 */
export function clampFontSizeRatio(value: number): number {
  if (Number.isNaN(value)) {
    return TEXT_FONT_SIZE_RATIO_MIN;
  }
  return Math.min(TEXT_FONT_SIZE_RATIO_MAX, Math.max(TEXT_FONT_SIZE_RATIO_MIN, value));
}

/** 钳制旋转角度。 */
export function clampTextRotation(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.min(TEXT_ROTATION_MAX, Math.max(TEXT_ROTATION_MIN, value));
}

/** 钳制文字不透明度。 */
export function clampTextOpacity(value: number): number {
  if (Number.isNaN(value)) {
    return TEXT_OPACITY_MAX;
  }
  return Math.min(TEXT_OPACITY_MAX, Math.max(TEXT_OPACITY_MIN, value));
}

/** 钳制归一化坐标。 */
export function clampNormalizedCoord(value: number): number {
  if (Number.isNaN(value)) {
    return 0.5;
  }
  return Math.min(TEXT_COORD_MAX, Math.max(TEXT_COORD_MIN, value));
}

/** 截断或拒绝非法文字内容：超过 80 字符截断；空内容返回空串。 */
export function sanitizeTextContent(content: string): string {
  if (content.length === 0) {
    return '';
  }
  if (content.length > TEXT_LAYER_MAX_CHARS) {
    return content.substring(0, TEXT_LAYER_MAX_CHARS);
  }
  return content;
}

/** 深拷贝单个 TextLayer（ArkTS 不支持对象展开 { ...obj }）。 */
export function cloneTextLayer(src: TextLayer): TextLayer {
  return {
    id: src.id,
    content: src.content,
    fontKey: src.fontKey,
    colorArgb: src.colorArgb,
    fontSizeRatio: src.fontSizeRatio,
    centerX: src.centerX,
    centerY: src.centerY,
    rotationDeg: src.rotationDeg,
    opacity: src.opacity
  };
}

/** 深拷贝 TextLayer 数组。 */
export function cloneTextLayers(src: TextLayer[]): TextLayer[] {
  const out: TextLayer[] = [];
  for (let i = 0; i < src.length; i++) {
    out.push(cloneTextLayer(src[i]));
  }
  return out;
}

// ───────────────────────── 边框状态 ─────────────────────────

/** 边框状态（一张作品最多启用一款模板）。 */
export interface BorderState {
  /** 边框模板 id，未知 id 由调用方回退 'none'。 */
  templateId: string;
  /** 边宽比例，0…0.25，按照片短边计算。 */
  widthRatio: number;
  /** ARGB 颜色。 */
  colorArgb: number;
  /** 投影强度，0…1。 */
  shadowStrength: number;
}

/** 边宽比例下界。 */
export const BORDER_WIDTH_RATIO_MIN: number = 0;
/** 边宽比例上界。 */
export const BORDER_WIDTH_RATIO_MAX: number = 0.25;
/** 投影强度下界。 */
export const BORDER_SHADOW_MIN: number = 0;
/** 投影强度上界。 */
export const BORDER_SHADOW_MAX: number = 1;

/** 钳制边宽比例。 */
export function clampBorderWidthRatio(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.min(BORDER_WIDTH_RATIO_MAX, Math.max(BORDER_WIDTH_RATIO_MIN, value));
}

/** 钳制投影强度。 */
export function clampBorderShadow(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.min(BORDER_SHADOW_MAX, Math.max(BORDER_SHADOW_MIN, value));
}

/** 无装裱默认边框。 */
export function defaultBorderState(): BorderState {
  return { templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0 };
}

/** 深拷贝 BorderState。 */
export function cloneBorderState(src: BorderState): BorderState {
  return {
    templateId: src.templateId,
    widthRatio: src.widthRatio,
    colorArgb: src.colorArgb,
    shadowStrength: src.shadowStrength
  };
}

// ───────────────────────── 完整编辑快照 ─────────────────────────

/**
 * 完整编辑快照。schemaVersion 在 0.1.9 固定为 1。
 * WorkRecord.editorSnapshot 为可选字段；旧作品缺失时使用安全默认值：
 * - filter: defaultFilterSnapshot()
 * - textLayers: []
 * - border: defaultBorderState()
 */
export interface EditorSnapshot {
  schemaVersion: number;
  filter: FilterSnapshot;
  textLayers: TextLayer[];
  border: BorderState;
}

/** 0.1.9 的 schema 版本。 */
export const EDITOR_SNAPSHOT_SCHEMA_VERSION: number = 1;

/** 空作品默认快照（原图滤镜 + 空文字 + 无装裱）。 */
export function defaultEditorSnapshot(): EditorSnapshot {
  return {
    schemaVersion: EDITOR_SNAPSHOT_SCHEMA_VERSION,
    filter: defaultFilterSnapshot(),
    textLayers: [],
    border: defaultBorderState()
  };
}

/** 深拷贝 EditorSnapshot（数组与子对象全部独立）。 */
export function cloneEditorSnapshot(src: EditorSnapshot): EditorSnapshot {
  return {
    schemaVersion: src.schemaVersion,
    filter: cloneFilterSnapshot(src.filter),
    textLayers: cloneTextLayers(src.textLayers),
    border: cloneBorderState(src.border)
  };
}
