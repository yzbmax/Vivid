import { describe, it, expect } from '@ohos/hypium';
import {
  EditorSnapshot,
  FilterSnapshot,
  TextLayer,
  BorderState,
  createDefaultEditorSnapshot,
  createDefaultFilterSnapshot,
  createDefaultBorderState,
  cloneFilterSnapshot,
  cloneTextLayer,
  cloneTextLayers,
  cloneBorderState,
  cloneEditorSnapshot
} from '../main/ets/models/SharedContracts';
import { MockWorkStore } from '../main/ets/models/MockWorkStore';
import { WorkRecord, WorkStatus } from '../main/ets/models/WorkRecord';

export default function editorSnapshotTest() {
  describe('EditorSnapshot', () => {

    it('creates default editor snapshot with schemaVersion 1', 0, () => {
      const snapshot = createDefaultEditorSnapshot();
      expect(snapshot.schemaVersion).assertEqual(1);
      expect(snapshot.filter.filterId).assertEqual('original');
      expect(snapshot.filter.strength).assertEqual(0);
      expect(snapshot.textLayers.length).assertEqual(0);
      expect(snapshot.border.templateId).assertEqual('none');
      expect(snapshot.border.widthRatio).assertEqual(0);
      expect(snapshot.border.shadowStrength).assertEqual(0);
    });

    it('deep clones filter snapshot and clamps strength', 0, () => {
      const original: FilterSnapshot = {
        filterId: 'jade_mist',
        strength: 1.5 // 超出 1.0，应钳制到 1.0
      };
      const cloned = cloneFilterSnapshot(original);
      expect(cloned.filterId).assertEqual('jade_mist');
      expect(cloned.strength).assertEqual(1.0);

      // 修改原对象不影响副本
      original.filterId = 'modified';
      expect(cloned.filterId).assertEqual('jade_mist');
    });

    it('deep clones text layer and enforces boundaries', 0, () => {
      const layer: TextLayer = {
        id: 'txt-1',
        content: '题签测试',
        fontKey: 'noto_serif_sc',
        colorArgb: 0xFF7B171B,
        fontSizeRatio: 0.50, // 超出 0.20 上限，应钳制到 0.20
        centerX: 1.2,        // 超出 1.0，应钳制到 1.0
        centerY: -0.1,       // 低于 0.0，应钳制到 0.0
        rotationDeg: 200,    // 超出 180，应钳制到 180
        opacity: 0.1         // 低于 0.3，应钳制到 0.3
      };
      const cloned = cloneTextLayer(layer);
      expect(cloned.fontSizeRatio).assertEqual(0.20);
      expect(cloned.centerX).assertEqual(1.0);
      expect(cloned.centerY).assertEqual(0.0);
      expect(cloned.rotationDeg).assertEqual(180);
      expect(cloned.opacity).assertEqual(0.3);

      // 原对象修改不影响副本
      layer.content = '已修改';
      expect(cloned.content).assertEqual('题签测试');
    });

    it('truncates text layers to max 8 items', 0, () => {
      const layers: TextLayer[] = [];
      for (let i = 0; i < 12; i++) {
        layers.push({
          id: `layer-${i}`,
          content: `文字${i}`,
          fontKey: 'system_sans',
          colorArgb: 0xFF241918,
          fontSizeRatio: 0.06,
          centerX: 0.5,
          centerY: 0.5,
          rotationDeg: 0,
          opacity: 1.0
        });
      }
      const cloned = cloneTextLayers(layers);
      expect(cloned.length).assertEqual(8);
      expect(cloned[7].id).assertEqual('layer-7');
    });

    it('deep clones border state and clamps widthRatio and shadowStrength', 0, () => {
      const border: BorderState = {
        templateId: 'paper_white',
        widthRatio: 0.4,       // 超出 0.25，应钳制到 0.25
        colorArgb: 0xFFF2F1ED,
        shadowStrength: 1.5    // 超出 1.0，应钳制到 1.0
      };
      const cloned = cloneBorderState(border);
      expect(cloned.widthRatio).assertEqual(0.25);
      expect(cloned.shadowStrength).assertEqual(1.0);

      border.templateId = 'changed';
      expect(cloned.templateId).assertEqual('paper_white');
    });

    it('deep clones full editor snapshot', 0, () => {
      const snapshot: EditorSnapshot = {
        schemaVersion: 1,
        filter: { filterId: 'ink_noir', strength: 0.8 },
        textLayers: [{
          id: 't1',
          content: '落款',
          fontKey: 'gkai',
          colorArgb: 0xFFB23B2F,
          fontSizeRatio: 0.08,
          centerX: 0.8,
          centerY: 0.8,
          rotationDeg: 0,
          opacity: 0.9
        }],
        border: {
          templateId: 'scroll_mount',
          widthRatio: 0.15,
          colorArgb: 0xFFDEDDD7,
          shadowStrength: 0.3
        }
      };

      const cloned = cloneEditorSnapshot(snapshot);
      expect(cloned.schemaVersion).assertEqual(1);
      expect(cloned.filter.filterId).assertEqual('ink_noir');
      expect(cloned.textLayers.length).assertEqual(1);
      expect(cloned.border.templateId).assertEqual('scroll_mount');

      // 深入修改验证独立性
      snapshot.filter.filterId = 'original';
      snapshot.textLayers[0].content = '篡改';
      snapshot.border.templateId = 'none';

      expect(cloned.filter.filterId).assertEqual('ink_noir');
      expect(cloned.textLayers[0].content).assertEqual('落款');
      expect(cloned.border.templateId).assertEqual('scroll_mount');
    });

    it('persists editorSnapshot in MockWorkStore with deep copy', 0, () => {
      const store = new MockWorkStore();
      store.init();

      const record = new WorkRecord();
      record.title = '快照持久化测试';
      record.status = WorkStatus.Sealed;
      const snapshot: EditorSnapshot = {
        schemaVersion: 1,
        filter: { filterId: 'cinnabar_glow', strength: 0.65 },
        textLayers: [{
          id: 't-persist',
          content: '朱砂印',
          fontKey: 'noto_serif_sc',
          colorArgb: 0xFF7B171B,
          fontSizeRatio: 0.05,
          centerX: 0.2,
          centerY: 0.2,
          rotationDeg: 0,
          opacity: 1.0
        }],
        border: {
          templateId: 'ink_black',
          widthRatio: 0.1,
          colorArgb: 0xFF241918,
          shadowStrength: 0.5
        }
      };
      record.editorSnapshot = snapshot;

      const created = store.create(record);
      // 修改原始 snapshot 对象
      snapshot.filter.filterId = 'tampered';
      snapshot.textLayers[0].content = 'tampered';

      const retrieved = store.findById(created.id);
      expect(retrieved !== null).assertTrue();
      expect(retrieved!.editorSnapshot !== undefined).assertTrue();
      expect(retrieved!.editorSnapshot!.filter.filterId).assertEqual('cinnabar_glow');
      expect(retrieved!.editorSnapshot!.textLayers[0].content).assertEqual('朱砂印');
    });

    it('provides safe default snapshot and maps template tool for legacy works', 0, () => {
      const store = new MockWorkStore();
      store.init();

      const legacy = new WorkRecord();
      legacy.title = '旧作品无快照';
      legacy.lastTool = 'template'; // 旧工具名
      legacy.editorSnapshot = undefined;

      const created = store.create(legacy);
      const retrieved = store.findById(created.id);

      expect(retrieved !== null).assertTrue();
      expect(retrieved!.lastTool).assertEqual('border'); // 应自动兼容映射为 border
      expect(retrieved!.editorSnapshot !== undefined).assertTrue();
      expect(retrieved!.editorSnapshot!.filter.filterId).assertEqual('original');
      expect(retrieved!.editorSnapshot!.textLayers.length).assertEqual(0);
      expect(retrieved!.editorSnapshot!.border.templateId).assertEqual('none');
    });
  });
}
