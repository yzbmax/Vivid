import { MASK_SEAL, SealPageHeader, SealPaperBackground, SettingRow } from '../components/MaskSeal';

@Entry
@Component
struct AppSettingsPage {
  @State appearance: number = 0;

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
            Text('外观')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%');
            Column() {
              Row({ space: 12 }) {
                Radio({ value: 'system', group: 'appearance' })
                  .checked(this.appearance === 0)
                  .onChange((checked: boolean) => { if (checked) this.appearance = 0; });
                Text('跟随系统').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .onClick(() => this.appearance = 0);
              Row({ space: 12 }) {
                Radio({ value: 'light', group: 'appearance' })
                  .checked(this.appearance === 1)
                  .onChange((checked: boolean) => { if (checked) this.appearance = 1; });
                Text('浅色').fontSize(16).fontColor(MASK_SEAL.ink);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: { top: 1 }, color: '#eadbd7' })
              .onClick(() => this.appearance = 1);
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
