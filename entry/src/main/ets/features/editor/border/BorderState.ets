/**
 * 边框状态纯函数（实施计划 §三 / §五 任务 5）。
 *
 * 纯逻辑模块，无 ArkUI 依赖。所有写入必须经本模块的钳制与归一化。
 * SharedContracts.ets 提供基础 clamp 与 clone；本模块在此基础上增加：
 * - 未知 templateId 归一化到 `none`
 * - 模板不支持的参数被强制回退到安全默认值（而不是静默保留用户输入）
 * - 状态比较（浅比较，用于判断是否需要重渲染）
 */

import {
  BorderState,
  clampBorderRadiusRatio,
  clampBorderShadow,
  clampBorderWidthRatio,
  cloneBorderState,
  defaultBorderState,
  cloneWatermarkConfig,
  defaultWatermarkConfig
} from '../../../models/SharedContracts';
import {
  findBorderTemplate,
  templateSupportsCapability,
  isWatermarkTemplate
} from './BorderCatalog';

/** 未知 templateId 时的归一化目标。 */
export const BORDER_FALLBACK_TEMPLATE_ID: string = 'none';

/** 纸白默认色（白色，ARGB）。 */
export const BORDER_DEFAULT_COLOR_PAPER_WHITE: number = 0xFFFFFFFF;
/** 墨色默认色（近黑，ARGB）。 */
export const BORDER_DEFAULT_COLOR_INK: number = 0xFF1A1A1A;
/** 拍立得相纸色（乳白，ARGB）。 */
export const BORDER_DEFAULT_COLOR_POLAROID: number = 0xFFF5F2E8;

/**
 * 把未知 templateId 归一化到已注册模板；
 * 未注册时返回 `none`，不抛异常，保证旧数据不崩溃。
 */
export function normalizeBorderTemplateId(templateId: string): string {
  if (templateId === '') {
    return BORDER_FALLBACK_TEMPLATE_ID;
  }
  if (findBorderTemplate(templateId) !== null) {
    return templateId;
  }
  return BORDER_FALLBACK_TEMPLATE_ID;
}

/**
 * 按模板能力强制钳制一个 BorderState：
 * - 未知 id → `none`
 * - widthRatio 始终钳制到 [0, 0.25]
 * - 模板不支持 color 时 → 回退到该模板的默认色
 * - 模板不支持 shadow 时 → shadowStrength 强制 0
 * - 模板不支持 radius 时 → radiusRatio 强制 0
 *
 * 该函数保证任何输入都得到可被渲染器安全消费的合法状态。
 */
export function sanitizeBorderState(raw: BorderState): BorderState {
  const templateId = normalizeBorderTemplateId(raw.templateId);
  const widthRatio = clampBorderWidthRatio(raw.widthRatio);
  let colorArgb = raw.colorArgb;
  let shadowStrength = clampBorderShadow(raw.shadowStrength);
  let radiusRatio = clampBorderRadiusRatio(raw.radiusRatio ?? 0);

  if (!templateSupportsCapability(templateId, 'color')) {
    colorArgb = defaultColorForTemplate(templateId);
  }
  if (!templateSupportsCapability(templateId, 'shadow')) {
    shadowStrength = 0;
  }
  if (!templateSupportsCapability(templateId, 'radius')) {
    radiusRatio = 0;
  }
  if (templateId === BORDER_FALLBACK_TEMPLATE_ID) {
    // `none` 模板：所有装饰参数强制归零
    return {
      templateId: BORDER_FALLBACK_TEMPLATE_ID,
      widthRatio: 0,
      colorArgb: BORDER_DEFAULT_COLOR_PAPER_WHITE,
      shadowStrength: 0,
      radiusRatio: 0
    };
  }
  const watermark = isWatermarkTemplate(templateId)
    ? (raw.watermark ? cloneWatermarkConfig(raw.watermark) : defaultWatermarkConfig())
    : (raw.watermark ? cloneWatermarkConfig(raw.watermark) : undefined);

  return { templateId, widthRatio, colorArgb, shadowStrength, radiusRatio, watermark };
}

