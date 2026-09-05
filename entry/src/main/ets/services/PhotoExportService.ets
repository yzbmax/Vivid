import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ExportProfile } from '../models/AppSettingsModels';

/**
 * 导出结果
 */
export interface ExportResult {
  /** 是否成功 */
  success: boolean;
  /** 成功时返回媒体库 URI */
  mediaUri?: string;
  /** 失败时返回错误码 */
  errorCode?: string;
  /** 失败时返回错误信息 */
  errorMessage?: string;
}

/**
 * 相册导出服务：将 PixelMap 编码并写入系统相册。
 *
 * API 24 推荐方式（无需 WRITE_IMAGEVIDEO 权限）：
 * 1. 编码到 cacheDir 临时文件
 * 2. 在 SaveButton onClick 回调中：
 *    - 使用 MediaAssetChangeRequest.createImageAssetRequest() 创建变更请求
 *    - 调用 applyChanges() 写入相册
 *    - 通过 getAsset().uri 获取媒体 URI
 *
 * 临时文件生命周期：
 * - 编码完成后生成 cacheDir/vivid_export_{timestamp}.{ext}
 * - 写入相册成功后立即删除
 * - 写入失败时也在 catch 中清理
 */
export class PhotoExportService {
  /**
   * 将 PixelMap 编码到 cacheDir 临时文件
   * @param context 应用上下文
   * @param pixelMap 要导出的 PixelMap
   * @param profile 导出配置
   * @returns 临时文件路径，失败返回空字符串
   */
  static async encodeToCacheFile(
    context: common.UIAbilityContext,
    pixelMap: image.PixelMap,
    profile: ExportProfile
  ): Promise<string> {
    const tmpPath = context.cacheDir + `/vivid_export_${Date.now()}${profile.extension}`;

    try {
      const tmpFile = fs.openSync(
        tmpPath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE
      );

      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: profile.mimeType,
        quality: profile.encoderQuality
      };

      await imagePackerApi.packToFile(pixelMap, tmpFile.fd, packOpts);
      fs.closeSync(tmpFile.fd);

      return tmpPath;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Encode failed: ${error.code} - ${error.message}`);
      PhotoExportService.safeUnlink(tmpPath);
      return '';
    }
  }

  /**
   * 通过 SaveButton 安全控件写入系统相册（推荐方式，无需权限）
   *
   * 调用时机：必须在 SaveButton onClick 回调中调用
   *
   * @param context 应用上下文
   * @param cacheFilePath 编码后的临时文件路径
   * @returns 导出结果
   */
  static async saveViaSaveButton(
    context: common.UIAbilityContext,
    cacheFilePath: string
  ): Promise<ExportResult> {
    try {
      if (!fs.accessSync(cacheFilePath)) {
        return {
          success: false,
          errorCode: 'FILE_NOT_FOUND',
          errorMessage: '临时文件不存在'
        };
      }

      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);

      // API 24 推荐：使用 MediaAssetChangeRequest 创建图片资产
      const assetChangeRequest: photoAccessHelper.MediaAssetChangeRequest =
        photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(
          context, cacheFilePath
        );

      await phAccessHelper.applyChanges(assetChangeRequest);

      const mediaUri = assetChangeRequest.getAsset().uri;

      // 清理临时文件
      PhotoExportService.safeUnlink(cacheFilePath);

      return {
        success: true,
        mediaUri: mediaUri
      };
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Save via SaveButton failed: ${error.code} - ${error.message}`);

      // 清理临时文件
      PhotoExportService.safeUnlink(cacheFilePath);

      return {
        success: false,
        errorCode: String(error.code),
        errorMessage: error.message
      };
    }
  }

  /**
   * 通过授权弹窗写入系统相册（备选方式）
   *
   * 会弹出系统授权窗口，用户确认后写入。
   *
   * @param context 应用上下文
   * @param cacheFilePath 编码后的临时文件路径
   * @param fileName 文件名（不含扩展名）
   * @param extension 文件扩展名（如 'jpg', 'png'）
   * @returns 导出结果
   */
  static async saveViaDialog(
    context: common.UIAbilityContext,
    cacheFilePath: string,
    fileName: string,
    extension: string
  ): Promise<ExportResult> {
    try {
      if (!fs.accessSync(cacheFilePath)) {
        return {
          success: false,
          errorCode: 'FILE_NOT_FOUND',
          errorMessage: '临时文件不存在'
        };
      }

      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);

      const srcFileUris: Array<string> = [cacheFilePath];
      const photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [{
        title: fileName,
        fileNameExtension: extension,
        photoType: photoAccessHelper.PhotoType.IMAGE,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT,
      }];

      const desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(
        srcFileUris, photoCreationConfigs
      );

      if (desFileUris.length > 0) {
        const desFile = fs.openSync(desFileUris[0], fs.OpenMode.WRITE_ONLY);
        const srcFile = fs.openSync(cacheFilePath, fs.OpenMode.READ_ONLY);
        fs.copyFileSync(srcFile.fd, desFile.fd);
        fs.closeSync(srcFile.fd);
        fs.closeSync(desFile.fd);

        PhotoExportService.safeUnlink(cacheFilePath);

        return {
          success: true,
          mediaUri: desFileUris[0]
        };
      }

      // 用户取消
      PhotoExportService.safeUnlink(cacheFilePath);

      return {
        success: false,
        errorCode: 'USER_CANCELLED',
        errorMessage: '用户取消了保存操作'
      };
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Save via dialog failed: ${error.code} - ${error.message}`);

      // 清理临时文件
      PhotoExportService.safeUnlink(cacheFilePath);

      return {
        success: false,
        errorCode: String(error.code),
        errorMessage: error.message
      };
    }
  }

  /**
   * 完整导出流程：编码 + 写入相册（旧接口，保留兼容）
   *
   * 注意：此方法需要在用户交互触发的上下文中调用
   */
  static async exportToGallery(
    context: common.UIAbilityContext,
    pixelMap: image.PixelMap,
    profile: ExportProfile
  ): Promise<ExportResult> {
    const tmpPath = await PhotoExportService.encodeToCacheFile(context, pixelMap, profile);

    if (tmpPath === '') {
      return {
        success: false,
        errorCode: 'ENCODE_FAILED',
        errorMessage: '图片编码失败'
      };
    }

    return PhotoExportService.saveViaSaveButton(context, tmpPath);
  }

  /**
   * 安全删除文件，忽略错误
   */
  private static safeUnlink(path: string): void {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (_e) {
      // 忽略清理错误
    }
  }
}
