import { Theme } from '../components/common/Theme';
import { AppraisalSealType, APPRAISAL_SEALS, ColophonConfig, TraditionalColorItem } from '../models/ColophonModels';
import { image } from '@kit.ImageKit';
import { LengthMetricsUnit } from '@kit.ArkUI';

/**
 * 题跋长卷布局几何参数
 */
export interface ColophonScrollLayout {
  width: number;
  height: number;
  margin: number;
  headerY: number;
  headerHeight: number;
  imageY: number;
  imageWidth: number;
  imageHeight: number;
  metaY: number;
  metaHeight: number;
  paletteY: number;
  paletteHeight: number;
  notesY: number;
  notesHeight: number;
  sealY: number;
  sealHeight: number;
  footerY: number;
}

/**
 * 题跋长卷离屏装裱渲染器
 */
export class ColophonScrollRenderer {
  /**
   * 计算长卷布局尺寸
   */
  static calculateLayout(
    imageW: number,
    imageH: number,
    notesText: string,
    showPalette: boolean,
    canvasWidth: number = 1080
  ): ColophonScrollLayout {
    const margin = 60;
    const headerY = 70;
    const headerHeight = 110;

    const imageY = headerY + headerHeight;
    const imageWidth = canvasWidth - margin * 2;
    // 保持照片画幅比例，高度做合理下限与上限保护
    const aspect = (imageW > 0 && imageH > 0) ? (imageH / imageW) : (3 / 4);
    const calculatedHeight = Math.round(imageWidth * aspect);
    const imageHeight = Math.max(540, Math.min(1300, calculatedHeight));

    const metaY = imageY + imageHeight + 36;
    const metaHeight = 60;

    const paletteY = metaY + metaHeight + 24;
    const paletteHeight = showPalette ? 140 : 0;

    const notesY = paletteY + paletteHeight + (showPalette ? 28 : 10);
    // 根据文字字数估算高度（每行约 32 个汉字，行高 44px）
    const textLen = notesText.length;
    const lineCount = Math.max(2, Math.ceil(textLen / 30));
    const notesHeight = 50 + lineCount * 44;

    const sealY = notesY + notesHeight + 24;
    const sealHeight = 150;

    const footerY = sealY + sealHeight + 20;
    const totalHeight = footerY + 80;

    return {
      width: canvasWidth,
      height: totalHeight,
      margin,
      headerY,
      headerHeight,
      imageY,
      imageWidth,
      imageHeight,
      metaY,
      metaHeight,
      paletteY,
      paletteHeight,
      notesY,
      notesHeight,
      sealY,
      sealHeight,
      footerY
    };
  }

  /**
   * 绘制底纸与边框
   */
  static drawBackground(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    width: number,
    height: number
  ): void {
    // 宣纸底色
    ctx.fillStyle = Theme.PAPER_BASE;
    ctx.fillRect(0, 0, width, height);

    // 古画立轴内边框双线
    ctx.strokeStyle = Theme.OUTLINE_VARIANT;
    ctx.lineWidth = 1;
    ctx.strokeRect(20, 20, width - 40, height - 40);
    ctx.strokeRect(26, 26, width - 52, height - 52);
  }

  /**
   * 绘制天头与题签
   */
  static drawHeader(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    layout: ColophonScrollLayout,
    config: ColophonConfig
  ): void {
    ctx.save();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    // 卷宗大标题
    ctx.fillStyle = Theme.ON_SURFACE;
    ctx.font = 'bold 36px ' + Theme.FONT_SERIF;
    ctx.fillText(config.workTitle, layout.width / 2, layout.headerY + 36);

    // 细墨纹隔线
    ctx.strokeStyle = Theme.PRIMARY;
    ctx.lineWidth = 1.5;
    const lineW = 120;
    ctx.beginPath();
    ctx.moveTo((layout.width - lineW) / 2, layout.headerY + 74);
    ctx.lineTo((layout.width + lineW) / 2, layout.headerY + 74);
    ctx.stroke();

    ctx.restore();
  }

  /**
   * 绘制案卷编号与分隔
   */
  static drawMetadata(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    layout: ColophonScrollLayout,
    config: ColophonConfig
  ): void {
    ctx.save();
    ctx.fillStyle = Theme.ON_SURFACE_VARIANT;
    ctx.font = '18px ' + Theme.FONT_MONO;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';

    const y = layout.metaY + layout.metaHeight / 2;
    ctx.fillText('FILE . NO : ' + config.fileNo, layout.margin + 8, y);

    ctx.textAlign = 'right';
    ctx.fillText('DATE : ' + config.dateText, layout.width - layout.margin - 8, y);

    // 水平分割淡线
    ctx.strokeStyle = Theme.OUTLINE_VARIANT;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(layout.margin, layout.metaY + layout.metaHeight);
    ctx.lineTo(layout.width - layout.margin, layout.metaY + layout.metaHeight);
    ctx.stroke();

    ctx.restore();
  }

