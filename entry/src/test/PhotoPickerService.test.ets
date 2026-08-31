import { describe, it, expect } from '@ohos/hypium';
import {
  buildSelectedPhotoResult,
  isPhotoPickerUri,
  SelectedPhotoPickResult
} from '../main/ets/services/PhotoPickerService';

export default function photoPickerServiceTest() {
  describe('photoPickerServiceTest', () => {
    it('recognizes media-provider URIs returned by PhotoViewPicker', 0, () => {
      expect(isPhotoPickerUri('file://media/Photo/123')).assertTrue();
      expect(isPhotoPickerUri('dataability:///media/Photo/123')).assertTrue();
    });

    it('does not classify an app sandbox path as a picker URI', 0, () => {
      expect(isPhotoPickerUri('/data/storage/el2/base/files/photo.jpg')).assertFalse();
    });

    it('keeps the picker URI for display and the sandbox path for processing', 0, () => {
      const result: SelectedPhotoPickResult = buildSelectedPhotoResult(
        'file://media/Photo/123',
        '/data/storage/el2/base/cache/vivid_import_123.image'
      );
      expect(result.imageUri).assertEqual('file://media/Photo/123');
      expect(result.sourcePath).assertEqual('/data/storage/el2/base/cache/vivid_import_123.image');
    });

  });
}
