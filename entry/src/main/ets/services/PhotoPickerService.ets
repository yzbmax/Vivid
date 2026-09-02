import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export interface SelectedPhotoPickResult {
  status: 'selected';
  /** Temporary picker URI retained as an ArkUI display fallback. */
  imageUri: string;
  /** App-sandbox copy used by ImageKit and the native render pipeline. */
  sourcePath: string;
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

/** PhotoViewPicker returns a temporary media-provider URI, not an app file path. */
export function isPhotoPickerUri(sourceUri: string): boolean {
  return sourceUri.startsWith('file://media/') || sourceUri.startsWith('dataability://');
}

/** Convert picker output into the page-safe result contract. */
export function normalizePhotoUris(photoUris: string[]): PhotoPickResult {
  if (photoUris.length === 0 || photoUris[0].length === 0) {
    const cancelled: CancelledPhotoPickResult = { status: 'cancelled' };
    return cancelled;
  }
  return buildSelectedPhotoResult(photoUris[0], '');
}

export function buildSelectedPhotoResult(
  imageUri: string,
  sourcePath: string
): SelectedPhotoPickResult {
  return { status: 'selected', imageUri: imageUri, sourcePath: sourcePath };
}

/** System photo selection without requesting broad gallery permissions. */
export class PhotoPickerService {
  public static async pickSingleImage(
    context: common.UIAbilityContext
  ): Promise<PhotoPickResult> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      const normalized = normalizePhotoUris(result.photoUris);
      if (normalized.status !== 'selected') {
        return normalized;
      }

      // The URI returned by PhotoViewPicker is a temporary provider URI. Resolve it
      // while picker authorization is still active, then pass only a sandbox path
      // to the editor. This also prevents preview and thumbnail pipelines from
      // issuing concurrent media-provider reads after navigation.
      const sourcePath = await PhotoPickerService.copySelectedAssetToCache(
        context,
        normalized.imageUri
      );
      return buildSelectedPhotoResult(normalized.imageUri, sourcePath);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`Photo import failed: code=${error.code}, message=${error.message}`);
      if (error.code === 13900042) {
        const cancelled: CancelledPhotoPickResult = { status: 'cancelled' };
        return cancelled;
      }
      const failed: FailedPhotoPickResult = { status: 'failed', errorCode: error.code };
      return failed;
    }
  }

  private static async copySelectedAssetToCache(
    context: common.UIAbilityContext,
    sourceUri: string
  ): Promise<string> {
    const cachePath = `${context.cacheDir}/vivid_import_${Date.now()}.image`;
    let sourceFd: number = -1;
    let destinationFd: number = -1;
    try {
      // PhotoViewPicker grants this app temporary access to the returned URI.
      sourceFd = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY).fd;
      destinationFd = fs.openSync(
        cachePath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
      ).fd;

      // PhotoPicker URIs can be copied reliably only after opening them. The
      // platform's fd-to-fd copy preserves the complete encoded asset and avoids
      // the offset/partial-write corruption possible in a hand-written loop.
      fs.copyFileSync(sourceFd, destinationFd);

      fs.closeSync(destinationFd);
      destinationFd = -1;
      await PhotoPickerService.validateCachedImage(cachePath);
      return cachePath;
    } catch (err) {
      const error: Error = err as Error;
      console.error(`Failed to materialize selected photo: ${error.message}`);
      PhotoPickerService.safeUnlink(cachePath);
      throw err as Error;
    } finally {
      if (destinationFd >= 0) {
        fs.closeSync(destinationFd);
      }
      if (sourceFd >= 0) {
        fs.closeSync(sourceFd);
      }
    }
  }

  private static async validateCachedImage(path: string): Promise<void> {
    const cachedFile = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const imageSource = image.createImageSource(cachedFile.fd);
    try {
      const imageInfo = await imageSource.getImageInfo();
      if (imageInfo.size.width <= 0 || imageInfo.size.height <= 0) {
        throw new Error('Selected photo has invalid dimensions');
      }
      const longEdge = Math.max(imageInfo.size.width, imageInfo.size.height);
      const scale = Math.min(1, 64 / longEdge);
      const validationPixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        desiredSize: {
          width: Math.max(1, Math.round(imageInfo.size.width * scale)),
          height: Math.max(1, Math.round(imageInfo.size.height * scale))
        }
      });
      validationPixelMap.release();
    } finally {
      await imageSource.release();
      fs.closeSync(cachedFile.fd);
    }
  }

  private static safeUnlink(path: string): void {
    try {
      fs.unlinkSync(path);
    } catch (_err) {
      // The file may not have been created yet.
    }
  }
}
