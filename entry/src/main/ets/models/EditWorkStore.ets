import { WorkDraft } from './EditModels';

/**
 * @deprecated 兼容遗留：内存作品草稿仓库（C 独占，进程内有效，重启不恢复）。
 *
 * 本阶段仅停止引用并标记为兼容遗留，不删除。后续如需删除须单独确认和单独提交。
 * 所有新代码应使用 MockWorkStore（统一作品仓库）。
 *
 * 方法名与冻结契约（list / findById / create / update）一致，但出入参是 C 侧的
 * WorkDraft（WorkRecord 尚无 sourceImageUri/adjustments 等扩展字段）。
 * 开发者 B 交付 MockWorkStore / WorkRecord 扩展字段后，由适配层把 WorkDraft
 * 映射为 WorkRecord 并转发给 MockWorkStore，本文件随之替换为适配器或删除。
 */
export class EditWorkStore {
  private static items: WorkDraft[] = [];

  /** 返回全部草稿，按 updatedAt 倒序（最新在前）。 */
  static list(): WorkDraft[] {
    return EditWorkStore.items.slice().sort((a: WorkDraft, b: WorkDraft) => b.updatedAt - a.updatedAt);
  }

  static findById(id: string): WorkDraft | null {
    const hit = EditWorkStore.items.find((it: WorkDraft) => it.id === id);
    return hit != null ? hit : null;
  }

  static create(draft: WorkDraft): WorkDraft {
    EditWorkStore.items.push(draft);
    return draft;
  }

  /** 续编更新：保留原 id/title/width/height/createdAt，替换源图/参数/状态/更新时间。 */
  static update(id: string, patch: WorkDraft): WorkDraft | null {
    const idx = EditWorkStore.items.findIndex((it: WorkDraft) => it.id === id);
    if (idx < 0) {
      return null;
    }
    const prev = EditWorkStore.items[idx];
    const merged: WorkDraft = {
      id: prev.id,
      title: prev.title,
      sourceImageUri: patch.sourceImageUri,
      width: prev.width,
      height: prev.height,
      adjustments: patch.adjustments,
      status: patch.status,
      createdAt: prev.createdAt,
      updatedAt: patch.updatedAt
    };
    EditWorkStore.items[idx] = merged;
    return merged;
  }

  /** 清空（仅测试用）。 */
  static clear(): void {
    EditWorkStore.items = [];
  }
}
