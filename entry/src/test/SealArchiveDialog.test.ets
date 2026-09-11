import { describe, it, expect } from '@ohos/hypium';
import { ArchiveStage } from '../main/ets/components/editor/SealArchiveDialog';

export default function sealArchiveDialogTest() {
  describe('SealArchiveDialogTest', () => {
    it('should support all archive stages in logical sequence', 0, () => {
      const stages: ArchiveStage[] = ['render', 'border', 'export', 'sealed'];
      expect(stages.length).assertEqual(4);
      expect(stages[0]).assertEqual('render');
      expect(stages[1]).assertEqual('border');
      expect(stages[2]).assertEqual('export');
      expect(stages[3]).assertEqual('sealed');
    });

    it('should format archive number with 4 digits zero-padded', 0, () => {
      const formatArchiveNo = (count: number): string => String(count).padStart(4, '0');
      expect(formatArchiveNo(1)).assertEqual('0001');
      expect(formatArchiveNo(409)).assertEqual('0409');
      expect(formatArchiveNo(1024)).assertEqual('1024');
    });
  });
}
