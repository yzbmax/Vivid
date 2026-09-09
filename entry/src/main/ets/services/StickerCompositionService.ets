import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { LengthMetricsUnit } from '@kit.ArkUI';
import { StickerSnapshotItem } from '../models/SharedContracts';
import { findStickerTemplate, StickerRenderType } from '../models/EditModels';
import { Theme } from '../components/common/Theme';

/**
 * 贴纸离线合成服务：
 * 负责将贴纸图层在全分辨率下按等比缩放、旋转与透明度准确绘制到基础 PixelMap 上。
 *
 * 依据：《贴纸系统稳健体验优化实施方案》
 * 支持类型：
 * 1. SealStamp（金石闲章：纯矢量绘制朱砂红印面、内界阑与楷体字）
 * 2. CornerFlower / AuspiciousIcon（角花与吉祥图：SVG 媒体资产解码绘制）
 * 3. LabelStrip（签条：宣纸底色色带与题签文字）
 * 4. CustomImage（自定义贴纸 / AI 抠图：从应用沙箱图片文件解码绘制）
 */
export class StickerCompositionService {
  /**
   * 将全部贴纸合成到 basePixelMap 上
   * @param basePixelMap 经过滤镜调色的底层 PixelMap
   * @param stickers 贴纸快照列表
   * @param previewWidth 预览区照片宽度（vp），用于计算等比缩放
   * @param previewHeight 预览区照片高度（vp），用于计算等比缩放
   * @param context 应用上下文（用于加载 SVG 资源）
   * @returns 合成后的新 PixelMap
   */
  static async render(
    basePixelMap: image.PixelMap,
    stickers: StickerSnapshotItem[],
    previewWidth: number,
    previewHeight: number,
    context?: common.UIAbilityContext
  ): Promise<image.PixelMap> {
    if (!stickers || stickers.length === 0) {
      return basePixelMap;
    }

    const info = await basePixelMap.getImageInfo();
    const exportW = info.size.width;
    const exportH = info.size.height;

    // 缩放基准：若未提供有效预览区尺寸，则按导出尺寸回退计算
    const refW = previewWidth > 0 ? previewWidth : exportW;
    const refH = previewHeight > 0 ? previewHeight : exportH;
    const scaleX = exportW / refW;
    const scaleY = exportH / refH;
    // 保持纵横比等比缩放贴纸尺寸
    const scaleSize = (scaleX + scaleY) / 2;

    const canvas = new OffscreenCanvasRenderingContext2D(
      exportW,
      exportH,
      new RenderingContextSettings(true),
      LengthMetricsUnit.PX
    );

    // 1. 绘制底层照片
    canvas.drawImage(basePixelMap, 0, 0, exportW, exportH);

    // 2. 按 zIndex 升序排序，保证层级正确叠加
    const sortedStickers = [...stickers].sort((a, b) => (a.zIndex ?? 0) - (b.zIndex ?? 0));

    // 3. 逐一绘制贴纸
    for (const s of sortedStickers) {
      const tpl = findStickerTemplate(s.templateId);
      const stickerPixelSize = Math.round(s.size * scaleSize);
      if (stickerPixelSize <= 0) {
        continue;
      }

      // 贴纸中心像素位置
      const centerX = Math.round((s.posX + s.size / 2) * scaleX);
      const centerY = Math.round((s.posY + s.size / 2) * scaleY);
      const rotationDeg = s.rotation ?? 0;
      const opacity = Math.max(0.1, Math.min(1.0, s.opacity ?? 1.0));

      canvas.save();
      canvas.translate(centerX, centerY);
      if (rotationDeg !== 0) {
        canvas.rotate((rotationDeg * Math.PI) / 180);
      }
      canvas.globalAlpha = opacity;

      // ── 分支渲染各类贴纸 ──
      const customUri = s.customUri ?? tpl?.customUri;
      if (customUri && customUri.length > 0) {
        await StickerCompositionService.drawCustomImage(canvas, customUri, stickerPixelSize);
      } else if (tpl) {
        if (tpl.renderType === StickerRenderType.SealStamp) {
          StickerCompositionService.drawSealStamp(canvas, tpl.textContent, stickerPixelSize);
        } else if (tpl.renderType === StickerRenderType.LabelStrip) {
          StickerCompositionService.drawLabelStrip(canvas, tpl.textContent, stickerPixelSize);
        } else if (
          (tpl.renderType === StickerRenderType.CornerFlower ||
            tpl.renderType === StickerRenderType.AuspiciousIcon) &&
          tpl.resource &&
          context
        ) {
          await StickerCompositionService.drawMediaResource(canvas, tpl.resource, stickerPixelSize, context);
        }
      }

      canvas.restore();
    }

    return canvas.getPixelMap(0, 0, exportW, exportH);
  }

