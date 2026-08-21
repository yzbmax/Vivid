import { describe, it, expect } from '@ohos/hypium';
import { PendingEditIntent } from '../main/ets/models/EditModels';
import { PendingEditIntentStore } from '../main/ets/models/PendingEditIntentStore';

export default function pendingEditIntentStoreTest() {
  describe('pendingEditIntentStoreTest', () => {
    it('sets peeks overwrites and clears one pending intent', 0, () => {
      PendingEditIntentStore.clear();
      const first: PendingEditIntent = {
        imageUri: 'file:///first.jpg',
        initialTool: 'filter',
        createdAt: 100
      };
      const second: PendingEditIntent = {
        imageUri: 'file:///second.jpg',
        initialTool: 'text',
        createdAt: 200
      };

      PendingEditIntentStore.set(first);
      expect(PendingEditIntentStore.peek()?.imageUri).assertEqual('file:///first.jpg');

      PendingEditIntentStore.set(second);
      expect(PendingEditIntentStore.peek()?.initialTool).assertEqual('text');

      PendingEditIntentStore.clear();
      expect(PendingEditIntentStore.peek()).assertUndefined();
    });

    it('consumes an intent only once', 0, () => {
      PendingEditIntentStore.clear();
      const intent: PendingEditIntent = {
        imageUri: 'file:///once.jpg',
        initialTool: 'adjust',
        createdAt: 300
      };
      PendingEditIntentStore.set(intent);

      expect(PendingEditIntentStore.consume()?.imageUri).assertEqual('file:///once.jpg');
      expect(PendingEditIntentStore.consume()).assertUndefined();
    });

    it('returns copies that cannot mutate the stored intent', 0, () => {
      PendingEditIntentStore.clear();
      const intent: PendingEditIntent = {
        imageUri: 'file:///safe.jpg',
        initialTool: 'subject',
        createdAt: 400
      };
      PendingEditIntentStore.set(intent);
      intent.imageUri = 'file:///caller-mutated.jpg';

      const peeked = PendingEditIntentStore.peek();
      if (peeked !== undefined) {
        peeked.initialTool = 'template';
      }

      const consumed = PendingEditIntentStore.consume();
      expect(consumed?.imageUri).assertEqual('file:///safe.jpg');
      expect(consumed?.initialTool).assertEqual('subject');
    });
  });
}
