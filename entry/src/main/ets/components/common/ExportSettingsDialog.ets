import { Theme } from './Theme';
import {
  AppExportSettings,
  ExportFormat,
  ExportQuality,
  ImageDimensions,
  estimateExportFileSize,
  formatEstimatedFileSize,
  resolveExportDimensions
} from '../../models/AppSettingsModels';
import { AppSettingsStore } from '../../models/AppSettingsStore';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';

/**
 * 卷宗导出规格确认弹窗（ExportSettingsDialog）
 *
 * 依据：Mask & Seal 设计规范
 * - 宣纸质感底座与朱砂装裱细边
 * - 导出时弹窗询问画质（超清/高清/标准）与格式（JPEG/PNG/WebP/HEIF/源格式）
 * - 明确标明原画分辨率尺寸（宽 × 高 px），并在各档位展示目标分辨率
 * - 实时显示导出文件预估存储大小（按画质、格式与画幅动态计算）
 * - 自动记忆用户选择为下一次预设
 */
@Component
export struct ExportSettingsDialog {
  @Prop isVisible: boolean = false;
  @Prop imageWidth: number = 0;
  @Prop imageHeight: number = 0;
  @Prop sourceUri: string = '';
  @State selectedQuality: ExportQuality = ExportQuality.Ultra;
  @State selectedFormat: ExportFormat = ExportFormat.JPEG;
  @State realWidth: number = 0;
  @State realHeight: number = 0;
  onConfirm: (settings: AppExportSettings) => void = () => {};
  onCancel: () => void = () => {};

  aboutToAppear(): void {
    this.loadDefaultSettings();
    this.realWidth = this.imageWidth;
    this.realHeight = this.imageHeight;
    if ((this.realWidth <= 0 || this.realHeight <= 0) && this.sourceUri && this.sourceUri.length > 0) {
      this.resolveDimensionsFromSource();
    }
  }

  private async resolveDimensionsFromSource(): Promise<void> {
    try {
      let localPath = this.sourceUri.trim();
      if (localPath.startsWith('file://')) {
        localPath = localPath.substring(7);
      }
      if (fs.accessSync(localPath)) {
        const imageSource = image.createImageSource(localPath);
        const info = await imageSource.getImageInfo();
        if (info.size.width > 0 && info.size.height > 0) {
          this.realWidth = info.size.width;
          this.realHeight = info.size.height;
        }
        imageSource.release();
      }
    } catch (_e) {
      // 容错降级
    }
  }

  private async loadDefaultSettings(): Promise<void> {
    try {
      const current = await AppSettingsStore.getExportSettings();
      this.selectedQuality = current.quality;
      this.selectedFormat = current.format;
    } catch (_e) {
      // 读取失败保持超清+JPEG默认
    }
  }

  private async handleConfirm(): Promise<void> {
    const settings: AppExportSettings = {
      quality: this.selectedQuality,
      format: this.selectedFormat
    };
    try {
      await AppSettingsStore.setExportQuality(this.selectedQuality);
      await AppSettingsStore.setExportFormat(this.selectedFormat);
    } catch (_e) {
      // 容错不阻断导出
    }
    this.onConfirm(settings);
  }

