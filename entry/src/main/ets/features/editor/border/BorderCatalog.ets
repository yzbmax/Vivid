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
export type BorderCapability = 'width' | 'color' | 'shadow' | 'radius';

/** 模版大分类（全屏模版库分类筛选） */
export type BorderCategory = 'all' | 'watermark' | 'brand' | 'travel' | 'vintage' | 'framing';

export interface BorderCategoryInfo {
  id: BorderCategory;
  name: string;
}

export const BORDER_CATEGORIES: BorderCategoryInfo[] = [
  { id: 'all', name: '全部' },
  { id: 'watermark', name: '经典水印' },
  { id: 'brand', name: '品牌大师' },
  { id: 'travel', name: '旅拍打卡' },
  { id: 'vintage', name: '复古胶片' },
  { id: 'framing', name: '艺术装裱' }
];

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
  /** 分类类别 */
  category: BorderCategory;
  /** 简要描述 */
  description?: string;
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

/** 判断是否属于相机水印类装裱模板 */
export function isWatermarkTemplate(templateId: string): boolean {
  return templateId === 'camera_watermark' ||
    templateId === 'watermark_master_grid' ||
    templateId === 'watermark_blur_pip' ||
    templateId === 'watermark_cinematic' ||
    templateId === 'watermark_retro_film' ||
    templateId === 'watermark_overlay' ||
    templateId === 'watermark_nordic_gallery' ||
    templateId === 'watermark_editorial_mag' ||
    templateId === 'watermark_contact_sheet' ||
    templateId === 'watermark_oriental_seal' ||
    templateId === 'watermark_travel_stamp' ||
    templateId === 'watermark_travel_postcard' ||
    templateId === 'watermark_gradient_frame' ||
    templateId === 'watermark_leather_badge' ||
    templateId === 'watermark_mint_film' ||
    templateId === 'watermark_slim_white';
}

/**
 * 边框模板目录（`none` 必须为首项，相机水印系列优先展示）。
 */
export const BORDER_TEMPLATES: BorderTemplate[] = [
  {
    templateId: 'none',
    name: '无装裱',
    capabilities: [],
    previewResource: null,
    category: 'framing',
    description: '保持原片纯粹画幅'
  },
  {
    templateId: 'camera_watermark',
    name: '相机水印',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'watermark',
    description: '经典机型与参数双向排版'
  },
  {
    templateId: 'watermark_master_grid',
    name: '影展矩阵',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'watermark',
    description: '四栏专业参数矩阵与签名'
  },
  {
    templateId: 'watermark_blur_pip',
    name: '画中画虚化',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'watermark',
    description: '原图同色弥散虚化背景'
  },
  {
    templateId: 'watermark_travel_stamp',
    name: '齿孔邮票',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'travel',
    description: '经典邮票连续齿孔打卡'
  },
  {
    templateId: 'watermark_travel_postcard',
    name: '旅行明信片',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'travel',
    description: '复古双圈航空邮戳信片'
  },
  {
    templateId: 'watermark_gradient_frame',
    name: '幻彩双色框',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'brand',
    description: '青蓝暖橙双色线性渐变线'
  },
  {
    templateId: 'watermark_leather_badge',
    name: '皮革彩虹标',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'vintage',
    description: '碳黑皮革质感与彩虹徽章'
  },
  {
    templateId: 'watermark_mint_film',
    name: '清新薄荷绿',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'vintage',
    description: '治愈系薄荷绿胶片相机框'
  },
  {
    templateId: 'watermark_slim_white',
    name: '极简细白条',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'brand',
    description: '超窄精巧现代画廊细栏'
  },
  {
    templateId: 'watermark_nordic_gallery',
    name: '北欧画廊',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'brand',
    description: '哈苏极简留白与暖橙焦点'
  },
  {
    templateId: 'watermark_editorial_mag',
    name: '纪实画报',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'brand',
    description: '国家地理明黄细线与经纬度'
  },
  {
    templateId: 'watermark_cinematic',
    name: '电影影集',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'brand',
    description: '宽银幕电影题签与等宽参数'
  },
  {
    templateId: 'watermark_contact_sheet',
    name: '暗房印样',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'vintage',
    description: '柯达金字接触印相安全角标'
  },
  {
    templateId: 'watermark_oriental_seal',
    name: '文书印章',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'travel',
    description: '宣纸朱砂双内框与金石印章'
  },
  {
    templateId: 'watermark_retro_film',
    name: '复古胶片',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'vintage',
    description: '经典拍立得温润相纸质感'
  },
  {
    templateId: 'watermark_overlay',
    name: '无界悬浮',
    capabilities: [],
    previewResource: null,
    category: 'watermark',
    description: '零画幅外扩防撞色水印'
  },
  {
    templateId: 'paper_white',
    name: '宣纸留白',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'framing',
    description: '均匀典雅文人留白框'
  },
  {
    templateId: 'ink_black',
    name: '墨框',
    capabilities: ['width', 'color', 'radius'],
    previewResource: null,
    category: 'framing',
    description: '沉稳黑曜石卡纸包边'
  },
  {
    templateId: 'floating_shadow',
    name: '浮光卡片',
    capabilities: ['width', 'color', 'shadow', 'radius'],
    previewResource: null,
    category: 'framing',
    description: '轻盈立体展墙悬浮投影'
  },
  {
    templateId: 'film_negative',
    name: '胶片齿孔',
    capabilities: ['width'],
    previewResource: null,
    category: 'vintage',
    description: '135 胶卷真齿孔底片编号'
  },
  {
    templateId: 'polaroid',
    name: '拍立得',
    capabilities: ['width', 'radius'],
    previewResource: null,
    category: 'vintage',
    description: '经典大下巴拍立得相纸'
  },
  {
    templateId: 'scroll_mount',
    name: '卷轴装裱',
    capabilities: ['width', 'color', 'shadow', 'radius'],
    previewResource: null,
    category: 'framing',
    description: '东方文书角标回纹装裱'
  }
];
