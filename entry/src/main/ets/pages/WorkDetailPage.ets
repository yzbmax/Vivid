import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PageHeader } from '../components/common/PageHeader';
import { PaperFrame } from '../components/common/PaperFrame';
import { MetadataBar, MetadataItem } from '../components/common/MetadataBar';
import { NotesCard } from '../components/common/NotesCard';
import { WorkRecord } from '../models/WorkRecord';
import { mockWorkStore } from '../models/MockWorkStore';
import { WorkSaveService } from '../services/WorkSaveService';
import { PhotoExportService, ExportResult } from '../services/PhotoExportService';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { AppExportSettings, ExportFormat, toExportProfile } from '../models/AppSettingsModels';
import { ExportSettingsDialog } from '../components/common/ExportSettingsDialog';
import { ColophonExportDialog } from '../components/common/ColophonExportDialog';
import { ColorRecipeStore } from '../services/ColorRecipeStore';
import { probeImageDimensions } from '../utils/WorkImageUtils';
import { ExifReaderService } from '../services/ExifReaderService';
import { ImageToneAnalyzer } from '../services/ImageToneAnalyzer';
import { generateWorkDescription, generateAuditSuggestion } from '../models/WorkDescriptionGenerator';
import { common } from '@kit.AbilityKit';

/**
 * 作品详情页（Work Detail，stitch「Work Detail Page」卷宗详情样板）。
 *
 * 从作品页点击作品进入：展示装裱大图、卷宗元数据、案卷批注；
 * 「启封续编」为后续接入独立编辑页（EditPage）的入口，V1 先给轻提示。
 * 独立页面，不显示底部主导航（PRD F9）。
 */

@Entry
@Component
struct WorkDetailPage {
  @State workId: string = '';
  @State work: WorkRecord | null = null;
  @State exporting: boolean = false;
  @State showExportDialog: boolean = false;
  @State showColophonDialog: boolean = false;