  build() {
    if (this.isVisible) {
      Stack({ alignContent: Alignment.Center }) {
        // 半透明宣纸暗色遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(36, 25, 24, 0.48)')
          .backdropBlur(10)
          .onClick(() => this.onCancel())

        // 居中文书装裱规格卡片
        Column() {
          // 顶部 3vp 朱砂金线装裱条
          Row()
            .width('100%')
            .height(3)
            .backgroundColor(Theme.PRIMARY)

          Column({ space: 16 }) {
            // 顶栏：朱砂方印徽记 + 标题 + 关闭按钮
            Row() {
              // 朱砂方印微徽
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(20)
                  .height(20)
                  .border({ width: 0.8, color: 'rgba(242, 241, 237, 0.5)' })
                  .borderRadius(1)
                Text('印')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.PAPER_SURFACE)
              }
              .width(26)
              .height(26)
              .borderRadius(Theme.RADIUS_DEFAULT)
              .backgroundColor(Theme.PRIMARY)
              .margin({ right: 10 })

              Column({ space: 1 }) {
                Text('落印导出 · 卷宗规制')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ON_SURFACE)
                  .letterSpacing(1)

                Text('EXPORT SPECIFICATION')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(9)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.PRIMARY)
                  .letterSpacing(1.2)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              // 关闭按钮
              Text('✕')
                .fontFamily(Theme.FONT_SANS)
                .fontSize(16)
                .fontColor(Theme.OUTLINE)
                .padding(4)
                .onClick(() => this.onCancel())
            }
            .width('100%')

            // 分割细线
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(Theme.PRIMARY_20)

            // 规格区块 1：导出画质
            Column({ space: 8 }) {
              Row() {
                Row({ space: 4 }) {
                  Text('画质规制')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.ON_SURFACE)
                  Text(' · RESOLUTION')
                    .fontFamily(Theme.FONT_MONO)
                    .fontSize(9)
                    .fontColor(Theme.PRIMARY)
                    .letterSpacing(1)
                }

                Blank()

                // 右侧明确标出原画的分辨率尺寸
                Row({ space: 4 }) {
                  Text('原画尺寸')
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(10)
                    .fontColor(Theme.ON_SURFACE_VARIANT)
                  Text(this.getOriginalResolutionText())
                    .fontFamily(Theme.FONT_MONO)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.PRIMARY)
                }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(Theme.PRIMARY_05)
                .borderRadius(Theme.RADIUS_DEFAULT)
              }
              .width('100%')

              // 3 选 1 分段选项
              Row({ space: 8 }) {
                this.QualityOption(ExportQuality.Ultra, '超清', this.getQualityOptionSubtitle(ExportQuality.Ultra))
                this.QualityOption(ExportQuality.High, '高清', this.getQualityOptionSubtitle(ExportQuality.High))
                this.QualityOption(ExportQuality.Standard, '标准', this.getQualityOptionSubtitle(ExportQuality.Standard))
              }
              .width('100%')

              // 动态画质说明
              Text(this.getQualityDescription())
                .fontFamily(Theme.FONT_SANS)
                .fontSize(11)
                .fontColor(Theme.ON_SURFACE_VARIANT)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 规格区块 2：导出格式
            Column({ space: 8 }) {
              Row() {
                Text('图像格式')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ON_SURFACE)
                Text(' · ENCODING')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(10)
                  .fontColor(Theme.PRIMARY)
              }
              .width('100%')

              // 5 项格式选项（首行「源格式」，后随 2 行 × 2 列）
              Column({ space: 6 }) {
                Row() {
                  this.FormatOption(ExportFormat.ORIGINAL, '源格式', '与原图格式一致（自适应）')
                }
                .width('100%')

                Row({ space: 6 }) {
                  this.FormatOption(ExportFormat.JPEG, 'JPEG', '常规通用')
                  this.FormatOption(ExportFormat.PNG, 'PNG', '无损高保真')
                }
                .width('100%')

                Row({ space: 6 }) {
                  this.FormatOption(ExportFormat.WEBP, 'WebP', '现代高效')
                  this.FormatOption(ExportFormat.HEIF, 'HEIF', '高保真压缩')
                }
                .width('100%')
              }
              .width('100%')

              // 动态格式说明
              Text(this.getFormatDescription())
                .fontFamily(Theme.FONT_SANS)
                .fontSize(11)
                .fontColor(Theme.ON_SURFACE_VARIANT)
                .margin({ top: 2 })
            }
            // 规格区块 3：预估存储占用
            Row() {
              Row({ space: 6 }) {
                Text('预估体积')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ON_SURFACE)
                Text(' · ESTIMATE')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(9)
                  .fontColor(Theme.PRIMARY)
                  .letterSpacing(1)
              }

              Blank()

