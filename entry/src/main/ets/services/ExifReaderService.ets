import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { WatermarkConfig, defaultWatermarkConfig, WatermarkLogoType } from '../models/SharedContracts';
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
        const inferred = inferLogoFromDeviceModel(result.deviceModel || '');
        if (inferred === 'none') {
          result.logo = 'none';
        } else {
          result.logo = inferred;
        }
      }

      // 1.1 读取镜头型号
      let lens = '';
      try {
        lens = await imageSource.getImageProperty(image.PropertyKey.LENS_MODEL);
      } catch (_) {}
      if (!lens || lens.trim().length === 0) {
        try {
          lens = await imageSource.getImageProperty('LensModel');
        } catch (_) {}
      }
      if (lens && lens.trim().length > 0) {
        result.lensModel = lens.trim();
        result.showLens = true;
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
      } else if (file) {
        try {
          const stat = fs.statSync(file.fd);
          if (stat && stat.mtime) {
            const date = new Date(stat.mtime * 1000);
            const y = date.getFullYear();
            const m = String(date.getMonth() + 1).padStart(2, '0');
            const d = String(date.getDate()).padStart(2, '0');
            const hh = String(date.getHours()).padStart(2, '0');
            const mm = String(date.getMinutes()).padStart(2, '0');
            result.timeText = `${y}.${m}.${d} ${hh}:${mm}`;
          }
        } catch (_) {}
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

/**
 * 根据机型文本或厂商信息智能推导对应的水印品牌标识。
 * 遵循合规要求：界面不明文呈现候选品牌列表，纯靠 EXIF 提取或用户输入自适应匹配。
 */
export function inferLogoFromDeviceModel(deviceModel: string): WatermarkLogoType {
  if (!deviceModel || deviceModel.trim().length === 0) {
    return 'none';
  }
  const fullLower = deviceModel.trim().toLowerCase();
  if (fullLower.includes('vivo') || fullLower.includes('zeiss') || fullLower.includes('蔡司')) {
    return 'zeiss';
  } else if (fullLower.includes('huawei') || fullLower.includes('xmage') || fullLower.includes('华为')) {
    return 'none';
  } else if (fullLower.includes('xiaomi') || fullLower.includes('leica') || fullLower.includes('徕卡')) {
    return 'leica';
  } else if (fullLower.includes('oppo') || fullLower.includes('hasselblad') || fullLower.includes('哈苏')) {
    return 'hasselblad';
  } else if (fullLower.includes('iphone') || fullLower.includes('apple') || fullLower.includes('苹果')) {
    return 'apple';
  } else if (fullLower.includes('sony') || fullLower.includes('ilce') || fullLower.includes('alpha') || fullLower.includes('索尼')) {
    return 'sony';
  } else if (fullLower.includes('canon') || fullLower.includes('佳能')) {
    return 'canon';
  } else if (fullLower.includes('nikon') || fullLower.includes('尼康')) {
    return 'nikon';
  } else if (fullLower.includes('fujifilm') || fullLower.includes('fuji') || fullLower.includes('富士')) {
    return 'fujifilm';
  } else if (fullLower.includes('samsung') || fullLower.includes('galaxy') || fullLower.includes('三星')) {
    return 'samsung';
  } else if (fullLower.includes('honor') || fullLower.includes('荣耀')) {
    return 'honor';
  }
  return 'none';
}
