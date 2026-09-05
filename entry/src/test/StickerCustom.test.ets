import { describe, it, expect } from '@ohos/hypium';
import {
  STICKER_CATEGORIES,
  StickerItem,
  createCustomStickerInstance
} from '../main/ets/models/EditModels';
import {
  EditorSnapshot,
  StickerSnapshotItem,
  cloneEditorSnapshot,
  defaultEditorSnapshot
} from '../main/ets/models/SharedContracts';

export default function stickerCustomTest() {
  describe('stickerCustomTest', () => {
    it('includes custom category in STICKER_CATEGORIES', 0, () => {
      const customCategory = STICKER_CATEGORIES.find((cat) => cat.key === 'custom');
      expect(customCategory !== undefined).assertTrue();
      expect(customCategory?.label).assertEqual('自定义');
    });

    it('creates custom sticker instance with customUri', 0, () => {
      const uri = 'file://test/custom_sticker.png';
      const item: StickerItem = createCustomStickerInstance(uri, 200, 300);
      expect(item.instanceId.startsWith('sticker-custom-')).assertTrue();
      expect(item.customUri).assertEqual(uri);
      expect(item.size).assertEqual(64);
      expect(item.posX).assertEqual(200 - 32);
      expect(item.posY).assertEqual(300 - 32);
      expect(item.opacity).assertEqual(1.0);
    });

    it('persists and deep clones customUri in EditorSnapshot', 0, () => {
      const snapshot: EditorSnapshot = defaultEditorSnapshot();
      const sticker1: StickerSnapshotItem = {
        instanceId: 'stk-1',
        templateId: 'custom',
        posX: 50,
        posY: 60,
        size: 80,
        rotation: 15,
        opacity: 0.9,
        zIndex: 1,
        customUri: 'file://path/to/custom_transparent.png'
      };
      snapshot.stickers = [sticker1];

      const cloned = cloneEditorSnapshot(snapshot);
      expect(cloned.stickers !== undefined).assertTrue();
      expect(cloned.stickers?.length).assertEqual(1);
      expect(cloned.stickers?.[0].customUri).assertEqual('file://path/to/custom_transparent.png');
      expect(cloned.stickers?.[0].instanceId).assertEqual('stk-1');

      // Verify deep copy mutation safety
      sticker1.customUri = 'file://mutated/path.png';
      expect(cloned.stickers?.[0].customUri).assertEqual('file://path/to/custom_transparent.png');
    });
  });
}
