import { WorkRecord } from '../../models/WorkRecord';

/**
 * 符合 ArkUI IDataSource 规范的 Works 懒加载数据源。
 * 供 WaterFlow / List 组件使用 LazyForEach 时进行精准增量刷新与内存虚拟化。
 */
export class WorkDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataArray: WorkRecord[] = [];

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): WorkRecord {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  setData(data: WorkRecord[]): void {
    this.dataArray = data ? data.slice() : [];
    this.notifyDataReload();
  }
}
