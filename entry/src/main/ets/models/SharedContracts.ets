/**
 * Vivid 0.1.9 共享契约与统一编辑快照（SharedContracts）
 *
 * 依据：《Vivid_0.1.9更新计划》§3.1
 * 约束：公开接口冻结，不可删除或重命名字段；所有写入必须使用深拷贝。
 */

export interface FilterSnapshot {
  filterId: string;
  strength: number;
}

export interface TextLayer {
  id: string;
  content: string;
  fontKey: string;
  colorArgb: number;
  fontSizeRatio: number;
  centerX: number;
  centerY: number;
  rotationDeg: number;
  opacity: number;
}

export interface BorderState {
  templateId: string;
  widthRatio: number;
  colorArgb: number;
  shadowStrength: number;
}

export interface EditorSnapshot {
  schemaVersion: number;
  filter: FilterSnapshot;
  textLayers: TextLayer[];
  border: BorderState;
}

/** 创建默认滤镜快照 */
export function createDefaultFilterSnapshot(): FilterSnapshot {
  return {
    filterId: 'original',
    strength: 0
  };
}

/** 创建默认边框状态 */
export function createDefaultBorderState(): BorderState {
  return {
    templateId: 'none',
    widthRatio: 0,
    colorArgb: 0xFFFFFFFF,
    shadowStrength: 0
  };
}

/** 创建默认统一编辑快照 (schemaVersion = 1) */
export function createDefaultEditorSnapshot(): EditorSnapshot {
  return {
    schemaVersion: 1,
    filter: createDefaultFilterSnapshot(),
    textLayers: [],
    border: createDefaultBorderState()
  };
}

/** 深拷贝滤镜快照 */
export function cloneFilterSnapshot(filter?: FilterSnapshot | null): FilterSnapshot {
  if (!filter) {
    return createDefaultFilterSnapshot();
  }
  return {
    filterId: filter.filterId ?? 'original',
    strength: typeof filter.strength === 'number' && !isNaN(filter.strength)
      ? Math.max(0, Math.min(1, filter.strength))
      : 0
  };
}

/** 深拷贝单个文字图层 */
export function cloneTextLayer(layer: TextLayer): TextLayer {
  return {
    id: layer.id ?? '',
    content: layer.content ?? '',
    fontKey: layer.fontKey ?? 'system_sans',
    colorArgb: typeof layer.colorArgb === 'number' ? layer.colorArgb : 0xFF241918,
    fontSizeRatio: typeof layer.fontSizeRatio === 'number' && !isNaN(layer.fontSizeRatio)
      ? Math.max(0.02, Math.min(0.20, layer.fontSizeRatio))
      : 0.06,
    centerX: typeof layer.centerX === 'number' && !isNaN(layer.centerX)
      ? Math.max(0, Math.min(1, layer.centerX))
      : 0.5,
    centerY: typeof layer.centerY === 'number' && !isNaN(layer.centerY)
      ? Math.max(0, Math.min(1, layer.centerY))
      : 0.5,
    rotationDeg: typeof layer.rotationDeg === 'number' && !isNaN(layer.rotationDeg)
      ? Math.max(-180, Math.min(180, layer.rotationDeg))
      : 0,
    opacity: typeof layer.opacity === 'number' && !isNaN(layer.opacity)
      ? Math.max(0.3, Math.min(1, layer.opacity))
      : 1
  };
}

/** 深拷贝文字图层列表（上限 8 层） */
export function cloneTextLayers(layers?: TextLayer[] | null): TextLayer[] {
  if (!layers || !Array.isArray(layers)) {
    return [];
  }
  return layers.slice(0, 8).map((layer: TextLayer) => cloneTextLayer(layer));
}

/** 深拷贝边框状态 */
export function cloneBorderState(border?: BorderState | null): BorderState {
  if (!border) {
    return createDefaultBorderState();
  }
  return {
    templateId: border.templateId ?? 'none',
    widthRatio: typeof border.widthRatio === 'number' && !isNaN(border.widthRatio)
      ? Math.max(0, Math.min(0.25, border.widthRatio))
      : 0,
    colorArgb: typeof border.colorArgb === 'number' ? border.colorArgb : 0xFFFFFFFF,
    shadowStrength: typeof border.shadowStrength === 'number' && !isNaN(border.shadowStrength)
      ? Math.max(0, Math.min(1, border.shadowStrength))
      : 0
  };
}

/** 深拷贝统一编辑快照 */
export function cloneEditorSnapshot(snapshot?: EditorSnapshot | null): EditorSnapshot {
  if (!snapshot) {
    return createDefaultEditorSnapshot();
  }
  return {
    schemaVersion: snapshot.schemaVersion === 1 ? 1 : 1,
    filter: cloneFilterSnapshot(snapshot.filter),
    textLayers: cloneTextLayers(snapshot.textLayers),
    border: cloneBorderState(snapshot.border)
  };
}
