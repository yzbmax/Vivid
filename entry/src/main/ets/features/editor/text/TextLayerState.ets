import {
  TextLayer,
  TEXT_LAYER_MAX_COUNT,
  TEXT_LAYER_MAX_CHARS,
  TEXT_LAYER_MAX_LINES,
  clampFontSizeRatio,
  clampNormalizedCoord,
  clampTextOpacity,
  clampTextRotation,
  cloneTextLayer,
  cloneTextLayers
} from '../../../models/SharedContracts';
import { resolveFontKey, resolveTextColor, TEXT_COLOR_PALETTE } from './FontCatalog';

export interface TextValidationResult {
  valid: boolean;
  error: string;
}

export interface TextLayerPatch {
  content?: string;
  fontKey?: string;
  colorArgb?: number;
  fontSizeRatio?: number;
  centerX?: number;
  centerY?: number;
  rotationDeg?: number;
  opacity?: number;
}

export interface TextLayerMutationResult {
  layers: TextLayer[];
  selectedId: string | null;
  error: string;
}

function unicodeLength(value: string): number {
  let count = 0;
  for (let i = 0; i < value.length; i++) {
    const code = value.charCodeAt(i);
    if (code >= 0xD800 && code <= 0xDBFF && i + 1 < value.length) {
      const next = value.charCodeAt(i + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        i++;
      }
    }
    count++;
  }
  return count;
}

export function validateTextContent(content: string): TextValidationResult {
  if (content.trim().length === 0) {
    return { valid: false, error: '题签内容不能为空' };
  }
  if (unicodeLength(content) > TEXT_LAYER_MAX_CHARS) {
    return { valid: false, error: '题签内容不能超过 ' + TEXT_LAYER_MAX_CHARS + ' 个字符' };
  }
  if (content.split(/\r\n|\r|\n/).length > TEXT_LAYER_MAX_LINES) {
    return { valid: false, error: '题签内容不能超过 ' + TEXT_LAYER_MAX_LINES + ' 行' };
  }
  return { valid: true, error: '' };
}

export function createDefaultTextLayer(id: string, content: string = ''): TextLayer {
  return {
    id: id,
    content: content,
    fontKey: 'system_sans',
    colorArgb: TEXT_COLOR_PALETTE[0],
    fontSizeRatio: 0.06,
    centerX: 0.5,
    centerY: 0.5,
    rotationDeg: 0,
    opacity: 1
  };
}

function hasId(layers: TextLayer[], id: string): boolean {
  for (let i = 0; i < layers.length; i++) {
    if (layers[i].id === id) {
      return true;
    }
  }
  return false;
}

function copyLayers(layers: TextLayer[]): TextLayer[] {
  return cloneTextLayers(layers);
}

function result(layers: TextLayer[], selectedId: string | null, error: string): TextLayerMutationResult {
  return { layers: layers, selectedId: selectedId, error: error };
}

export function addTextLayer(
  layers: TextLayer[],
  content: string,
  id: string
): TextLayerMutationResult {
  const safeLayers = copyLayers(layers);
  const validation = validateTextContent(content);
  if (!validation.valid) {
    return result(safeLayers, null, validation.error);
  }
  if (safeLayers.length >= TEXT_LAYER_MAX_COUNT) {
    return result(safeLayers, null, '最多添加 8 个题签');
  }
  if (id.trim().length === 0) {
    return result(safeLayers, null, '题签 ID 不能为空');
  }
  if (hasId(safeLayers, id)) {
    return result(safeLayers, null, '题签 ID 已存在');
  }
  safeLayers.push(createDefaultTextLayer(id, content));
  return result(safeLayers, id, '');
}

export function normalizeTextLayer(layer: TextLayer): TextLayer {
  const copy = cloneTextLayer(layer);
  copy.fontKey = resolveFontKey(copy.fontKey);
  copy.colorArgb = resolveTextColor(copy.colorArgb);
  copy.fontSizeRatio = clampFontSizeRatio(copy.fontSizeRatio);
  copy.centerX = clampNormalizedCoord(copy.centerX);
  copy.centerY = clampNormalizedCoord(copy.centerY);
  copy.rotationDeg = clampTextRotation(copy.rotationDeg);
  copy.opacity = clampTextOpacity(copy.opacity);
  return copy;
}

export function updateTextLayer(
  layers: TextLayer[],
  id: string,
  patch: TextLayerPatch
): TextLayerMutationResult {
  const safeLayers = copyLayers(layers);
  let found = false;
  for (let i = 0; i < safeLayers.length; i++) {
    if (safeLayers[i].id !== id) {
      continue;
    }
    found = true;
    const next = normalizeTextLayer(safeLayers[i]);
    if (patch.content !== undefined) {
      const validation = validateTextContent(patch.content);
      if (!validation.valid) {
        return result(safeLayers, id, validation.error);
      }
      next.content = patch.content;
    }
    if (patch.fontKey !== undefined) {
      next.fontKey = resolveFontKey(patch.fontKey);
    }
    if (patch.colorArgb !== undefined) {
      next.colorArgb = resolveTextColor(patch.colorArgb);
    }
    if (patch.fontSizeRatio !== undefined) {
      next.fontSizeRatio = clampFontSizeRatio(patch.fontSizeRatio);
    }
    if (patch.centerX !== undefined) {
      next.centerX = clampNormalizedCoord(patch.centerX);
    }
    if (patch.centerY !== undefined) {
      next.centerY = clampNormalizedCoord(patch.centerY);
    }
    if (patch.rotationDeg !== undefined) {
      next.rotationDeg = clampTextRotation(patch.rotationDeg);
    }
    if (patch.opacity !== undefined) {
      next.opacity = clampTextOpacity(patch.opacity);
    }
    safeLayers[i] = next;
  }
  return found ? result(safeLayers, id, '') : result(safeLayers, null, '未找到题签');
}

export function selectTextLayer(layers: TextLayer[], id: string): string | null {
  return hasId(layers, id) ? id : null;
}

/** 输入与保存共用同一条写入路径；首次有效输入创建图层，后续输入只更新该层。 */
export function applyTextInput(
  layers: TextLayer[], selectedId: string, content: string, newId: string
): TextLayerMutationResult {
  return selectedId === '' ? addTextLayer(layers, content, newId)
    : updateTextLayer(layers, selectedId, { content: content });
}

export function deleteTextLayer(
  layers: TextLayer[],
  id: string,
  selectedId: string | null
): TextLayerMutationResult {
  const safeLayers = copyLayers(layers);
  let index = -1;
  for (let i = 0; i < safeLayers.length; i++) {
    if (safeLayers[i].id === id) {
      index = i;
      break;
    }
  }
  if (index < 0) {
    return result(safeLayers, selectTextLayer(safeLayers, selectedId ?? ''), '未找到题签');
  }
  safeLayers.splice(index, 1);
  let nextSelected: string | null = selectTextLayer(safeLayers, selectedId ?? '');
  if (selectedId === id) {
    if (index < safeLayers.length) {
      nextSelected = safeLayers[index].id;
    } else if (safeLayers.length > 0) {
      nextSelected = safeLayers[safeLayers.length - 1].id;
    } else {
      nextSelected = null;
    }
  }
  return result(safeLayers, nextSelected, '');
}

export const removeTextLayer = deleteTextLayer;
