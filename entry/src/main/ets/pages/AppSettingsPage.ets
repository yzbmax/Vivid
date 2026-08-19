import { MASK_SEAL, SealPaperBackground, SettingRow } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { ExportFormat, ExportQuality } from '../models/AppSettingsModels';

@Entry
@Component
struct AppSettingsPage {
  @State exportQuality: ExportQuality = ExportQuality.Standard;
  @State exportFormat: ExportFormat = ExportFormat.JPEG;

  aboutToAppear(): void {
    this.loadExportSettings();
  }

  private async loadExportSettings(): Promise<void> {
    try {
      const settings = await AppSettingsStore.getExportSettings();
      this.exportQuality = settings.quality;
      this.exportFormat = settings.format;
    } catch (err) {
      this.showToast('导出设置读取失败，已使用默认值');
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
    } catch (err) {
      this.exportFormat = previous;
      this.showToast('导出格式保存失败');
    }
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
        Column({ space: 20 }) {
          Column({ space: 10 }) {
            Text('照片设置')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%');
            Text('导出质量')
              .fontSize(13)
              .fontColor(MASK_SEAL.inkMuted)
              .width('100%');
            Column() {
              Row({ space: 12 }) {
                Radio({ value: ExportQuality.Standard, group: 'exportQuality' })
                  .checked(this.exportQuality === ExportQuality.Standard)
                  .onChange((checked: boolean) => { if (checked) this.selectQuality(ExportQuality.Standard); });
                Text('标准').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .onClick(() => this.selectQuality(ExportQuality.Standard));
              Row({ space: 12 }) {
                Radio({ value: ExportQuality.High, group: 'exportQuality' })
                  .checked(this.exportQuality === ExportQuality.High)
                  .onChange((checked: boolean) => { if (checked) this.selectQuality(ExportQuality.High); });
                Text('高清').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.selectQuality(ExportQuality.High));
              Row({ space: 12 }) {
                Radio({ value: ExportQuality.Ultra, group: 'exportQuality' })
                  .checked(this.exportQuality === ExportQuality.Ultra)
                  .onChange((checked: boolean) => { if (checked) this.selectQuality(ExportQuality.Ultra); });
                Text('超清').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.selectQuality(ExportQuality.Ultra));
            }
            .border({ width: 1, color: '#d9c4c0' });

            Text('导出格式')
              .fontSize(13)
              .fontColor(MASK_SEAL.inkMuted)
              .width('100%')
              .padding({ top: 8 });
            Column() {
              Row({ space: 12 }) {
                Radio({ value: ExportFormat.JPEG, group: 'exportFormat' })
                  .checked(this.exportFormat === ExportFormat.JPEG)
                  .onChange((checked: boolean) => { if (checked) this.selectFormat(ExportFormat.JPEG); });
                Text('JPEG（默认）').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .onClick(() => this.selectFormat(ExportFormat.JPEG));
              Row({ space: 12 }) {
                Radio({ value: ExportFormat.PNG, group: 'exportFormat' })
                  .checked(this.exportFormat === ExportFormat.PNG)
                  .onChange((checked: boolean) => { if (checked) this.selectFormat(ExportFormat.PNG); });
                Text('PNG').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.selectFormat(ExportFormat.PNG));
            }
            .border({ width: 1, color: '#d9c4c0' });
          }

          Column() {
            Text('通用')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({ title: '语言', detail: '简体中文', interactive: false, onTap: () => {} });
            SettingRow({ title: '本地存储说明', detail: '导出设置保存在本机，重新进入后仍然生效', interactive: false,
              onTap: () => {} });
            SettingRow({ title: '关于蒙版调色', detail: 'V1.0 · Mask & Seal 界面示例', interactive: false,
              onTap: () => {} });
            SettingRow({ title: '版本号', detail: '0.1.1', interactive: false, onTap: () => {} });
          }
        }
        .width('100%')
        .padding(20);
      }
      .layoutWeight(1);
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
