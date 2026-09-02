/**
 * 边框模板目录（实施计划 §2.3）。
 *
 * 本文件只声明元数据和能力（哪些参数可调节），不包含渲染逻辑；
 * 渲染几何由 BorderLayoutResolver 统一计算。
 *
 * 模板 id 与 SharedContracts.ets 的 BorderState.templateId 对应；
 * 未知 id 在调用方回退到 `none`，本目录不抛异常。
 */

/** 边框能力键：标识某个参数是否可被用户调节。 */
export type BorderCapability = 'width' | 'color' | 'shadow';

/** 单个边框模板的元数据。 */
export interface BorderTemplate {
  /** 稳定 id，与 BorderState.templateId 一致。 */
  templateId: string;
  /** 用户可见名称。 */
  name: string;
  /** 该模板支持调节的参数集合。 */
  capabilities: BorderCapability[];
  /** 预览 SVG 资源；`none` 为 null。 */
  previewResource: Resource | null;
}

/** 校验模板 id 是否已注册。 */
export function isBorderTemplateRegistered(templateId: string): boolean {
  for (let i = 0; i < BORDER_TEMPLATES.length; i++) {
    if (BORDER_TEMPLATES[i].templateId === templateId) {
      return true;
    }
  }
  return false;
}

/** 根据 id 查找模板；未找到返回 null。 */
export function findBorderTemplate(templateId: string): BorderTemplate | null {
  for (let i = 0; i < BORDER_TEMPLATES.length; i++) {
    if (BORDER_TEMPLATES[i].templateId === templateId) {
      return BORDER_TEMPLATES[i];
    }
  }
  return null;
}

/** 查询某模板是否支持指定能力。 */
export function templateSupportsCapability(
  templateId: string,
  capability: BorderCapability
): boolean {
  const tpl = findBorderTemplate(templateId);
  if (tpl === null) {
    return false;
  }
  for (let i = 0; i < tpl.capabilities.length; i++) {
    if (tpl.capabilities[i] === capability) {
      return true;
    }
  }
  return false;
}

/**
 * 边框模板目录（7 项，`none` 必须为首项）。
 * 预览 SVG 资源由任务 6 的 BorderPanel 消费；此处只持有引用。
 */
export const BORDER_TEMPLATES: BorderTemplate[] = [
  {
    templateId: 'none',
    name: '无装裱',
    capabilities: [],
    previewResource: null
  },
  {
    templateId: 'paper_white',
    name: '宣纸留白',
    capabilities: ['width', 'color'],
    previewResource: null // 任务 6 接入 SVG
  },
  {
    templateId: 'ink_black',
    name: '墨框',
    capabilities: ['width', 'color'],
    previewResource: null
  },
  {
    templateId: 'floating_shadow',
    name: '浮光卡片',
    capabilities: ['width', 'color', 'shadow'],
    previewResource: null
  },
  {
    templateId: 'film_negative',
    name: '胶片边框',
    capabilities: ['width'],
    previewResource: null
  },
  {
    templateId: 'polaroid',
    name: '拍立得',
    capabilities: ['width'],
    previewResource: null
  },
  {
    templateId: 'scroll_mount',
    name: '卷轴装裱',
    capabilities: ['width', 'color', 'shadow'],
    previewResource: null
  }
];