/** 模板不支持 color 时的默认色（按模板 id 返回合理的固定色）。 */
export function defaultColorForTemplate(templateId: string): number {
  if (templateId === 'ink_black' || templateId === 'film_negative' || templateId === 'watermark_cinematic' ||
      templateId === 'watermark_editorial_mag' || templateId === 'watermark_contact_sheet' ||
      templateId === 'watermark_leather_badge') {
    return BORDER_DEFAULT_COLOR_INK;
  }
  if (templateId === 'polaroid' || templateId === 'watermark_retro_film') {
    return BORDER_DEFAULT_COLOR_POLAROID;
  }
  if (templateId === 'watermark_oriental_seal') {
    return 0xFFF7F4EB;
  }
  if (templateId === 'watermark_travel_postcard') {
    return 0xFFE4ECF0;
  }
  if (templateId === 'watermark_travel_stamp') {
    return 0xFFFBFBF9;
  }
  if (templateId === 'watermark_mint_film') {
    return 0xFFA3E4D7;
  }
  // paper_white / floating_shadow / scroll_mount / camera_watermark / watermark_master_grid / watermark_blur_pip / watermark_overlay / watermark_nordic_gallery / watermark_gradient_frame / watermark_slim_white 默认纸白
  return BORDER_DEFAULT_COLOR_PAPER_WHITE;
}

/** 浅比较两个 BorderState 是否相等（用于跳过不必要的重渲染）。 */
export function borderStateEquals(a: BorderState, b: BorderState): boolean {
  const baseEqual = a.templateId === b.templateId &&
    a.widthRatio === b.widthRatio &&
    a.colorArgb === b.colorArgb &&
    a.shadowStrength === b.shadowStrength &&
    (a.radiusRatio ?? 0) === (b.radiusRatio ?? 0);
  if (!baseEqual) {
    return false;
  }
  if (!a.watermark && !b.watermark) {
    return true;
  }
  if (!a.watermark || !b.watermark) {
    return false;
  }
  return a.watermark.showDevice === b.watermark.showDevice &&
    a.watermark.deviceModel === b.watermark.deviceModel &&
    a.watermark.showLogo === b.watermark.showLogo &&
    a.watermark.logo === b.watermark.logo &&
    a.watermark.showParams === b.watermark.showParams &&
    a.watermark.paramsText === b.watermark.paramsText &&
    a.watermark.showTime === b.watermark.showTime &&
    a.watermark.timeText === b.watermark.timeText;
}

/**
 * 选择新边框模板时保留用户已调参数（仅当新模板支持该能力时）；
 * 不支持的能力回退到安全默认值。
 */
export function switchBorderTemplate(
  current: BorderState,
  nextTemplateId: string
): BorderState {
  const candidate: BorderState = {
    templateId: nextTemplateId,
    widthRatio: current.widthRatio > 0 ? current.widthRatio : 0.08,
    colorArgb: current.templateId === 'none' || current.colorArgb === defaultColorForTemplate(current.templateId)
      ? defaultColorForTemplate(nextTemplateId) : current.colorArgb,
    shadowStrength: templateSupportsCapability(current.templateId, 'shadow') ? current.shadowStrength : 0.35,
    radiusRatio: templateSupportsCapability(nextTemplateId, 'radius') ? (current.radiusRatio ?? 0) : 0,
    watermark: isWatermarkTemplate(nextTemplateId)
      ? (current.watermark ? cloneWatermarkConfig(current.watermark) : defaultWatermarkConfig())
      : current.watermark
  };
  return sanitizeBorderState(candidate);
}

/**
 * 从旧版本 BorderState 迁移到当前 schema。
 * 0.1.9 没有历史数据，但预留迁移入口供未来版本使用。
 * 旧 `template` 字符串归一化为 `border` 在 EditorToolKey 层面处理，
 * 此处只关心 BorderState 自身的字段兼容。
 */
export function migrateBorderState(raw: BorderState | null): BorderState {
  if (raw === null) {
    return defaultBorderState();
  }
  return sanitizeBorderState(cloneBorderState(raw));
}
