import { MASK_SEAL, SealPageHeader, SealPaperBackground, SettingRow } from '../components/MaskSeal';

@Entry
@Component
struct AppSettingsPage {
  @State exportQuality: number = 0;
  @State exportFormat: number = 0;

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
      SealPageHeader({ title: '应用设置', showBack: true, titleOffsetY: 6, onBack: () => this.goBack() });
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
                Radio({ value: 'standard', group: 'exportQuality' })
                  .checked(this.exportQuality === 0)
                  .onChange((checked: boolean) => { if (checked) this.exportQuality = 0; });
                Text('标准').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .onClick(() => this.exportQuality = 0);
              Row({ space: 12 }) {
                Radio({ value: 'high', group: 'exportQuality' })
                  .checked(this.exportQuality === 1)
                  .onChange((checked: boolean) => { if (checked) this.exportQuality = 1; });
                Text('高清').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.exportQuality = 1);
              Row({ space: 12 }) {
                Radio({ value: 'ultra', group: 'exportQuality' })
                  .checked(this.exportQuality === 2)
                  .onChange((checked: boolean) => { if (checked) this.exportQuality = 2; });
                Text('超清').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.exportQuality = 2);
            }
            .border({ width: 1, color: '#d9c4c0' });

            Text('导出格式')
              .fontSize(13)
              .fontColor(MASK_SEAL.inkMuted)
              .width('100%')
              .padding({ top: 8 });
            Column() {
              Row({ space: 12 }) {
                Radio({ value: 'jpeg', group: 'exportFormat' })
                  .checked(this.exportFormat === 0)
                  .onChange((checked: boolean) => { if (checked) this.exportFormat = 0; });
                Text('JPEG（默认）').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .onClick(() => this.exportFormat = 0);
              Row({ space: 12 }) {
                Radio({ value: 'png', group: 'exportFormat' })
                  .checked(this.exportFormat === 1)
                  .onChange((checked: boolean) => { if (checked) this.exportFormat = 1; });
                Text('PNG').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.exportFormat = 1);
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
            SettingRow({ title: '本地存储说明', detail: '当前设置仅保留在页面生命周期内', interactive: false,
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