  private scroller: Scroller = new Scroller();
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    this.workId = params?.workId ?? '';
    mockWorkStore.init(this.context);
    this.work = mockWorkStore.findById(this.workId);
    this.ensureWorkDimensions();
    this.ensureWorkAnnotation();
  }

  /** 确保卷宗批注与真实照片的直方图明暗、拍摄时间与参数深度关联 */
  private async ensureWorkAnnotation(): Promise<void> {
    if (this.work === null) {
      return;
    }
    const defaultSnippet = '光影均衡，不偏不倚';
    const needsRefresh = !this.work.description ||
      this.work.description.length === 0 ||
      this.work.description.includes(defaultSnippet) ||
      !this.work.toneLabel ||
      this.work.toneLabel.length === 0;

    if (!needsRefresh) {
      return;
    }

    const targetUri = this.work.sourceImageUri || this.work.previewImageUri;
    if (!targetUri || targetUri.length === 0) {
      return;
    }

    try {
      const exif = await ExifReaderService.extractWatermarkInfo(targetUri, this.context);
      const toneResult = await ImageToneAnalyzer.analyzeImageTone(targetUri);

      if (this.work !== null) {
        const newDesc = generateWorkDescription({
          adjustments: this.work.adjustments,
          width: this.work.width,
          height: this.work.height,
          exif: exif,
          toneMetrics: toneResult.metrics,
          audit: toneResult.audit
        });
        const suggestion = generateAuditSuggestion(toneResult.audit);
        this.work.description = newDesc;
        this.work.toneLabel = toneResult.metrics.toneLabel;
        this.work.auditSuggestion = suggestion;
        try {
          mockWorkStore.update(this.work.id, this.work);
        } catch (_e) {}
      }
    } catch (_err) {}
  }

  /** 确保卷宗分辨率尺寸就绪；若旧数据未录入宽高，主动异步探测并持久化回填 */
  private async ensureWorkDimensions(): Promise<void> {
    if (this.work !== null && (this.work.width <= 0 || this.work.height <= 0)) {
      const targetUri = this.work.sourceImageUri || this.work.previewImageUri;
      if (targetUri && targetUri.length > 0) {
        const dims = await probeImageDimensions(targetUri);
        if (dims.width > 0 && dims.height > 0 && this.work !== null) {
          this.applyResolvedDimensions(dims.width, dims.height);
        }
      }
    }
  }

  /** 将解析出的真实宽高应用到当前作品并同步持久化 */
  private applyResolvedDimensions(width: number, height: number): void {
    if (this.work === null || (this.work.width === width && this.work.height === height)) {
      return;
    }
    this.work.width = width;
    this.work.height = height;
    try {
      mockWorkStore.update(this.work.id, this.work);
    } catch (_e) {}
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
      // 提示失败不影响页面
    }
  }

  /** 卷宗元数据三栏 */
  private metadataItems(): MetadataItem[] {
    const w = this.work;
    const resolution = (w !== null && w.width > 0 && w.height > 0)
      ? w.width + ' × ' + w.height
      : '未知';
    const seal = (w !== null && w.sealGlyph.length > 0) ? w.sealGlyph : '无';
    const date = (w !== null) ? this.formatDate(w.date, w.createdAt) : '';
    return [
      { label: '分辨率', value: resolution },
      { label: '保存日期', value: date },
      { label: '封印', value: seal, valueColor: Theme.PRIMARY }
    ];
  }

  /** 日期格式化：优先使用 date 字段，无值时从 createdAt 时间戳生成 YYYY.MM.DD */
  private formatDate(dateStr: string, timestamp: number): string {
    if (dateStr.length > 0) {
      return dateStr;
    }
    if (timestamp <= 0) {
      return '';
    }
    const d = new Date(timestamp);
    const y = d.getFullYear().toString();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return y + '.' + m + '.' + day;
  }

  /** 展卷详阅指引小胶囊：文书钤印古雅风格，点击平滑展开下卷 */
  @Builder
  scrollCuePill() {
    Row({ space: 4 }) {
      Text('展卷详阅 · 案卷批注')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(12)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .letterSpacing(1.2)
      Text('▾')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(12)
        .fontColor(Theme.PRIMARY)
    }
    .padding({ top: 6, bottom: 6, left: 14, right: 14 })
    .backgroundColor(Theme.PRIMARY_05)
    .borderRadius(Theme.RADIUS_FULL)
    .border({ width: 1, color: Theme.PRIMARY_20 })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.scroller.scrollPage({ next: true });
    })
  }

  /** 操作区：导出（ghost）+ 复制配方（ghost）+ 题跋长卷（ghost）+ 启封续编（primary） */
  @Builder
  actionArea() {
    Column() {
      Row({ space: 10 }) {
        // 导出到相册按钮
        Stack({ alignContent: Alignment.Center }) {
          if (this.exporting) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Theme.ON_SURFACE_VARIANT)
          } else {
            Image($r('app.media.icon_archive'))
              .width(20)
              .height(20)
              .fillColor(Theme.ON_SURFACE_VARIANT)
          }
        }
        .width(48)
        .height(52)
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onClick(() => {
          this.exportToGallery();
        })

        // 复制此卷配方按钮
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.icon_copy'))
            .width(20)
            .height(20)
            .fillColor(Theme.ON_SURFACE_VARIANT)
        }
        .width(48)
        .height(52)
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onClick(() => {
          this.copyWorkRecipe();
        })

        // 题跋长卷装裱按钮
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.icon_scroll'))
            .width(20)
            .height(20)
            .fillColor(Theme.ON_SURFACE_VARIANT)
        }
        .width(48)
        .height(52)
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onClick(() => {
          this.showColophonDialog = true;
        })

        Row({ space: 8 }) {
          Image($r('app.media.icon_edit'))
            .width(20)
            .height(20)
            .fillColor(Theme.ON_PRIMARY)
          Text('继续编辑')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(18)
            .fontColor(Theme.ON_PRIMARY)
            .letterSpacing(3)
        }
        .layoutWeight(1)
        .height(52)
        .backgroundColor(Theme.PRIMARY)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.work != null) {
            // 待 C 在 main_pages.json 注册 pages/EditPage 后生效
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/EditPage',
              params: { source: 'work', workId: this.work.id }
            }).catch(() => {
              this.toast('编辑页尚未就绪');
            });
          }
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      left: Theme.MARGIN_MOBILE,
      right: Theme.MARGIN_MOBILE,
      top: 10,
      bottom: 10 + (AppStorage.get<number>('navBarHeight') ?? 0)
    })
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .backdropBlur(20)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
  }

  /** 复制此卷调色配方到剪贴板 */
  private copyWorkRecipe(): void {
    if (this.work == null) {
      return;
    }
    const filterId = this.work.editorSnapshot?.filter?.filterId ?? 'original';
    const filterStrength = this.work.editorSnapshot?.filter?.strength ?? 1.0;
    ColorRecipeStore.copyRecipe(
      this.work.adjustments,
      filterId,
      filterStrength,
      this.work.regionAdjustments,
      this.work.title || '卷宗配方'
    );
    this.toast('调色配方已复制');
  }

  /** 导出到相册 */
  private async exportToGallery(): Promise<void> {
    if (this.exporting || this.work == null) {
      return;
    }

    const shouldPrompt = await AppSettingsStore.isPromptOnExport();
    if (shouldPrompt) {
      this.showExportDialog = true;
      return;
    }

    const defaultSettings = await AppSettingsStore.getExportSettings();
    await this.doExportToGallery(defaultSettings);
  }

  private async doExportToGallery(settings: AppExportSettings, useSaveButton: boolean = false): Promise<void> {
    this.showExportDialog = false;
    if (this.exporting || this.work == null) {
      return;
    }

    this.exporting = true;

    try {
      const result = await WorkSaveService.exportWork(this.context, this.work.id, settings);

      if (!result.success) {
        this.toast(result.errorMessage ?? '导出失败');
        this.exporting = false;
        return;
      }

      if (result.cacheFilePath) {
        let exportResult: ExportResult;
        if (useSaveButton) {
          exportResult = await PhotoExportService.saveViaSaveButton(this.context, result.cacheFilePath, false);
          if (!exportResult.success) {
            const ext = toExportProfile(settings, this.work?.sourceImageUri).extension.replace('.', '');
            exportResult = await PhotoExportService.saveViaDialog(
              this.context,
              result.cacheFilePath,
              `Vivid_${this.work.id}`,
              ext
            );
          }
        } else {
          const ext = toExportProfile(settings, this.work?.sourceImageUri).extension.replace('.', '');
          exportResult = await PhotoExportService.saveViaDialog(
            this.context,
            result.cacheFilePath,
            `Vivid_${this.work.id}`,
            ext
          );
        }

        if (exportResult.success) {
          this.toast('已保存到系统相册「图片」');
          if (this.work) {
            this.work.exportedAssetUri = exportResult.mediaUri ?? '';
          }
        } else if (exportResult.errorCode === 'USER_CANCELLED') {
          this.toast('已取消导出');
        } else {
          this.toast(exportResult.errorMessage ?? '导出失败');
        }
      }
    } catch (_err) {
      this.toast('导出失败');
    } finally {
      this.exporting = false;
    }
  }

  private notesText(): string {
    if (this.work != null && this.work.description.length > 0) {
      return this.work.description;
    }
    return '此卷尚无批注。';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // @Entry 根节点外层布局
      Column() {
        PaperBackground() {
          if (this.work == null) {
            // 无效 workId：显示错误态
            Column() {
              PageHeader({ title: '卷宗详情', showBack: true,
                onBack: () => this.getUIContext().getRouter().back(), topInset: true })
              Column() {
                Text('卷宗不存在')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(18)
                  .fontColor(Theme.ON_SURFACE_VARIANT)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
            .width('100%')
            .height('100%')
          } else {
            Column() {
              // 1. 统一头部标题栏（自顶避让状态栏，常驻固定在页面顶部）
              PageHeader({
                title: this.work!.title,
                showBack: true,
                onBack: () => this.getUIContext().getRouter().back(),
                topInset: true
              })

              // 2. 中间长卷内容滚动区（随手势流畅翻阅，开启卷轴刻度滚动条）
              Scroll(this.scroller) {
                Column() {
                  PaperFrame({
                    image: this.work!.previewImage,
                    imageUri: this.work!.previewImageUri,
                    fileNo: this.work!.id,
                    frameRatio: (this.work!.width > 0 && this.work!.height > 0)
                      ? (this.work!.width / this.work!.height)
                      : 0,
                    onImageSize: (w: number, h: number) => {
                      if (this.work !== null && (this.work.width <= 0 || this.work.height <= 0)) {
                        this.applyResolvedDimensions(w, h);
                      }
                    }
                  })
                    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
                    .margin({ top: 12, bottom: 8 })

                  // 展卷指引提示 pill（提示下方有案卷批注与考评，点击亦可平滑展开下卷）
                  this.scrollCuePill()

                  MetadataBar({ columns: this.metadataItems() })
                    .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 16 })

                  NotesCard({
                    content: this.notesText(),
                    toneLabel: this.work?.toneLabel ?? '',
                    suggestion: this.work?.auditSuggestion ?? '',
                    watermarkGlyph: (this.work?.auditSuggestion && this.work.auditSuggestion.length > 0) ? '待校' : '阅'
                  })
                    .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 20 })
                }
                .width('100%')
                .padding({ bottom: 20 })
              }
              .layoutWeight(1)
              .width('100%')
              .scrollBar(BarState.Auto)
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

              // 3. 底部悬浮常驻操作区（继续编辑 / 题跋长卷 / 复制配方 / 导出）
              this.actionArea()
            }
            .width('100%')
            .height('100%')
          }
        }
      }
      .width('100%')
      .height('100%')

      if (this.showExportDialog) {
        ExportSettingsDialog({
          isVisible: this.showExportDialog,
          imageWidth: this.work?.width ?? 0,
          imageHeight: this.work?.height ?? 0,
          sourceUri: this.work?.sourceImageUri ?? '',
          onConfirm: (settings: AppExportSettings, useSaveButton?: boolean) => {
            this.doExportToGallery(settings, useSaveButton ?? false);
          },
          onCancel: () => {
            this.showExportDialog = false;
          }
        })
      }

      if (this.showColophonDialog) {
        ColophonExportDialog({
          isVisible: this.showColophonDialog,
          work: this.work,
          onClose: () => {
            this.showColophonDialog = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
