import { AdjustParams, RegionAdjustments, cloneAdjustments, cloneRegionAdjustments } from './EditModels';

/**
 * 单步编辑状态快照
 */
export interface EditHistorySnapshot {
  adjustments: AdjustParams;
  filterId: string;
  filterStrength: number;
  regionAdjustments?: RegionAdjustments;
  description?: string;
}

/**
 * 调色编辑历史栈管理器（撤销/重做）
 */
export class EditHistoryManager {
  private undoStack: EditHistorySnapshot[] = [];
  private redoStack: EditHistorySnapshot[] = [];
  private readonly maxDepth: number;

  constructor(maxDepth: number = 20) {
    this.maxDepth = maxDepth;
  }

  /**
   * 是否可以撤销
   */
  canUndo(): boolean {
    return this.undoStack.length > 0;
  }

  /**
   * 是否可以重做
   */
  canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  /**
   * 压入历史快照（发生新操作时，保存之前的状态，并清空重做栈）
   */
  pushSnapshot(snapshot: EditHistorySnapshot): void {
    const copy = this.cloneSnapshot(snapshot);
    this.undoStack.push(copy);
    if (this.undoStack.length > this.maxDepth) {
      this.undoStack.shift();
    }
    this.redoStack = [];
  }

  /**
   * 执行撤销：将当前状态压入 redo 栈，弹出上一步并返回
   */
  undo(currentState: EditHistorySnapshot): EditHistorySnapshot | null {
    if (!this.canUndo()) {
      return null;
    }
    const previous = this.undoStack.pop();
    if (!previous) {
      return null;
    }
    this.redoStack.push(this.cloneSnapshot(currentState));
    return this.cloneSnapshot(previous);
  }

  /**
   * 执行重做：将当前状态压入 undo 栈，弹出下一步并返回
   */
  redo(currentState: EditHistorySnapshot): EditHistorySnapshot | null {
    if (!this.canRedo()) {
      return null;
    }
    const next = this.redoStack.pop();
    if (!next) {
      return null;
    }
    this.undoStack.push(this.cloneSnapshot(currentState));
    return this.cloneSnapshot(next);
  }

  /**
   * 清空历史
   */
  clear(): void {
    this.undoStack = [];
    this.redoStack = [];
  }

  private cloneSnapshot(snapshot: EditHistorySnapshot): EditHistorySnapshot {
    return {
      adjustments: cloneAdjustments(snapshot.adjustments),
      filterId: snapshot.filterId,
      filterStrength: snapshot.filterStrength,
      regionAdjustments: snapshot.regionAdjustments ? cloneRegionAdjustments(snapshot.regionAdjustments) : undefined,
      description: snapshot.description
    };
  }
}
