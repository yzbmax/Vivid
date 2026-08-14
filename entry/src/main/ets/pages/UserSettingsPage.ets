import { FloatingInput, MASK_SEAL, SealPageHeader, SealPaperBackground, SettingRow } from '../components/MaskSeal';

@Entry
@Component
struct UserSettingsPage {
  @State nickname: string = '';

  private goBack(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`Failed to show toast: ${JSON.stringify(err)}`);
    }
  }

  private async openLogin(): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error(`Failed to open login page: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      SealPageHeader({ title: '用户设置', showBack: true, titleOffsetY: 6, onBack: () => this.goBack() });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 12 }) {
            Text('个人册页')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%');
            Row({ space: 14 }) {
              Text('未')
                .fontFamily('Noto Serif SC')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.primary)
                .width(58)
                .height(58)
                .textAlign(TextAlign.Center)
                .padding({ top: 14 })
                .backgroundColor('#f9e3e1')
                .border({ width: 1, color: '#d2a5a0' })
                .borderRadius(29);
              Column({ space: 4 }) {
                Text('头像印记').fontSize(16).fontColor(MASK_SEAL.ink);
                Text('暂未登记在册').fontSize(13).fontColor(MASK_SEAL.inkMuted);
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);
              Text('›').fontSize(24).fontColor(MASK_SEAL.primary);
            }
            .width('100%')
            .padding(18)
            .backgroundColor(MASK_SEAL.paperSurface)
            .border({ width: 1, color: '#d9c4c0' })
            .onClick(() => this.openLogin());
            FloatingInput({ value: this.nickname, label: '个人称谓', error: '', layoutWeight: 0,
              onChange: (value: string) => this.nickname = value });
          }

          Column() {
            Text('账号说明')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({ title: '手机号与登录安全', detail: '未登录', interactive: false,
              onTap: () => this.showToast('登录后可管理') });
          }

          Text('本页输入仅用于前端展示，离开页面后不会保存。')
            .fontSize(12)
            .fontColor(MASK_SEAL.inkMuted)
            .padding({ top: 8 });
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
