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
  /** 作品页缩略图 */
  previewImage: Resource | null = null;
  /** 保存时间展示文案 */
  date: string = '';
  /** 浮印字（甲/乙/丙…） */
  sealGlyph: string = '';
  status: WorkStatus = WorkStatus.Sealed;
  createdAt: number = 0;
  updatedAt: number = 0;
}