              Row({ space: 4 }) {
                Text(this.getEstimatedSizeText())
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.PRIMARY)
                Text('（依画面复杂度浮动）')
                  .fontFamily(Theme.FONT_SANS)
                  .fontSize(10)
                  .fontColor(Theme.ON_SURFACE_VARIANT)
              }
            }
            .width('100%')
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(Theme.PRIMARY_05)
            .border({ width: 0.8, color: Theme.OUTLINE_VARIANT })
            .borderRadius(Theme.RADIUS_DEFAULT)

            // 底部操作按钮
            Row({ space: 10 }) {
              Button('取消')
                .layoutWeight(1)
                .height(42)
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(14)
                .fontColor(Theme.ON_SURFACE_VARIANT)
                .backgroundColor(Theme.PAPER_BASE)
                .border({ width: 1, color: Theme.OUTLINE_VARIANT })
                .borderRadius(Theme.RADIUS_DEFAULT)
                .onClick(() => this.onCancel())

              Button('确认落印导出')
                .layoutWeight(2)
                .height(42)
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.ON_PRIMARY)
                .backgroundColor(Theme.PRIMARY)
                .borderRadius(Theme.RADIUS_DEFAULT)
                .shadow({ radius: 4, color: 'rgba(123, 23, 27, 0.3)', offsetY: 1 })
                .onClick(() => this.handleConfirm())
            }
            .width('100%')
            .margin({ top: 4 })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 16, bottom: 18 })
        }
        .width('88%')
        .backgroundColor(Theme.PAPER_SURFACE)
        .border({ width: 1, color: Theme.PRIMARY_20 })
        .borderRadius(Theme.RADIUS_DEFAULT)
        .shadow({ radius: 16, color: 'rgba(36, 25, 24, 0.25)', offsetY: 4 })
        .clip(true)
      }
      .width('100%')
      .height('100%')
      .zIndex(999)
    }
  }

  @Builder
  QualityOption(quality: ExportQuality, title: string, subtitle: string) {
    Column({ space: 2 }) {
      Text(title)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedQuality === quality ? Theme.PRIMARY : Theme.ON_SURFACE)

      Text(subtitle)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(10)
        .fontColor(this.selectedQuality === quality ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.selectedQuality === quality ? Theme.PRIMARY_05 : Theme.PAPER_SURFACE)
    .border({
      width: this.selectedQuality === quality ? 1.5 : 1,
      color: this.selectedQuality === quality ? Theme.PRIMARY : Theme.OUTLINE_VARIANT
    })
    .borderRadius(Theme.RADIUS_DEFAULT)
    .onClick(() => {
      this.selectedQuality = quality;
    })
  }

  @Builder
  FormatOption(format: ExportFormat, title: string, subtitle: string) {
    Column({ space: 2 }) {
      Text(title)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedFormat === format ? Theme.PRIMARY : Theme.ON_SURFACE)

      Text(subtitle)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(10)
        .fontColor(this.selectedFormat === format ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.selectedFormat === format ? Theme.PRIMARY_05 : Theme.PAPER_SURFACE)
    .border({
      width: this.selectedFormat === format ? 1.5 : 1,
      color: this.selectedFormat === format ? Theme.PRIMARY : Theme.OUTLINE_VARIANT
    })
    .borderRadius(Theme.RADIUS_DEFAULT)
    .onClick(() => {
      this.selectedFormat = format;
    })
  }

  private getEffectiveWidth(): number {
    if (this.realWidth > 0) {
      return this.realWidth;
    }
    if (this.imageWidth > 0) {
      return this.imageWidth;
    }
    return 4000;
  }

  private getEffectiveHeight(): number {
    if (this.realHeight > 0) {
      return this.realHeight;
    }
    if (this.imageHeight > 0) {
      return this.imageHeight;
    }
    return 3000;
  }

  private getOriginalResolutionText(): string {
    const w = this.getEffectiveWidth();
    const h = this.getEffectiveHeight();
    return `${w} × ${h}`;
  }

  private getQualityOptionSubtitle(quality: ExportQuality): string {
    const dims: ImageDimensions = resolveExportDimensions(
      quality,
      this.getEffectiveWidth(),
      this.getEffectiveHeight()
    );
    return `${dims.width}×${dims.height}`;
  }

  private getQualityDescription(): string {
    const w = this.getEffectiveWidth();
    const h = this.getEffectiveHeight();
    if (this.selectedQuality === ExportQuality.Ultra) {
      return `◆ 原画尺寸（${w} × ${h} px），完整保留最高解析力与精细画质（推荐）`;
    }
    if (this.selectedQuality === ExportQuality.High) {
      const dims: ImageDimensions = resolveExportDimensions(ExportQuality.High, w, h);
      return `◆ 2K 尺寸（${dims.width} × ${dims.height} px · 长边限 2560px），兼顾细腻锐度与适中体积`;
    }
    const dims: ImageDimensions = resolveExportDimensions(ExportQuality.Standard, w, h);
    return `◆ 1080P 尺寸（${dims.width} × ${dims.height} px · 长边限 1920px），适宜快速网络流转与社交分享`;
  }

  private getFormatDescription(): string {
    if (this.selectedFormat === ExportFormat.ORIGINAL) {
      return '◆ 智能识别并沿用输入原图格式（JPEG / PNG / WebP / HEIF），自适应编码';
    }
    if (this.selectedFormat === ExportFormat.PNG) {
      return '◆ 100% 无损编码，边缘平滑无失真，适合精细图文与二次批注';
    }
    if (this.selectedFormat === ExportFormat.WEBP) {
      return '◆ 现代高效图像格式，相同画质下相比 JPEG 缩减约 30% 存储体积';
    }
    if (this.selectedFormat === ExportFormat.HEIF) {
      return '◆ 旗舰高保真格式，具备更宽广的色彩动态范围与极高压缩比';
    }
    return '◆ 标准高效压缩，通用兼容性最佳，绝大多数设备均可直接查验';
  }

  private getEstimatedSizeText(): string {
    const bytes = estimateExportFileSize(
      this.selectedQuality,
      this.selectedFormat,
      this.getEffectiveWidth(),
      this.getEffectiveHeight(),
      this.sourceUri
    );
    return formatEstimatedFileSize(bytes);
  }
}
