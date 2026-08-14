import { WorkRecord, WorkStatus } from './WorkRecord';

/** mock 作品数据（对应 Works Page 样板六卡）；接入 WorkRepository 后替换为真实数据源 */
export function buildMockWorks(): WorkRecord[] {
  const list: WorkRecord[] = [];
  const mk = (id: string, title: string, media: Resource, date: string,
    sealGlyph: string, status: WorkStatus, updatedAt: number): WorkRecord => {
    const w = new WorkRecord();
    w.id = id;
    w.title = title;
    w.previewImage = media;
    w.date = date;
    w.sealGlyph = sealGlyph;
    w.status = status;
    w.updatedAt = updatedAt;
    return w;
  };
  list.push(mk('0409-A', '竹林闲居图', $r('app.media.work_bamboo'), '2024.08.15', '甲', WorkStatus.Sealed, 20240815));
  list.push(mk('0409-B', '夜雨古刹', $r('app.media.work_temple'), '2024.08.12', '乙', WorkStatus.Sealed, 20240812));
  list.push(mk('0409-C', '残印特写', $r('app.media.work_seal'), '2024.08.10', '', WorkStatus.Draft, 20240810));
  list.push(mk('0409-D', '江山万里卷', $r('app.media.work_mountain'), '2024.08.05', '丙', WorkStatus.Sealed, 20240805));
  list.push(mk('0409-E', '残印特写', $r('app.media.work_seal'), '2024.08.10', '吴', WorkStatus.Draft, 20240810));
  list.push(mk('0409-F', '江山万里卷', $r('app.media.work_mountain'), '2024.08.05', '时', WorkStatus.Sealed, 20240805));
  return list;
}

/** 按 id 查找作品（作品详情页使用） */
export function findWork(id: string): WorkRecord | null {
  return buildMockWorks().find((w: WorkRecord) => w.id === id) ?? null;
}