  /**
   * 绘制中国传统五色谱带
   */
  static drawPalette(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    layout: ColophonScrollLayout,
    palette: TraditionalColorItem[]
  ): void {
    if (!palette || palette.length === 0 || layout.paletteHeight <= 0) {
      return;
    }

    ctx.save();
    const count = palette.length;
    const totalW = layout.imageWidth;
    const cardGap = 16;
    const cardW = (totalW - (count - 1) * cardGap) / count;
    const cardH = 110;
    const startX = layout.margin;
    const startY = layout.paletteY + 15;

    for (let i = 0; i < count; i++) {
      const item = palette[i];
      const x = startX + i * (cardW + cardGap);

      // 色票白底卡片衬底
      ctx.fillStyle = Theme.PAPER_SURFACE;
      ctx.fillRect(x, startY, cardW, cardH);
      ctx.strokeStyle = Theme.OUTLINE_VARIANT;
      ctx.lineWidth = 1;
      ctx.strokeRect(x, startY, cardW, cardH);

      // 颜色块
      ctx.fillStyle = item.hex;
      ctx.fillRect(x + 8, startY + 8, cardW - 16, 50);

      // 传统色名
      ctx.fillStyle = Theme.ON_SURFACE;
      ctx.font = 'bold 18px ' + Theme.FONT_SERIF;
      ctx.textAlign = 'center';
      ctx.fillText(item.name, x + cardW / 2, startY + 78);

      // 十六进制色值
      ctx.fillStyle = Theme.ON_SURFACE_VARIANT;
      ctx.font = '14px ' + Theme.FONT_MONO;
      ctx.fillText(item.hex, x + cardW / 2, startY + 98);
    }

    ctx.restore();
  }

  /**
   * 绘制案卷批注与题跋正文
   */
  static drawNotes(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    layout: ColophonScrollLayout,
    notesText: string
  ): void {
    ctx.save();

    // 批注标题栏
    ctx.fillStyle = Theme.PRIMARY;
    ctx.fillRect(layout.margin, layout.notesY, 4, 22);

    ctx.fillStyle = Theme.ON_SURFACE;
    ctx.font = 'bold 22px ' + Theme.FONT_SERIF;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';
    ctx.fillText('案卷批注', layout.margin + 14, layout.notesY);

    // 批注文案换行排版
    ctx.font = '22px ' + Theme.FONT_SERIF;
    ctx.fillStyle = Theme.ON_SURFACE;

    const maxW = layout.imageWidth - 20;
    const textY = layout.notesY + 44;
    const chars = notesText.split('');
    let line = '';
    let currentY = textY;

    for (let i = 0; i < chars.length; i++) {
      const testLine = line + chars[i];
      const metrics = ctx.measureText(testLine);
      if (metrics.width > maxW && i > 0) {
        ctx.fillText(line, layout.margin + 10, currentY);
        line = chars[i];
        currentY += 38;
      } else {
        line = testLine;
      }
    }
    if (line.length > 0) {
      ctx.fillText(line, layout.margin + 10, currentY);
    }

    ctx.restore();
  }

  /**
   * 绘制朱砂鉴藏大印
   */
  static drawSeal(
    ctx: CanvasRenderingContext2D | OffscreenCanvasRenderingContext2D,
    layout: ColophonScrollLayout,
    sealType: AppraisalSealType
  ): void {
    ctx.save();

    // 寻找印章 glyph 与 label
    let glyph = '阅';
    for (let i = 0; i < APPRAISAL_SEALS.length; i++) {
      if (APPRAISAL_SEALS[i].type === sealType) {
        glyph = APPRAISAL_SEALS[i].glyph;
        break;
      }
    }

    // 印章尺寸与位置（放在右侧）
    const sealSize = 88;
    const x = layout.width - layout.margin - sealSize - 20;
    const y = layout.sealY + 10;

    // 印泥红底色与双重外框
    ctx.strokeStyle = Theme.SEAL_RED;
    ctx.lineWidth = 3;
    ctx.strokeRect(x, y, sealSize, sealSize);

    ctx.lineWidth = 1;
    ctx.strokeRect(x + 4, y + 4, sealSize - 8, sealSize - 8);

    // 篆刻朱红大字
    ctx.fillStyle = Theme.SEAL_RED;
    ctx.font = 'bold 50px ' + Theme.FONT_SERIF;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(glyph, x + sealSize / 2, y + sealSize / 2);

    // 底部落款
    ctx.fillStyle = Theme.ON_SURFACE_VARIANT;
    ctx.font = '16px ' + Theme.FONT_SERIF;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    ctx.fillText('微霏格物局 · 炎国宝卷', layout.width / 2, layout.footerY + 30);

    ctx.restore();
  }

  /**
   * 将长卷离屏渲染合成为完整海报 PixelMap
   */
  static async renderToPixelMap(
    basePixelMap: image.PixelMap,
    config: ColophonConfig,
    palette: TraditionalColorItem[],
    sealType: AppraisalSealType
  ): Promise<image.PixelMap> {
    const info = await basePixelMap.getImageInfo();
    const layout = ColophonScrollRenderer.calculateLayout(
      info.size.width,
      info.size.height,
      config.notesText,
      config.showColorPalette,
      1080
    );

    const canvas = new OffscreenCanvasRenderingContext2D(
      layout.width,
      layout.height,
      new RenderingContextSettings(true),
      LengthMetricsUnit.PX
    );

    // 1. 宣纸底色与立轴边框
    ColophonScrollRenderer.drawBackground(canvas, layout.width, layout.height);

    // 2. 天头与题签
    ColophonScrollRenderer.drawHeader(canvas, layout, config);

    // 3. 画心图片绘制（居中并保持比例）
    canvas.drawImage(basePixelMap, layout.margin, layout.imageY, layout.imageWidth, layout.imageHeight);

    // 4. 案卷编号与录入日期
    ColophonScrollRenderer.drawMetadata(canvas, layout, config);

    // 5. 国色五谱展示带
    if (config.showColorPalette && palette && palette.length > 0) {
      ColophonScrollRenderer.drawPalette(canvas, layout, palette);
    }

    // 6. 案卷批注
    ColophonScrollRenderer.drawNotes(canvas, layout, config.notesText);

    // 7. 朱砂鉴藏大印与落款
    ColophonScrollRenderer.drawSeal(canvas, layout, sealType);

    return canvas.getPixelMap(0, 0, layout.width, layout.height);
  }
}
