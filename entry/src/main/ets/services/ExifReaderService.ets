import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { WatermarkConfig, defaultWatermarkConfig } from '../models/SharedContracts';
import {
  formatFocalLength,
  formatFNumber,
  formatExposureTime,
  formatIso,
  formatExifDateTime
} from '../features/editor/border/ExifFormatUtils';

/**
 * EXIF 拍摄参数解析服务：负责从照片文件提取机型、镜头、曝光参数与拍摄时间。
 */
export class ExifReaderService {
  /**
   * 从图片 URI 中提取 EXIF 拍摄信息
   */
  static async extractWatermarkInfo(imageUri: string, context?: common.UIAbilityContext): Promise<Partial<WatermarkConfig>> {
    const result: Partial<WatermarkConfig> = {};
    if (!imageUri || imageUri.length === 0) {
      return result;
    }
    let imageSource: image.ImageSource | null = null;
    let file: fs.File | null = null;
    try {
      if (imageUri.startsWith('file://') || imageUri.startsWith('/')) {
        const filePath = imageUri.startsWith('file://') ? imageUri.substring(7) : imageUri;
        file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
        imageSource = image.createImageSource(file.fd);
      } else {
        imageSource = image.createImageSource(imageUri);
      }
      if (!imageSource) {
        return result;
      }

      // 1. 读取设备机型与厂商
      let model = '';
      try {
        model = await imageSource.getImageProperty(image.PropertyKey.MODEL);
      } catch (_) {}

      let make = '';
      try {
        make = await imageSource.getImageProperty(image.PropertyKey.MAKE);
      } catch (_) {}

      if (model && model.trim().length > 0) {
        const trimModel = model.trim();
        const trimMake = make ? make.trim() : '';
        if (trimMake && !trimModel.toLowerCase().includes(trimMake.toLowerCase())) {
          result.deviceModel = `${trimMake} ${trimModel}`;
        } else {
          result.deviceModel = trimModel;
        }

        // 自动推导品牌徽标
        const fullLower = (result.deviceModel || '').toLowerCase();
        if (fullLower.includes('vivo') || fullLower.includes('zeiss')) {
          result.logo = 'zeiss';
        } else if (fullLower.includes('huawei') || fullLower.includes('xmage')) {
          result.logo = 'xmage';
        } else if (fullLower.includes('xiaomi') || fullLower.includes('leica')) {
          result.logo = 'leica';
        } else if (fullLower.includes('oppo') || fullLower.includes('hasselblad')) {
          result.logo = 'hasselblad';
        } else if (fullLower.includes('iphone') || fullLower.includes('apple')) {
          result.logo = 'apple';
        } else if (fullLower.includes('sony')) {
          result.logo = 'sony';
        } else if (fullLower.includes('canon')) {
          result.logo = 'canon';
        } else if (fullLower.includes('nikon')) {
          result.logo = 'nikon';
        }
      }

      // 2. 读取焦距（优先 35mm 等效焦距）、光圈、快门、ISO
      let focal35 = '';
      let focalPhysical = '';
      let fNumber = '';
      let expTime = '';
      let iso = '';
      try {
        focal35 = await imageSource.getImageProperty(image.PropertyKey.FOCAL_LENGTH_IN_35_MM_FILM);
      } catch (_) {}
      try {
        focalPhysical = await imageSource.getImageProperty(image.PropertyKey.FOCAL_LENGTH);
      } catch (_) {}
      try {
        fNumber = await imageSource.getImageProperty(image.PropertyKey.F_NUMBER);
      } catch (_) {}
      try {
        expTime = await imageSource.getImageProperty(image.PropertyKey.EXPOSURE_TIME);
      } catch (_) {}
      try {
        iso = await imageSource.getImageProperty(image.PropertyKey.ISO_SPEED_RATINGS);
      } catch (_) {}

      const paramsParts: string[] = [];
      const focalFormatted = formatFocalLength(focal35, focalPhysical);
      if (focalFormatted.length > 0) {
        paramsParts.push(focalFormatted);
      }
      const fnFormatted = formatFNumber(fNumber);
      if (fnFormatted.length > 0) {
        paramsParts.push(fnFormatted);
      }
      const expFormatted = formatExposureTime(expTime);
      if (expFormatted.length > 0) {
        paramsParts.push(expFormatted);
      }
      const isoFormatted = formatIso(iso);
      if (isoFormatted.length > 0) {
        paramsParts.push(isoFormatted);
      }

      if (paramsParts.length > 0) {
        result.paramsText = paramsParts.join('  ');
      }

      // 3. 读取拍摄时间
      let dateTime = '';
      try {
        dateTime = await imageSource.getImageProperty(image.PropertyKey.DATE_TIME_ORIGINAL);
      } catch (_) {}
      const timeFormatted = formatExifDateTime(dateTime);
      if (timeFormatted.length > 0) {
        result.timeText = timeFormatted;
      }
    } catch (err) {
      console.warn(`Failed to extract EXIF from ${imageUri}: ${JSON.stringify(err)}`);
    } finally {
      if (file) {
        try {
          fs.closeSync(file);
        } catch (_) {}
      }
    }
    return result;
  }
}
