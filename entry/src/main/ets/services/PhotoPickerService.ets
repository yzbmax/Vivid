import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export type PhotoPickResult =
  | { status: 'selected'; imageUri: string }
  | { status: 'cancelled' }
  | { status: 'failed'; errorCode?: number };

/** Convert picker output into the page-safe result contract. */
export function normalizePhotoUris(photoUris: string[]): PhotoPickResult {
  if (photoUris.length === 0 || photoUris[0].length === 0) {
    return { status: 'cancelled' };
  }
  return { status: 'selected', imageUri: photoUris[0] };
}

/** System photo selection without requesting broad gallery permissions. */
export class PhotoPickerService {
  public static async pickSingleImage(): Promise<PhotoPickResult> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    try {
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      return normalizePhotoUris(result.photoUris);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      if (error.code === 13900042) {
        return { status: 'cancelled' };
      }
      return { status: 'failed', errorCode: error.code };
    }
  }
}
