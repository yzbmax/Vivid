import { AdjustParams, RegionAdjustments, createDefaultRegionAdjustments } from './EditModels';

/**
 * 作品状态：已封缄（已保存）/ 草稿 / 数据损坏。
 */
export enum WorkStatus {
  Sealed = 'sealed',
  Draft = 'draft',
  Damaged = 'damaged'
}

/**
 * 本地作品记录（《项目结构》§四 WorkRecord 的作品页展示投影）。
 *
 * mock 阶段 previewImage 以媒体资源占位；接入 WorkRepository 后，
 * 应替换为 previewImageRef 对应的可展示引用（PixelMap / Resource / 文件 uri）。
 */
export class WorkRecord {
  /** 作品唯一标识（mock 使用卷宗编号样式，如 0409-A） */
  id: string = '';
  /** 作品标题 */
  title: string = '';
  /** 自动生成或手动编辑的作品描述（案卷批注） */
  description: string = '';
  /** 作品页缩略图 */
  previewImage: Resource | null = null;
  /** 保存时间展示文案 */
  date: string = '';
  /** 浮印字（甲/乙/丙…） */
  sealGlyph: string = '';
  status: WorkStatus = WorkStatus.Sealed;
  createdAt: number = 0;
  updatedAt: number = 0;
  /** 原始图片 URI；内置 Resource 样例允许为空 */
  sourceImageUri: string = '';
  /** 缩略图本地 URI（预览用） */
  previewImageUri: string = '';
  /** 导出到相册后的媒体 URI */
  exportedAssetUri: string = '';
  /** 最后使用的编辑工具 */
  lastTool: string = 'adjust';
  /** 原始图片宽度；未知时为 0 */
  width: number = 0;
  /** 原始图片高度；未知时为 0 */
  height: number = 0;
  /** 保存时的调色参数快照 */
  adjustments: AdjustParams = {
    exposure: 0,
    brightness: 0,
    contrast: 0,
    saturation: 0,
    temperature: 0
  };
  /** V2 新增：双区域调色参数（主体/背景各自独立） */
  regionAdjustments: RegionAdjustments = createDefaultRegionAdjustments();
}
