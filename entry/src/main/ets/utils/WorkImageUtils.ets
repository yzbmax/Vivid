import { fileIo as fs } from '@kit.CoreFileKit';

/**
 * 规范化并解析作品卡片的图片源：
 * 1. 优先使用 previewUri（渲染后的作品缩略图），其次 sourceUri（源图），再次 Resource，最后兜底作品图。
 * 2. 补全 file:// 前缀（ArkUI Image 加载应用沙箱文件必须以 file:// 开头）。
 * 3. 自动修复旧版 .image 命名：若文件在磁盘上存在但名为 .image，自动创建 .image.jpg 兼容副本并返回，确保 ArkUI 能正确识别 JPEG/PNG 解码器。
 * 4. 若文件已不存在（如临时缓存被清空），安全优雅回退到内置画作资源，避免出现白板/粉红空卡片。
 */
export function resolveWorkImageSource(
  previewUri?: string,
  sourceUri?: string,
  resourceImage?: Resource | null
): ResourceStr {
  // 1. 优先尝试预览图 URI
  if (previewUri && previewUri.trim().length > 0) {
    const fixed = fixAndNormalizePath(previewUri.trim());
    if (fixed.length > 0) {
      return fixed;
    }
  }

  // 2. 其次尝试源图 URI
  if (sourceUri && sourceUri.trim().length > 0) {
    const fixed = fixAndNormalizePath(sourceUri.trim());
    if (fixed.length > 0) {
      return fixed;
    }
  }

  // 3. 再次尝试 Resource 资源
  if (resourceImage !== null && resourceImage !== undefined) {
    return resourceImage;
  }

  // 4. 兜底画作封面
  return $r('app.media.work_mountain');
}

/**
 * 将路径规范化为标准 file:// URI，并处理 .image 兼容
 */
export function fixAndNormalizePath(uri: string): string {
  if (!uri || uri.trim().length === 0) {
    return '';
  }
  const clean = uri.trim();
  let path = clean;
  if (path.startsWith('file://')) {
    path = path.substring(7);
  }

  // 本地绝对路径处理
  if (path.startsWith('/')) {
    try {
      let fileExists = false;
      try {
        fileExists = fs.accessSync(path);
      } catch (_) {
        fileExists = false;
      }

      if (fileExists) {
        // 如果文件以 .image 结尾，ArkUI 无法识别格式，生成 .image.jpg 别名
        if (path.endsWith('.image')) {
          const jpgPath = path + '.jpg';
          try {
            let jpgExists = false;
            try {
              jpgExists = fs.accessSync(jpgPath);
            } catch (_) {
              jpgExists = false;
            }
            if (!jpgExists) {
              fs.copyFileSync(path, jpgPath);
            }
            return 'file://' + jpgPath;
          } catch (_) {
            return 'file://' + path;
          }
        }
        return 'file://' + path;
      } else {
        // 检查是否有对应的 .jpg
        let jpgExists = false;
        try {
          jpgExists = fs.accessSync(path + '.jpg');
        } catch (_) {
          jpgExists = false;
        }
        if (jpgExists) {
          return 'file://' + path + '.jpg';
        }
        // 本地文件在磁盘上不存在，返回空字符串让上层优雅降级
        return '';
      }
    } catch (_) {
      return '';
    }
  }

  return clean;
}
