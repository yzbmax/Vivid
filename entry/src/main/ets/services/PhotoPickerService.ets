import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export interface SelectedPhotoPickResult {
  status: 'selected';
  imageUri: string;
}

export interface CancelledPhotoPickResult {
  status: 'cancelled';
}

export interface FailedPhotoPickResult {
  status: 'failed';
  errorCode?: number;
}

export type PhotoPickResult =
  SelectedPhotoPickResult | CancelledPhotoPickResult | FailedPhotoPickResult;

/** Convert picker output into the page-safe result contract. */
export function normalizePhotoUris(photoUris: string[]): PhotoPickResult {
  if (photoUris.length === 0 || photoUris[0].length === 0) {
    const cancelled: CancelledPhotoPickResult = { status: 'cancelled' };
    return cancelled;
  }
  const selected: SelectedPhotoPickResult = { status: 'selected', imageUri: photoUris[0] };
  return selected;
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
        const cancelled: CancelledPhotoPickResult = { status: 'cancelled' };
        return cancelled;
      }
      const failed: FailedPhotoPickResult = { status: 'failed', errorCode: error.code };
      return failed;
    }
  }
}
