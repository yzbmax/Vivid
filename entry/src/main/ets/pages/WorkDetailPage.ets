import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PageHeader } from '../components/common/PageHeader';
import { PaperFrame } from '../components/common/PaperFrame';
import { MetadataBar, MetadataItem } from '../components/common/MetadataBar';
import { NotesCard } from '../components/common/NotesCard';
import { WorkRecord } from '../models/WorkRecord';
import { mockWorkStore } from '../models/MockWorkStore';
import { WorkSaveService } from '../services/WorkSaveService';
import { PhotoExportService } from '../services/PhotoExportService';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { AppExportSettings, ExportFormat, toExportProfile } from '../models/AppSettingsModels';
import { ExportSettingsDialog } from '../components/common/ExportSettingsDialog';
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

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    this.workId = params?.workId ?? '';
    mockWorkStore.init(this.context);
    this.work = mockWorkStore.findById(this.workId);
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

  /** 操作区：导出（ghost）+ 启封续编（primary） */
  @Builder
  actionArea() {
    Row({ space: 16 }) {
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
      .width(64)
      .height(56)
      .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
      .onClick(() => {
        this.exportToGallery();
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
      .height(56)
      .backgroundColor(Theme.PRIMARY)
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
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
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

  private async doExportToGallery(settings: AppExportSettings): Promise<void> {
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
        const ext = toExportProfile(settings, this.work?.sourceImageUri).extension.replace('.', '');
        const exportResult = await PhotoExportService.saveViaDialog(
          this.context,
          result.cacheFilePath,
          `Vivid_${this.work.id}`,
          ext
        );

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
            Scroll() {
              Column() {
                // 统一头部标题栏（自顶避让状态栏，背景延伸至屏幕顶部）
                PageHeader({ title: this.work!.title, showBack: true,
                  onBack: () => this.getUIContext().getRouter().back(), topInset: true })
                PaperFrame({ image: this.work!.previewImage, imageUri: this.work!.previewImageUri, fileNo: this.work!.id })
                  .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
                  .margin({ bottom: 32 })
                MetadataBar({ columns: this.metadataItems() })
                  .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 24 })
                NotesCard({ content: this.notesText() })
                  .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 32 })
                this.actionArea()
              }
              .width('100%')
              .padding({ bottom: 32 })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
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
          onConfirm: (settings: AppExportSettings) => {
            this.doExportToGallery(settings);
          },
          onCancel: () => {
            this.showExportDialog = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
