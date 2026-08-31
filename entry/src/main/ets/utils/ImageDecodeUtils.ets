import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ImageDecodeUtils';

/**
 * 图片解码工具：uri → RGBA_8888 可编辑 PixelMap（V2 §4 AI 输入规格）。
 *
 * 与 ImageRenderService.render 的解码段同构，但独立成 util：
 * - 分割工作图与导出渲染的解码需求不同（1920 上限 vs ExportProfile）；
 * - ImageRenderService 是 B 独占文件，避免交叉依赖。
 */

/** 解码结果：PixelMap + 已缩放后的实际像素尺寸。 */
export interface DecodedImage {
  pixelMap: image.PixelMap;
  width: number;
  height: number;
}

/**
 * 从文件 URI 解码 RGBA_8888 editable PixelMap，最长边超过 maxLongEdge 时按比例缩小。
 *
 * @param uri 文件 URI 或沙箱路径
 * @param maxLongEdge 最长边上限（如 AI_WORK_MAX_EDGE=1920 / PREVIEW_MAX_EDGE）
 * @returns 解码结果；失败抛 Error（message 为 'DECODE_FAILED'，调用方映射 SegErrorCode）
 */
export async function decodeImageFromUri(
  uri: string,
  maxLongEdge: number
): Promise<DecodedImage> {
  let file: fs.File;
  try {
    file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
  } catch (openErr) {
    hilog.error(0x0000, TAG, 'open file failed for %{public}s: %{public}s',
      uri, (openErr as Error).message);
    throw new Error('DECODE_FAILED');
  }
  try {
    const imageSource = image.createImageSource(file.fd);
    const imageInfo = await imageSource.getImageInfo();
    const longEdge = Math.max(imageInfo.size.width, imageInfo.size.height);

    const decodingOptions: image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: 3 // RGBA_8888
    };

    if (maxLongEdge > 0 && longEdge > maxLongEdge) {
      const scale = maxLongEdge / longEdge;
      decodingOptions.desiredSize = {
        width: Math.max(1, Math.round(imageInfo.size.width * scale)),
        height: Math.max(1, Math.round(imageInfo.size.height * scale))
      };
    }

    const pixelMap = await imageSource.createPixelMap(decodingOptions);
    const scaled = await pixelMap.getImageInfo();
    hilog.info(0x0000, TAG,
      'decoded %{public}s -> %{public}dx%d (long edge limit %d)',
      uri, scaled.size.width, scaled.size.height, maxLongEdge);
    const result: DecodedImage = {
      pixelMap: pixelMap,
      width: scaled.size.width,
      height: scaled.size.height
    };
    return result;
  } catch (err) {
    hilog.error(0x0000, TAG, 'decode failed for %{public}s: %{public}s',
      uri, (err as Error).message);
    const failure = new Error('DECODE_FAILED');
    throw failure;
  } finally {
    try {
      fs.closeSync(file.fd);
    } catch (_e) {
      // 句柄已关闭时忽略
    }
  }
}
