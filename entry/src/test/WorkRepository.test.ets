import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { WorkRepository } from '../main/ets/models/WorkRepository';
import { WorkRecord, WorkStatus } from '../main/ets/models/WorkRecord';

export default function workRepositoryTest() {
  describe('WorkRepository', () => {
    let repo: WorkRepository;

    beforeEach(() => {
      repo = WorkRepository.getInstance();
      repo.clearForTesting();
    });

    it('initializes with empty list when no prior storage', 0, () => {
      expect(repo.list().length).assertEqual(0);
    });

    it('creates work and finds it by id', 0, () => {
      const record = new WorkRecord();
      record.title = '作品仓库测试';
      record.status = WorkStatus.Sealed;

      const created = repo.create(record);
      expect(created.id.length > 0).assertTrue();

      const found = repo.findById(created.id);
      expect(found !== null).assertTrue();
      expect(found!.title).assertEqual('作品仓库测试');
      expect(found!.status).assertEqual(WorkStatus.Sealed);
    });

    it('updates work and bumps updatedAt', 0, () => {
      const record = new WorkRecord();
      record.title = '初始标题';
      const created = repo.create(record);

      const patch = new WorkRecord();
      patch.title = '更新标题';
      patch.status = WorkStatus.Sealed;

      const updated = repo.update(created.id, patch);
      expect(updated.title).assertEqual('更新标题');
      expect(updated.status).assertEqual(WorkStatus.Sealed);
      expect(repo.findById(created.id)!.title).assertEqual('更新标题');
    });

    it('deletes work and returns true', 0, () => {
      const record = new WorkRecord();
      record.title = '准备删除';
      const created = repo.create(record);
      expect(repo.list().length).assertEqual(1);

      const deleted = repo.delete(created.id);
      expect(deleted).assertTrue();
      expect(repo.list().length).assertEqual(0);
      expect(repo.findById(created.id)).assertNull();
    });

    it('upsert creates work when id is non-empty but does not exist in repository', 0, () => {
      const record = new WorkRecord();
      record.id = 'MOCK-NEW-ID';
      record.title = '全新卷宗';
      record.status = WorkStatus.Draft;
      const upserted = repo.upsert(record);
      expect(upserted.id).assertEqual('MOCK-NEW-ID');
      expect(repo.findById('MOCK-NEW-ID') !== null).assertTrue();
      expect(repo.findById('MOCK-NEW-ID')!.title).assertEqual('全新卷宗');
    });
  });
}
