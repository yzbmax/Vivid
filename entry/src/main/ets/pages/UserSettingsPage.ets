import { MASK_SEAL, SealButton, SealPaperBackground, SettingRow } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
import { Theme } from '../components/common/Theme';
import { AuthUiState } from '../models/AuthUiState';
import { AuthSession, MockUser } from '../models/AuthModels';
import { MockAuthStore } from '../models/MockAuthStore';

@Entry
@Component
struct UserSettingsPage {
  @StorageProp('authRevision') authRevision: number = 0;

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

  private async openPage(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch (err) {
      console.error(`Failed to open ${url}: ${JSON.stringify(err)}`);
    }
  }

  private currentSession(): AuthSession {
    if (this.authRevision < 0) {
      return { status: 'anonymous' };
    }
    return MockAuthStore.getSession();
  }

  private currentUser(): MockUser | undefined {
    return this.currentSession().user;
  }

  private currentAvatarUri(): string {
    return MockAuthStore.getCurrentAvatarUri() ?? '';
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      PageHeader({ title: '用户设置', showBack: true, onBack: () => this.goBack(), topInset: true });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 12 }) {
            Text('个人册页')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%');
            Row({ space: 14 }) {
              if (this.currentAvatarUri().length > 0) {
                Image(this.currentAvatarUri())
                  .width(58)
                  .height(58)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 1, color: '#d2a5a0' })
                  .borderRadius(29);
              } else {
                Text(this.currentUser()?.avatarGlyph ?? '印')
                  .fontFamily(Theme.FONT_SERIF)
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
              }
              Column({ space: 4 }) {
                Text(this.currentUser()?.nickname ?? '雅集墨客')
                  .fontSize(16).fontColor(MASK_SEAL.ink);
                Text('本地创作者档案 · 私密存储')
                  .fontSize(13).fontColor(MASK_SEAL.inkMuted);
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);
              Text('›')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(24).fontColor(MASK_SEAL.primary);
            }
            .width('100%')
            .padding(18)
            .backgroundColor(MASK_SEAL.paperSurface)
            .border({ width: 1, color: '#d9c4c0' })
            .onClick(() => {
              this.openPage('pages/ProfileEditPage');
            });
          }

          Column() {
            Text('存储与运行说明')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({
              title: '运行模式',
              detail: '纯本地离线创作 · 端侧图像处理',
              interactive: false,
              onTap: () => {}
            });
            SettingRow({
              title: '数据存储',
              detail: '作品与偏好完全保存在本机私有沙箱',
              interactive: false,
              onTap: () => {}
            });
          }

          Text('微霏恪守端侧隐私安全，无需绑定手机号或注册账号，所有作品与创作设置完全保存在设备本地。')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .fontColor(MASK_SEAL.inkMuted)
            .lineHeight(18)
            .padding({ top: 8 });
        }
        .width('100%')
        .padding(20);
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