  /** 绘制金石闲章（纯矢量印面 + 内界阑 + 楷体字） */
  private static drawSealStamp(
    canvas: OffscreenCanvasRenderingContext2D,
    text: string,
    size: number
  ): void {
    const sealBoxSize = Math.round(size * 0.85);
    const halfBox = Math.round(sealBoxSize / 2);
    const borderWidth = Math.max(2, Math.round(sealBoxSize * 0.04));

    // 朱砂红底印面
    canvas.fillStyle = Theme.PRIMARY;
    canvas.fillRect(-halfBox, -halfBox, sealBoxSize, sealBoxSize);

    // 外圈金石印边
    canvas.lineWidth = borderWidth;
    canvas.strokeStyle = Theme.SEAL_RED;
    canvas.strokeRect(-halfBox, -halfBox, sealBoxSize, sealBoxSize);

    // 内界阑轻微留白边线（文人篆刻经典边栏）
    const innerPadding = Math.max(2, Math.round(sealBoxSize * 0.06));
    const innerSize = sealBoxSize - innerPadding * 2;
    canvas.lineWidth = Math.max(1, Math.round(borderWidth * 0.4));
    canvas.strokeStyle = 'rgba(255, 255, 255, 0.35)';
    canvas.strokeRect(-innerSize / 2, -innerSize / 2, innerSize, innerSize);

    // 楷体印文
    const fontSize = Math.round(size * 0.42);
    canvas.fillStyle = '#FFFFFF';
    canvas.font = `bold ${fontSize}px "Kai", "Noto Serif SC"`;
    canvas.textAlign = 'center';
    canvas.textBaseline = 'middle';
    canvas.fillText(text, 0, 0);
  }

  /** 绘制题签条条带 */
  private static drawLabelStrip(
    canvas: OffscreenCanvasRenderingContext2D,
    text: string,
    size: number
  ): void {
    const stripW = Math.round(size * 1.6);
    const stripH = Math.round(size * 0.45);
    const halfW = Math.round(stripW / 2);
    const halfH = Math.round(stripH / 2);

    // 宣纸底色
    canvas.fillStyle = Theme.PAPER_SURFACE;
    canvas.fillRect(-halfW, -halfH, stripW, stripH);

    // 纸张边框
    canvas.lineWidth = Math.max(1, Math.round(size * 0.02));
    canvas.strokeStyle = Theme.OUTLINE_VARIANT;
    canvas.strokeRect(-halfW, -halfH, stripW, stripH);

    // 签条文字
    const fontSize = Math.round(size * 0.26);
    canvas.fillStyle = Theme.ON_SURFACE;
    canvas.font = `500 ${fontSize}px "Noto Serif SC"`;
    canvas.textAlign = 'center';
    canvas.textBaseline = 'middle';
    canvas.fillText(text, 0, 0);
  }

  /** 绘制自定义图片 / AI 抠图 */
  private static async drawCustomImage(
    canvas: OffscreenCanvasRenderingContext2D,
    fileUri: string,
    size: number
  ): Promise<void> {
    try {
      let cleanPath = fileUri;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.substring(7);
      }
      if (fs.accessSync(cleanPath)) {
        const imageSource = image.createImageSource(cleanPath);
        const pixelMap = await imageSource.createPixelMap();
        const half = Math.round(size / 2);
        canvas.drawImage(pixelMap, -half, -half, size, size);
        pixelMap.release();
      }
    } catch (_e) {
      // 容错降级
    }
  }

  /** 绘制系统矢量 Resource 资源（角花 / 吉祥图） */
  private static async drawMediaResource(
    canvas: OffscreenCanvasRenderingContext2D,
    resource: Resource,
    size: number,
    context: common.UIAbilityContext
  ): Promise<void> {
    try {
      const resMgr = context.resourceManager;
      const mediaBytes = await resMgr.getMediaContent(resource.id);
      const imageSource = image.createImageSource(mediaBytes.buffer);
      const pixelMap = await imageSource.createPixelMap();
      const half = Math.round(size / 2);
      canvas.drawImage(pixelMap, -half, -half, size, size);
      pixelMap.release();
    } catch (_e) {
      // 容错降级
    }
  }
}
