import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { MockWorkStore } from '../main/ets/models/MockWorkStore';
import { WorkRecord, WorkStatus } from '../main/ets/models/WorkRecord';
import { EditorSnapshot } from '../main/ets/models/SharedContracts';

export default function mockWorkStoreTest() {
  describe('MockWorkStore', () => {
    let store: MockWorkStore;

    beforeEach(() => {
      // 每个测试用例创建独立实例，避免单例状态污染
      store = new MockWorkStore();
      store.init();
    });

    it('initializes with empty works', 0, () => {
      const works = store.list();
      expect(works.length).assertEqual(0);
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
      const draft = new WorkRecord();
      draft.title = '测试查找';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const work = store.findById(created.id);
      expect(work !== null).assertTrue();
      expect(work!.title).assertEqual('测试查找');
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

    // ── update() tests（签名: update(id, patch)）──

    it('updates an existing work by id and patch', 0, () => {
      const draft = new WorkRecord();
      draft.title = '原始标题';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const patch = new WorkRecord();
      patch.title = '更新后标题';
      patch.status = WorkStatus.Sealed;
      patch.adjustments = { exposure: 15, brightness: -10, contrast: 5, saturation: 0, temperature: 0 };
      const updated = store.update(created.id, patch);

      expect(updated !== null).assertTrue();
      expect(updated!.title).assertEqual('更新后标题');
      expect(updated!.status).assertEqual(WorkStatus.Sealed);
      expect(updated!.adjustments.exposure).assertEqual(15);
    });

    it('throws when updating non-existent work', 0, () => {
      let threw = false;
      try {
        const patch = new WorkRecord();
        patch.title = '不存在';
        store.update('NONEXISTENT', patch);
      } catch (_e) {
        threw = true;
      }
      expect(threw).assertTrue();
      expect(store.list().length).assertEqual(0);
    });

    it('does not modify existing fields when patch fields are empty', 0, () => {
      const draft = new WorkRecord();
      draft.title = '保留标题';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const patch = new WorkRecord();
      // 不设置 title（保持空字符串）
      patch.status = WorkStatus.Sealed;
      const updated = store.update(created.id, patch);

      expect(updated !== null).assertTrue();
      // title 应保留原值
      expect(updated!.title).assertEqual('保留标题');
      expect(updated!.status).assertEqual(WorkStatus.Sealed);
    });

    it('merges previewImageUri and exportedAssetUri on update', 0, () => {
      const draft = new WorkRecord();
      draft.title = 'URI测试';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const patch = new WorkRecord();
      patch.previewImageUri = 'file:///sandbox/preview.jpg';
      patch.exportedAssetUri = 'file://media/Photo/1';
      patch.lastTool = 'filter';
      const updated = store.update(created.id, patch);

      expect(updated!.previewImageUri).assertEqual('file:///sandbox/preview.jpg');
      expect(updated!.exportedAssetUri).assertEqual('file://media/Photo/1');
      expect(updated!.lastTool).assertEqual('filter');
    });

    it('bumps updatedAt on update', 0, () => {
      const draft = new WorkRecord();
      draft.title = '时间更新测试';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);
      const beforeUpdate = created.updatedAt;

      // 确保时间差
      const patch = new WorkRecord();
      patch.status = WorkStatus.Sealed;
      const updated = store.update(created.id, patch);

      expect(updated!.updatedAt >= beforeUpdate).assertTrue();
    });

    // ── upsert() tests ──

    it('upsert creates when id is empty', 0, () => {
      const before = store.list().length;
      const record = new WorkRecord();
      record.title = '新作品';
      record.status = WorkStatus.Draft;
      const result = store.upsert(record);

      expect(result.id.startsWith('MOCK-')).assertTrue();
      expect(result.title).assertEqual('新作品');
      expect(store.list().length).assertEqual(before + 1);
    });

    it('upsert updates when id exists', 0, () => {
      const draft = new WorkRecord();
      draft.title = '原始';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const patch = new WorkRecord();
      patch.id = created.id;
      patch.title = '已更新';
      patch.status = WorkStatus.Sealed;
      const updated = store.upsert(patch);

      expect(updated.id).assertEqual(created.id);
      expect(updated.title).assertEqual('已更新');
      expect(updated.status).assertEqual(WorkStatus.Sealed);
    });

    it('upsert preserves createdAt on update', 0, () => {
      const draft = new WorkRecord();
      draft.title = '保留时间';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);
      const originalCreatedAt = created.createdAt;

      const patch = new WorkRecord();
      patch.id = created.id;
      patch.title = '更新后';
      const updated = store.upsert(patch);

      expect(updated.createdAt).assertEqual(originalCreatedAt);
    });

    it('defaults adjustments to all zeros', 0, () => {
      const draft = new WorkRecord();
      draft.title = '默认参数';
      draft.status = WorkStatus.Draft;
      const created = store.create(draft);

      const work = store.findById(created.id);
      expect(work !== null).assertTrue();
      expect(work!.adjustments.exposure).assertEqual(0);
      expect(work!.adjustments.brightness).assertEqual(0);
      expect(work!.adjustments.contrast).assertEqual(0);
      expect(work!.adjustments.saturation).assertEqual(0);
    });

    // ── 0.1.9 EditorSnapshot tests ──

    it('persists and deep copies editorSnapshot on create and update', 0, () => {
      const draft = new WorkRecord();
      draft.title = '快照持久化';
      draft.status = WorkStatus.Draft;
      const snapshot: EditorSnapshot = {
        schemaVersion: 1,
        filter: { filterId: 'jade_mist', strength: 0.68 },
        textLayers: [{
          id: 'txt-0',
          content: '题签',
          fontKey: 'noto_serif_sc',
          colorArgb: 0xFF241918,
          fontSizeRatio: 0.08,
          centerX: 0.5,
          centerY: 0.5,
          rotationDeg: 0,
          opacity: 1.0
        }],
        border: {
          templateId: 'paper_white',
          widthRatio: 0.1,
          colorArgb: 0xFFF2F1ED,
          shadowStrength: 0
        }
      };
      draft.editorSnapshot = snapshot;

      const created = store.create(draft);
      // 修改原始 snapshot
      snapshot.filter.filterId = 'modified';
      snapshot.textLayers[0].content = 'modified';

      const found = store.findById(created.id);
      expect(found !== null).assertTrue();
      expect(found!.editorSnapshot!.filter.filterId).assertEqual('jade_mist');
      expect(found!.editorSnapshot!.textLayers[0].content).assertEqual('题签');
    });

    it('maps legacy template tool to border when finding or listing', 0, () => {
      const legacy = new WorkRecord();
      legacy.title = '旧工具名作品';
      legacy.lastTool = 'template';
      legacy.status = WorkStatus.Draft;

      const created = store.create(legacy);
      const found = store.findById(created.id);
      expect(found !== null).assertTrue();
      expect(found!.lastTool).assertEqual('border');

      const list = store.list();
      const item = list.find((w: WorkRecord) => w.id === created.id);
      expect(item !== undefined).assertTrue();
      expect(item!.lastTool).assertEqual('border');
    });

  });
}
