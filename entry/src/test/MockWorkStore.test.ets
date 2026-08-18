import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { MockWorkStore } from '../main/ets/models/MockWorkStore';
import { WorkRecord, WorkStatus, DEFAULT_ADJUSTMENTS } from '../main/ets/models/WorkRecord';

export default function mockWorkStoreTest() {
  describe('MockWorkStore', () => {
    let store: MockWorkStore;

    beforeEach(() => {
      // 每个测试用例创建独立实例，避免单例状态污染
      store = new MockWorkStore();
      store.init();
    });

    it('initializes with 6 seed works', 0, () => {
      const works = store.list();
      expect(works.length).assertEqual(6);
    });

    it('returns list sorted by updatedAt descending', 0, () => {
      const works = store.list();
      for (let i = 1; i < works.length; i++) {
        expect(works[i - 1].updatedAt >= works[i].updatedAt).assertTrue();
      }
    });

    it('returns a copy of the internal list', 0, () => {
      const a = store.list();
      const b = store.list();
      // 两次调用返回不同数组引用
      expect(a === b).assertFalse();
      // 但内容相同
      expect(a.length).assertEqual(b.length);
    });

    it('finds an existing work by id', 0, () => {
      const work = store.findById('0409-A');
      expect(work !== null).assertTrue();
      expect(work!.title).assertEqual('竹林闲居图');
    });

    it('returns null for non-existent id', 0, () => {
      const work = store.findById('NONEXISTENT');
      expect(work).assertNull();
    });

    it('creates a new work with MOCK- prefix id', 0, () => {
      const before = store.list().length;
      const draft = new WorkRecord();
      draft.title = '测试新卷';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);
      expect(created.id.startsWith('MOCK-')).assertTrue();
      expect(store.list().length).assertEqual(before + 1);
    });

    it('sets createdAt and updatedAt on create', 0, () => {
      const draft = new WorkRecord();
      draft.title = '时间测试';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);
      expect(created.createdAt > 0).assertTrue();
      expect(created.updatedAt).assertEqual(created.createdAt);
    });

    it('updates an existing work', 0, () => {
      const draft = new WorkRecord();
      draft.title = '原始标题';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const update = new WorkRecord();
      update.id = created.id;
      update.title = '更新后标题';
      update.status = WorkStatus.Sealed;
      update.adjustments = { exposure: 15, brightness: -10, contrast: 5, saturation: 0 };
      const updated = store.update(update);

      expect(updated !== null).assertTrue();
      expect(updated!.title).assertEqual('更新后标题');
      expect(updated!.status).assertEqual(WorkStatus.Sealed);
      expect(updated!.adjustments.exposure).assertEqual(15);
    });

    it('returns null when updating non-existent work', 0, () => {
      const fake = new WorkRecord();
      fake.id = 'NONEXISTENT';
      fake.title = '不存在';
      const result = store.update(fake);
      expect(result).assertNull();
      expect(store.list().length).assertEqual(6);
    });

    it('does not modify existing fields when update fields are empty', 0, () => {
      const draft = new WorkRecord();
      draft.title = '保留标题';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const update = new WorkRecord();
      update.id = created.id;
      // 不设置 title（保持空字符串）
      update.status = WorkStatus.Sealed;
      const updated = store.update(update);

      expect(updated !== null).assertTrue();
      // title 应保留原值
      expect(updated!.title).assertEqual('保留标题');
      expect(updated!.status).assertEqual(WorkStatus.Sealed);
    });

    it('defaults adjustments to all zeros', 0, () => {
      const work = store.findById('0409-A');
      expect(work !== null).assertTrue();
      expect(work!.adjustments.exposure).assertEqual(0);
      expect(work!.adjustments.brightness).assertEqual(0);
      expect(work!.adjustments.contrast).assertEqual(0);
      expect(work!.adjustments.saturation).assertEqual(0);
    });

    it('seed works have populated createdAt', 0, () => {
      const work = store.findById('0409-A');
      expect(work !== null).assertTrue();
      expect(work!.createdAt > 0).assertTrue();
    });
  });
}
