import { AdjustParams, EditorToolKey, RegionAdjustments, cloneAdjustments, cloneRegionAdjustments } from './EditModels';
import { EditorSnapshot, cloneEditorSnapshot } from './SharedContracts';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { common } from '@kit.AbilityKit';
import { WorkFileService } from '../services/WorkFileService';

/**
 * 草稿记录数据结构
 */
export interface DraftRecord {
  imageUri: string;
  displayUri?: string;
  adjustments: AdjustParams;
  regionAdjustments?: RegionAdjustments;
  editorSnapshot?: EditorSnapshot;
  workId?: string;
  savedAt: number;
  title?: string;
  activeTool?: EditorToolKey;
  previewUri?: string;
}

const DRAFT_STORE_KEY = 'vivid_current_draft';

/**
 * 草稿存储器（DraftStore）
 *
 * 依据：三人分工 A 任务与下一阶段需求计划书。
 * 特性：
 * 1. 管理单一当前草稿，新草稿覆盖旧草稿；
 * 2. 进程内内存缓存保持同步快速访问，同时持久化到 Preferences；
 * 3. 支持深拷贝保护，防止外部修改污染内部状态。
 */
export class DraftStore {
  private static instance: DraftStore | null = null;
  private currentDraft: DraftRecord | null = null;
  private prefHelper: PreferencesHelper = PreferencesHelper.getStore('vivid_draft_store');
  private initialized: boolean = false;

  public static getInstance(): DraftStore {
    if (!DraftStore.instance) {
      DraftStore.instance = new DraftStore();
    }
    return DraftStore.instance;
  }

  public static createForTesting(): DraftStore {
    const store = new DraftStore();
    store.prefHelper = PreferencesHelper.getStore('vivid_draft_test_' + Date.now());
    return store;
  }

  public async init(context?: common.UIAbilityContext): Promise<void> {
    if (this.initialized && this.currentDraft !== null) {
      return;
    }
    const ctx = context ?? AppStorage.get<common.UIAbilityContext>('appContext');
    if (ctx) {
      try {
        const fileDraft = WorkFileService.loadDraftFile<DraftRecord>(ctx);
        if (fileDraft) {
          this.currentDraft = this.copyDraft(fileDraft);
          this.initialized = true;
          return;
        }
      } catch (_e) {
      }
    }
    await this.prefHelper.init(context);
    const stored = await this.prefHelper.getObject<DraftRecord | null>(DRAFT_STORE_KEY, null);
    if (stored) {
      this.currentDraft = this.copyDraft(stored);
    }
    this.initialized = true;
  }

  public save(draft: DraftRecord): void {
    const copied = this.copyDraft(draft);
    this.currentDraft = copied;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('appContext');
      if (ctx) {
        WorkFileService.saveDraftFile(ctx, copied);
      }
    } catch (_e) {
    }
    this.prefHelper.putObject(DRAFT_STORE_KEY, copied).catch(() => {
    });
  }

  public get(): DraftRecord | null {
    if (!this.currentDraft) {
      return null;
    }
    return this.copyDraft(this.currentDraft);
  }

  public clear(): void {
    this.currentDraft = null;
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('appContext');
      if (ctx) {
        WorkFileService.clearDraftFile(ctx);
      }
    } catch (_e) {
    }
    this.prefHelper.delete(DRAFT_STORE_KEY).catch(() => {
    });
  }

  public hasDraft(): boolean {
    return this.currentDraft !== null && this.currentDraft.imageUri.length > 0;
  }

  private copyDraft(d: DraftRecord): DraftRecord {
    return {
      imageUri: d.imageUri,
      displayUri: d.displayUri,
      adjustments: cloneAdjustments(d.adjustments),
      regionAdjustments: d.regionAdjustments ? cloneRegionAdjustments(d.regionAdjustments) : undefined,
      editorSnapshot: d.editorSnapshot ? cloneEditorSnapshot(d.editorSnapshot) : undefined,
      workId: d.workId,
      savedAt: d.savedAt,
      title: d.title,
      activeTool: d.activeTool,
      previewUri: d.previewUri
    };
  }
}

export const draftStore = DraftStore.getInstance();
