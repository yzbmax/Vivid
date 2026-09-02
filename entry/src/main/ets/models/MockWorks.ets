import { WorkRecord, WorkStatus } from './WorkRecord';

/** mock 作品数据（对应 Works Page 样板六卡）；接入 WorkRepository 后替换为真实数据源 */
export function buildMockWorks(): WorkRecord[] {
  return [];
}

/** 按 id 查找作品（作品详情页使用） */
export function findWork(id: string): WorkRecord | null {
  return buildMockWorks().find((w: WorkRecord) => w.id === id) ?? null;
}
