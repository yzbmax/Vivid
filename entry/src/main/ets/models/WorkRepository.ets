import { WorkRecord, WorkStatus } from './WorkRecord';
import { buildMockWorks } from './MockWorks';
import { cloneRegionAdjustments } from './EditModels';
import { cloneEditorSnapshot, createDefaultEditorSnapshot } from './SharedContracts';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { common } from '@kit.AbilityKit';
import { WorkFileService } from '../services/WorkFileService';

const WORKS_STORAGE_KEY = 'vivid_saved_works_list';

/**
 * 作品持久化仓库（WorkRepository）
 *
 * 依据：《Vivid三人分工与下一阶段任务清单》B 任务。
 * 核心设计：
 * 1. 内存高速缓存（保证 UI 同步读取无闪烁）+ Preferences 异步持久化（保证跨进程/重启存盘）；
 * 2. 维持与原 MockWorkStore 100% 相同的方法签名，增加真实的 delete(id) 接口；
 * 3. 首次冷启动若无本地存储，自动注入初始种子数据；
 * 4. 深度对象拷贝保护，杜绝引用污染。
 */
export class WorkRepository {
  private static instance: WorkRepository | null = null;
  private works: WorkRecord[] = [];
  private initialized: boolean = false;
  private prefHelper: PreferencesHelper = PreferencesHelper.getStore('vivid_works_repository');

  public static getInstance(): WorkRepository {
    if (!WorkRepository.instance) {
      WorkRepository.instance = new WorkRepository();
    }
    return WorkRepository.instance;
  }

  /** 初始化：加载本地持久化数据；无数据时灌入种子 */
  public async init(context?: common.UIAbilityContext): Promise<void> {
    if (this.initialized && this.works.length > 0) {
      return;
    }
    const ctx = context ?? AppStorage.get<common.UIAbilityContext>('appContext');
    if (ctx) {
      try {
        const fileWorks = WorkFileService.loadWorksManifest(ctx);
        if (fileWorks && fileWorks.length > 0) {
          this.works = fileWorks.map((w: WorkRecord) => this.sanitizeWork(w));
          this.initialized = true;
          return;
        }
      } catch (_e) {
      }
    }
    await this.prefHelper.init(context);
    const stored = await this.prefHelper.getObject<WorkRecord[] | null>(WORKS_STORAGE_KEY, null);
    if (stored && Array.isArray(stored) && stored.length > 0) {
      this.works = stored.map((w: WorkRecord) => this.sanitizeWork(w));
    } else if (this.works.length === 0) {
      this.works = buildMockWorks();
    }
    this.initialized = true;
  }

  /** 同步初始化保证（单测或同步首次拉取时安全降级） */
  public ensureInitSync(): void {
    if (!this.initialized || this.works.length === 0) {
      try {
        const ctx = AppStorage.get<common.UIAbilityContext>('appContext');
        if (ctx) {
          const fileWorks = WorkFileService.loadWorksManifest(ctx);
          if (fileWorks && fileWorks.length > 0) {
            this.works = fileWorks.map((w: WorkRecord) => this.sanitizeWork(w));
            this.initialized = true;
            return;
          }
        }
      } catch (_e) {
      }
      if (this.works.length === 0) {
        this.works = buildMockWorks();
      }
      this.initialized = true;
    }
  }

  /** 返回全部作品（按 updatedAt 倒序副本） */
  public list(): WorkRecord[] {
    this.ensureInitSync();
    return this.works.slice().sort((a: WorkRecord, b: WorkRecord) =>
      b.updatedAt - a.updatedAt
    ).map((w: WorkRecord) => this.sanitizeWork(w));
  }

  /** 按 ID 查找单个作品；不存在返回 null */
  public findById(id: string): WorkRecord | null {
    this.ensureInitSync();
    const work = this.works.find((w: WorkRecord) => w.id === id);
    if (!work) {
      return null;
    }
    return this.sanitizeWork(work);
  }

  /** 新建作品并持久化 */
  public create(record: WorkRecord): WorkRecord {
    this.ensureInitSync();
    const now = Date.now();
    record.id = record.id && record.id.length > 0 ? record.id : 'WORK-' + now;
    record.createdAt = record.createdAt > 0 ? record.createdAt : now;
    record.updatedAt = now;
    if (!record.status) {
      record.status = WorkStatus.Draft;
    }
    if (record.lastTool === 'template') {
      record.lastTool = 'border';
    }
    record.editorSnapshot = cloneEditorSnapshot(record.editorSnapshot);
    this.works.push(record);
    this.persist();
    return this.sanitizeWork(record);
  }

