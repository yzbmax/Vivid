import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { DraftStore, DraftRecord } from '../main/ets/models/DraftStore';
import { createDefaultAdjustments } from '../main/ets/models/EditModels';
import { defaultEditorSnapshot } from '../main/ets/models/SharedContracts';

export default function draftStoreTest() {
  describe('DraftStore', () => {
    let store: DraftStore;

    beforeEach(() => {
      store = DraftStore.createForTesting();
    });

    it('hasDraft returns false when empty', 0, () => {
      expect(store.hasDraft()).assertFalse();
      expect(store.get()).assertNull();
    });

    it('saves draft and retrieves a copy', 0, () => {
      const record: DraftRecord = {
        imageUri: 'file:///data/storage/el2/base/test.jpg',
        adjustments: createDefaultAdjustments(),
        editorSnapshot: defaultEditorSnapshot(),
        savedAt: 123456789
      };
      record.adjustments.exposure = 20;

      store.save(record);

      expect(store.hasDraft()).assertTrue();
      const retrieved = store.get();
      expect(retrieved !== null).assertTrue();
      expect(retrieved!.imageUri).assertEqual('file:///data/storage/el2/base/test.jpg');
      expect(retrieved!.adjustments.exposure).assertEqual(20);

      // 验证深拷贝隔离
      record.adjustments.exposure = 50;
      expect(store.get()!.adjustments.exposure).assertEqual(20);
    });

    it('clears draft properly', 0, () => {
      const record: DraftRecord = {
        imageUri: 'file:///test.jpg',
        adjustments: createDefaultAdjustments(),
        savedAt: Date.now()
      };
      store.save(record);
      expect(store.hasDraft()).assertTrue();

      store.clear();
      expect(store.hasDraft()).assertFalse();
      expect(store.get()).assertNull();
    });

    it('preserves title, activeTool, previewUri and workId', 0, () => {
      const record: DraftRecord = {
        imageUri: 'file:///data/storage/el2/base/drafts/test.jpg',
        displayUri: 'file:///data/storage/el2/base/drafts/test.jpg',
        adjustments: createDefaultAdjustments(),
        editorSnapshot: defaultEditorSnapshot(),
        workId: 'WORK-12345',
        savedAt: 1725420000000,
        title: '未保存草稿 · 14:15',
        activeTool: 'filter',
        previewUri: 'file:///data/storage/el2/base/drafts/preview.jpg'
      };

      store.save(record);

      const retrieved = store.get();
      expect(retrieved !== null).assertTrue();
      expect(retrieved!.title).assertEqual('未保存草稿 · 14:15');
      expect(retrieved!.activeTool).assertEqual('filter');
      expect(retrieved!.previewUri).assertEqual('file:///data/storage/el2/base/drafts/preview.jpg');
      expect(retrieved!.workId).assertEqual('WORK-12345');
    });
  });
}
