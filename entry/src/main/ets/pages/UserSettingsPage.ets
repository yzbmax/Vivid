import { MASK_SEAL, SealButton, SealPaperBackground, SettingRow } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
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

  private async openLogin(): Promise<void> {
    await this.openPage('pages/LoginPage');
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

  private isAuthenticated(): boolean {
    return this.currentSession().status === 'authenticated';
  }

  private currentUser(): MockUser | undefined {
    return this.currentSession().user;
  }

  private currentAvatarUri(): string {
    return MockAuthStore.getCurrentAvatarUri() ?? '';
  }

  private async confirmLogout(): Promise<void> {
    try {
      const response = await this.getUIContext().getPromptAction().showDialog({
        title: '确认退出登录',
        message: '退出后仍会保留当前进程内的 Mock 账号资料。',
        buttons: [
          { text: '取消', color: MASK_SEAL.inkMuted },
          { text: '退出登录', color: MASK_SEAL.primary }
        ]
      });
      if (response.index !== 1) {
        return;
      }
      MockAuthStore.logout();
      AuthUiState.bumpRevision();
      this.showToast('已退出登录');
    } catch (err) {
      console.error(`Failed to confirm logout: ${JSON.stringify(err)}`);
    }
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
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%');
            Row({ space: 14 }) {
              if (this.isAuthenticated() && this.currentAvatarUri().length > 0) {
                Image(this.currentAvatarUri())
                  .width(58)
                  .height(58)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 1, color: '#d2a5a0' })
                  .borderRadius(29);
              } else {
                Text(this.currentUser()?.avatarGlyph ?? '未')
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
              }
              Column({ space: 4 }) {
                Text(this.isAuthenticated() ? (this.currentUser()?.nickname ?? '个人称谓') : '个人称谓')
                  .fontSize(16).fontColor(MASK_SEAL.ink);
                Text(this.isAuthenticated() ? (this.currentUser()?.maskedPhone ?? '暂未登记在册') : '暂未登记在册')
                  .fontSize(13).fontColor(MASK_SEAL.inkMuted);
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);
              Text('›')
                .fontSize(24).fontColor(MASK_SEAL.primary);
            }
            .width('100%')
            .padding(18)
            .backgroundColor(MASK_SEAL.paperSurface)
            .border({ width: 1, color: '#d9c4c0' })
            .onClick(() => {
              if (!this.isAuthenticated()) {
                this.openLogin();
              } else {
                this.openPage('pages/ProfileEditPage');
              }
            });
            if (this.isAuthenticated()) {
              Text('演示数据 · 当前进程会话')
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .padding({ left: 18, right: 18 });
              SealButton({ text: '退出登录', secondary: true, onTap: () => this.confirmLogout() });
            }
          }

          Column() {
            Text('账号说明')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({
              title: '手机号与登录安全',
              detail: this.isAuthenticated() ? (this.currentUser()?.maskedPhone ?? '未登录') : '未登录',
              interactive: true,
              onTap: () => this.isAuthenticated()
                ? this.openPage('pages/AccountSecurityPage')
                : this.openLogin()
            });
          }

          Text('本页资料为演示数据，仅在当前应用进程内保留。')
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
