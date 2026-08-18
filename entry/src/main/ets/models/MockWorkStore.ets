import { WorkRecord, WorkStatus } from './WorkRecord';
import { buildMockWorks } from './MockWorks';

/**
 * 作品 Mock Store：管理作品列表的增删改查。
 *
 * 首次调用 init() 时加载 MockWorks 的 6 条静态数据作为种子；
 * 后续 create / update 在进程内生效，不跨重启持久化。
 *
 * 方法命名：list / findById / create / update（开发者 C 统一使用）。
 */
export class MockWorkStore {
  private works: WorkRecord[] = [];
  private initialized: boolean = false;

  /** 初始化：首次调用时加载种子数据，重复调用安全跳过 */
  init(): void {
    if (this.initialized) {
      return;
    }
    this.works = buildMockWorks();
    this.initialized = true;
  }

  /** 返回全部作品（按 updatedAt 倒序），返回副本防止外部修改内部数组 */
  list(): WorkRecord[] {
    return this.works.slice().sort((a: WorkRecord, b: WorkRecord) =>
      b.updatedAt - a.updatedAt
    );
  }

  /** 按 ID 查找单个作品；不存在时返回 null */
  findById(id: string): WorkRecord | null {
    return this.works.find((w: WorkRecord) => w.id === id) ?? null;
  }

  /**
   * 新建作品：生成 MOCK-{timestamp} ID，设置 createdAt / updatedAt，
   * 加入列表并返回新记录。
   */
  create(record: WorkRecord): WorkRecord {
    const now = Date.now();
    record.id = 'MOCK-' + now;
    record.createdAt = now;
    record.updatedAt = now;
    if (!record.status) {
      record.status = WorkStatus.Draft;
    }
    this.works.push(record);
    return record;
  }

  /**
   * 更新作品：按 ID 匹配，合并传入的字段，刷新 updatedAt。
   * 匹配不到时返回 null，不修改列表。
   */
  update(record: WorkRecord): WorkRecord | null {
    const index = this.works.findIndex((w: WorkRecord) => w.id === record.id);
    if (index < 0) {
      return null;
    }
    const existing = this.works[index];
    // 合并字段（保留已有值，用传入值覆盖）
    if (record.title.length > 0) {
      existing.title = record.title;
    }
    if (record.sourceImageUri.length > 0) {
      existing.sourceImageUri = record.sourceImageUri;
    }
    if (record.width > 0) {
      existing.width = record.width;
    }
    if (record.height > 0) {
      existing.height = record.height;
    }
    if (record.previewImage !== null) {
      existing.previewImage = record.previewImage;
    }
    if (record.sealGlyph.length > 0) {
      existing.sealGlyph = record.sealGlyph;
    }
    if (record.date.length > 0) {
      existing.date = record.date;
    }
    existing.status = record.status;
    existing.adjustments = {
      exposure: record.adjustments.exposure,
      brightness: record.adjustments.brightness,
      contrast: record.adjustments.contrast,
      saturation: record.adjustments.saturation
    };
    existing.updatedAt = Date.now();
    return existing;
  }
}

/** 导出单例，全应用共享同一份作品数据 */
export const mockWorkStore = new MockWorkStore();
