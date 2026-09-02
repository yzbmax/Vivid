import { WorkRecord, WorkStatus } from './WorkRecord';
import { buildMockWorks } from './MockWorks';
import { cloneRegionAdjustments } from './EditModels';
import { cloneEditorSnapshot, createDefaultEditorSnapshot } from './SharedContracts';

/**
 * 作品 Mock Store：管理作品列表的增删改查。
 *
 * 首次调用 init() 时加载 MockWorks 的种子数据（当前为空）；
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
    ).map((w: WorkRecord) => {
      if (w.lastTool === 'template') {
        w.lastTool = 'border';
      }
      if (!w.editorSnapshot) {
        w.editorSnapshot = createDefaultEditorSnapshot();
      }
      return w;
    });
  }

  /** 按 ID 查找单个作品；不存在时返回 null */
  findById(id: string): WorkRecord | null {
    const work = this.works.find((w: WorkRecord) => w.id === id);
    if (!work) {
      return null;
    }
    if (work.lastTool === 'template') {
      work.lastTool = 'border';
    }
    if (!work.editorSnapshot) {
      work.editorSnapshot = createDefaultEditorSnapshot();
    }
    return work;
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
    if (record.lastTool === 'template') {
      record.lastTool = 'border';
    }
    record.editorSnapshot = cloneEditorSnapshot(record.editorSnapshot);
    this.works.push(record);
    return record;
  }

  /**
   * 更新作品：按 ID 匹配，合并传入的字段，刷新 updatedAt。
   * 匹配不到时抛出异常，不修改列表。
   */
  update(id: string, patch: WorkRecord): WorkRecord {
    const index = this.works.findIndex((w: WorkRecord) => w.id === id);
    if (index < 0) {
      throw new Error(`Work not found: ${id}`);
    }
    const existing = this.works[index];
    // 合并字段（保留已有值，用传入值覆盖）
    if (patch.title.length > 0) {
      existing.title = patch.title;
    }
    if (patch.sourceImageUri.length > 0) {
      existing.sourceImageUri = patch.sourceImageUri;
    }
    if (patch.width > 0) {
      existing.width = patch.width;
    }
    if (patch.height > 0) {
      existing.height = patch.height;
    }
    if (patch.previewImage !== null) {
      existing.previewImage = patch.previewImage;
    }
    if (patch.sealGlyph.length > 0) {
      existing.sealGlyph = patch.sealGlyph;
    }
    if (patch.date.length > 0) {
      existing.date = patch.date;
    }
    if (patch.previewImageUri.length > 0) {
      existing.previewImageUri = patch.previewImageUri;
    }
    if (patch.exportedAssetUri.length > 0) {
      existing.exportedAssetUri = patch.exportedAssetUri;
    }
    if (patch.lastTool.length > 0) {
      existing.lastTool = patch.lastTool === 'template' ? 'border' : patch.lastTool;
    }
    if (patch.description.length > 0) {
      existing.description = patch.description;
    }
    existing.status = patch.status;
    existing.adjustments = {
      exposure: patch.adjustments.exposure,
      brightness: patch.adjustments.brightness,
      contrast: patch.adjustments.contrast,
      saturation: patch.adjustments.saturation,
      temperature: patch.adjustments.temperature
    };
    // V2: 同步区域参数
    if (patch.regionAdjustments !== undefined) {
      existing.regionAdjustments = cloneRegionAdjustments(patch.regionAdjustments);
    }
    // 0.1.9: 同步统一编辑快照（深拷贝）
    if (patch.editorSnapshot !== undefined) {
      existing.editorSnapshot = cloneEditorSnapshot(patch.editorSnapshot);
    }
    existing.updatedAt = Date.now();
    return existing;
  }

  /**
   * 新建或更新：id 为空时创建，否则更新。
   * 统一入口，避免调用方判断 create/update。
   */
  upsert(record: WorkRecord): WorkRecord {
    if (record.id === '') {
      return this.create(record);
    }
    return this.update(record.id, record);
  }

  /** 统计今日创建的作品数量（用于标题自动生成序号） */
  countToday(): number {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return this.works.filter((w: WorkRecord) => w.createdAt >= todayStart).length;
  }
}

/** 导出单例，全应用共享同一份作品数据 */
export const mockWorkStore = new MockWorkStore();
