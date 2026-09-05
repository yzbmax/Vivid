import { MASK_SEAL, SealPaperBackground, SettingRow } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
import { Theme } from '../components/common/Theme';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { AppExportSettings, ExportFormat, ExportQuality } from '../models/AppSettingsModels';
import { ExportSettingsDialog } from '../components/common/ExportSettingsDialog';

@Entry
@Component
struct AppSettingsPage {
  @State exportQuality: ExportQuality = ExportQuality.Standard;
  @State exportFormat: ExportFormat = ExportFormat.JPEG;
  @State promptOnExport: boolean = true;
  @State showExportDialog: boolean = false;

  aboutToAppear(): void {
    this.loadExportSettings();
  }

  private async loadExportSettings(): Promise<void> {
    try {
      const settings = await AppSettingsStore.getExportSettings();
      this.exportQuality = settings.quality;
      this.exportFormat = settings.format;
      this.promptOnExport = await AppSettingsStore.isPromptOnExport();
    } catch (err) {
      this.showToast('导出设置读取失败，已使用默认值');
    }
  }

  private async togglePromptOnExport(value: boolean): Promise<void> {
    this.promptOnExport = value;
    try {
      await AppSettingsStore.setPromptOnExport(value);
      this.showToast(value ? '已开启：照片导出时弹窗询问' : '已关闭弹窗，导出将直接使用预设值');
    } catch (_err) {
      this.showToast('设置保存失败');
    }
  }

  private async selectQuality(value: ExportQuality): Promise<void> {
    if (this.exportQuality === value) {
      return;
    }
    const previous: ExportQuality = this.exportQuality;
    this.exportQuality = value;
    try {
      await AppSettingsStore.setExportQuality(value);
      this.showToast(`预设画质已更新为：${this.getQualityLabel(value)}`);
    } catch (err) {
      this.exportQuality = previous;
      this.showToast('导出质量保存失败');
    }
  }

  private async selectFormat(value: ExportFormat): Promise<void> {
    if (this.exportFormat === value) {
      return;
    }
    const previous: ExportFormat = this.exportFormat;
    this.exportFormat = value;
    try {
      await AppSettingsStore.setExportFormat(value);
      this.showToast(`预设格式已更新为：${this.getFormatLabel(value)}`);
    } catch (err) {
      this.exportFormat = previous;
      this.showToast('导出格式保存失败');
    }
  }

  private cycleQuality(): void {
    let next: ExportQuality = ExportQuality.Ultra;
    if (this.exportQuality === ExportQuality.Ultra) {
      next = ExportQuality.High;
    } else if (this.exportQuality === ExportQuality.High) {
      next = ExportQuality.Standard;
    } else {
      next = ExportQuality.Ultra;
    }
    this.selectQuality(next);
  }

  private cycleFormat(): void {
    let next: ExportFormat = ExportFormat.ORIGINAL;
    if (this.exportFormat === ExportFormat.ORIGINAL) {
      next = ExportFormat.JPEG;
    } else if (this.exportFormat === ExportFormat.JPEG) {
      next = ExportFormat.PNG;
    } else if (this.exportFormat === ExportFormat.PNG) {
      next = ExportFormat.WEBP;
    } else if (this.exportFormat === ExportFormat.WEBP) {
      next = ExportFormat.HEIF;
    } else {
      next = ExportFormat.ORIGINAL;
    }
    this.selectFormat(next);
  }

  private getQualityLabel(quality: ExportQuality): string {
    if (quality === ExportQuality.Ultra) {
      return '超清 · 原画尺寸';
    }
    if (quality === ExportQuality.High) {
      return '高清 · 2K尺寸';
    }
    return '标准 · 1080P尺寸';
  }