  /** 更新作品并持久化 */
  public update(id: string, patch: WorkRecord): WorkRecord {
    this.ensureInitSync();
    const index = this.works.findIndex((w: WorkRecord) => w.id === id);
    if (index < 0) {
      throw new Error(`Work not found: ${id}`);
    }
    const existing = this.works[index];
    if (patch.title && patch.title.length > 0) {
      existing.title = patch.title;
    }
    if (patch.sourceImageUri && patch.sourceImageUri.length > 0) {
      existing.sourceImageUri = patch.sourceImageUri;
    }
    if (patch.width > 0) {
      existing.width = patch.width;
    }
    if (patch.height > 0) {
      existing.height = patch.height;
    }
    if (patch.previewImage !== null && patch.previewImage !== undefined) {
      existing.previewImage = patch.previewImage;
    }
    if (patch.sealGlyph && patch.sealGlyph.length > 0) {
      existing.sealGlyph = patch.sealGlyph;
    }
    if (patch.date && patch.date.length > 0) {
      existing.date = patch.date;
    }
    if (patch.previewImageUri && patch.previewImageUri.length > 0) {
      existing.previewImageUri = patch.previewImageUri;
    }
    if (patch.exportedAssetUri && patch.exportedAssetUri.length > 0) {
      existing.exportedAssetUri = patch.exportedAssetUri;
    }
    if (patch.lastTool && patch.lastTool.length > 0) {
      existing.lastTool = patch.lastTool === 'template' ? 'border' : patch.lastTool;
    }
    if (patch.description && patch.description.length > 0) {
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
    if (patch.regionAdjustments !== undefined) {
      existing.regionAdjustments = cloneRegionAdjustments(patch.regionAdjustments);
    }
    if (patch.editorSnapshot !== undefined) {
      existing.editorSnapshot = cloneEditorSnapshot(patch.editorSnapshot);
    }
    existing.updatedAt = Date.now();
    this.persist();
    return this.sanitizeWork(existing);
  }

  /** 新建或更新 */
  public upsert(record: WorkRecord): WorkRecord {
    this.ensureInitSync();
    if (record.id === '' || !this.works.some((w: WorkRecord) => w.id === record.id)) {
      return this.create(record);
    }
    return this.update(record.id, record);
  }

  /** 删除作品（真实删除） */
  public delete(id: string): boolean {
    this.ensureInitSync();
    const index = this.works.findIndex((w: WorkRecord) => w.id === id);
    if (index >= 0) {
      this.works.splice(index, 1);
      this.persist();
      return true;
    }
    return false;
  }

  /** 统计今日作品数量 */
  public countToday(): number {
    this.ensureInitSync();
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    return this.works.filter((w: WorkRecord) => w.createdAt >= todayStart).length;
  }

  /** 清理全部（仅测试用） */
  public clearForTesting(): void {
    this.works = [];
    this.initialized = false;
  }

  private sanitizeWork(w: WorkRecord): WorkRecord {
    const copy: WorkRecord = new WorkRecord();
    copy.id = w.id;
    copy.title = w.title ?? '';
    copy.description = w.description ?? '';
    copy.previewImage = w.previewImage ?? null;
    copy.date = w.date ?? '';
    copy.sealGlyph = w.sealGlyph ?? '';
    copy.status = w.status ?? WorkStatus.Draft;
    copy.createdAt = w.createdAt ?? 0;
    copy.updatedAt = w.updatedAt ?? 0;
    copy.sourceImageUri = w.sourceImageUri ?? '';
    copy.previewImageUri = w.previewImageUri ?? '';
    copy.exportedAssetUri = w.exportedAssetUri ?? '';
    copy.lastTool = w.lastTool === 'template' ? 'border' : (w.lastTool ?? 'adjust');
    copy.width = w.width ?? 0;
    copy.height = w.height ?? 0;
    copy.adjustments = w.adjustments ? {
      exposure: w.adjustments.exposure ?? 0,
      brightness: w.adjustments.brightness ?? 0,
      contrast: w.adjustments.contrast ?? 0,
      saturation: w.adjustments.saturation ?? 0,
      temperature: w.adjustments.temperature ?? 0
    } : { exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 0 };
    if (w.regionAdjustments) {
      copy.regionAdjustments = cloneRegionAdjustments(w.regionAdjustments);
    }
    copy.editorSnapshot = cloneEditorSnapshot(w.editorSnapshot ?? createDefaultEditorSnapshot());
    return copy;
  }

  private persist(): void {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('appContext');
      if (ctx) {
        WorkFileService.saveWorksManifest(ctx, this.works);
      }
    } catch (_e) {
    }
    this.prefHelper.putObject(WORKS_STORAGE_KEY, this.works).catch(() => {
    });
  }
}

export const workRepository = WorkRepository.getInstance();
