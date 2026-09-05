/**
 * 作品 UI 状态：提供响应式刷新机制。
 * 当 MockWorkStore 数据变化时调用 bumpRevision()，订阅者自动刷新列表。
 *
 * TODO: 后续由开发者 B 完善或合并到 MockWorkStore 内部。
 */
export class WorkUiState {
  private static listeners: Array<() => void> = [];

  static onChange(listener: () => void): () => void {
    WorkUiState.listeners.push(listener);
    return () => {
      const idx = WorkUiState.listeners.indexOf(listener);
      if (idx >= 0) {
        WorkUiState.listeners.splice(idx, 1);
      }
    };
  }

  static bumpRevision(): void {
    const snapshot = WorkUiState.listeners.slice();
    for (const fn of snapshot) {
      fn();
    }
  }
}