  private getFormatLabel(format: ExportFormat): string {
    if (format === ExportFormat.ORIGINAL) {
      return '源格式 · 保持原图格式';
    }
    if (format === ExportFormat.PNG) {
      return 'PNG · 无损高保真';
    }
    if (format === ExportFormat.WEBP) {
      return 'WebP · 现代高效';
    }
    if (format === ExportFormat.HEIF) {
      return 'HEIF · 高保真压缩';
    }
    return 'JPEG · 常规通用';
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      // 提示失败不影响设置状态。
    }
  }

  private goBack(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
        PageHeader({ title: '应用设置', showBack: true, onBack: () => this.goBack(), topInset: true });
        Scroll() {
          Column({ space: 24 }) {
            // ① 照片设置区块
            Column({ space: 10 }) {
              Text('照片设置')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .letterSpacing(1.5)
                .width('100%');

              Column() {
                // 1. 导出时弹窗询问开关
                Row() {
                  Column({ space: 3 }) {
                    Text('导出时弹窗询问')
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(16)
                      .fontColor(MASK_SEAL.ink);
                    Text('照片导出时弹窗选择画质与格式')
                      .fontFamily(Theme.FONT_MONO)
                      .fontSize(11)
                      .fontColor(MASK_SEAL.inkMuted);
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start);

                  Toggle({ type: ToggleType.Switch, isOn: this.promptOnExport })
                    .selectedColor(Theme.PRIMARY)
                    .switchPointColor(Theme.PAPER_SURFACE)
                    .onChange((isOn: boolean) => {
                      this.togglePromptOnExport(isOn);
                    });
                }
                .width('100%')
                .padding({ left: 18, right: 16, top: 15, bottom: 15 })
                .backgroundColor(MASK_SEAL.paperSurface)
                .border({ width: { bottom: 1 }, color: '#eadbd7' });

                // 2. 预设导出画质
                SettingRow({
                  title: '预设画质',
                  detail: this.getQualityLabel(this.exportQuality) + '（轻触切换）',
                  interactive: true,
                  onTap: () => this.cycleQuality()
                });

                // 3. 预设导出格式
                SettingRow({
                  title: '预设格式',
                  detail: this.getFormatLabel(this.exportFormat) + '（轻触切换）',
                  interactive: true,
                  onTap: () => this.cycleFormat()
                });

                // 4. 预览弹窗按钮
                SettingRow({
                  title: '预览导出弹窗面板',
                  detail: '轻触预览落印导出规格面板',
                  interactive: true,
                  onTap: () => {
                    this.showExportDialog = true;
                  }
                });
              }
              .border({ width: 1, color: '#d9c4c0' });

              // 提示微注
              Row({ space: 6 }) {
                Text('◆')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(10)
                  .fontColor(Theme.PRIMARY);
                Text('导出设置已改为「照片导出时弹窗询问」。在编辑页或作品库轻触导出时，将自动弹出规格选择面板。')
                  .fontFamily(Theme.FONT_SANS)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.inkMuted)
                  .lineHeight(18);
              }
              .padding({ left: 4, right: 4, top: 4 });
            }

            // ② 通用设置区块
            Column({ space: 10 }) {
              Text('通用')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .letterSpacing(1.5)
                .width('100%')
                .padding({ bottom: 2 });
              Column() {
                SettingRow({ title: '语言', detail: '简体中文', interactive: false, onTap: () => {} });
                SettingRow({
                  title: '本地存储说明',
                  detail: '导出设置保存在本机，导出时将弹窗供您即时确认',
                  interactive: false,
                  onTap: () => {}
                });
                SettingRow({ title: '关于蒙版调色', detail: 'V1.0 · Mask & Seal 界面示例', interactive: false, onTap: () => {} });
                SettingRow({ title: '版本号', detail: '0.1.9', interactive: false, onTap: () => {} });
              }
              .border({ width: 1, color: '#d9c4c0' });
            }
          }
          .width('100%')
          .padding(20);
        }
        .layoutWeight(1);
      }
      .width('100%')
      .height('100%');

      // 导出规格预览弹窗
      if (this.showExportDialog) {
        ExportSettingsDialog({
          isVisible: this.showExportDialog,
          imageWidth: 4000,
          imageHeight: 3000,
          onConfirm: (settings: AppExportSettings) => {
            this.exportQuality = settings.quality;
            this.exportFormat = settings.format;
            this.showExportDialog = false;
            this.showToast('已更新预设规格');
          },
          onCancel: () => {
            this.showExportDialog = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%');
  }
}
