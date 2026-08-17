import { MASK_SEAL, SealButton, SealPaperBackground, SettingRow } from '../MaskSeal';
import { PageHeader } from '../common/PageHeader';
import { AuthSession, MockUser } from '../../models/AuthModels';
import { MockAuthStore } from '../../models/MockAuthStore';

/**
 * 「我的」Tab 内容组件。
 * 由 CentralOfUser 分支 pages/Mine.ets 迁入 components/mine/，去掉 @Entry 供 Index 挂载；
 * 登录/注册/设置/协议仍为独立路由页（main_pages.json 注册）。
 */

@Component
export struct MinePage {
  @StorageProp('authRevision') authRevision: number = 0;

  private async openPage(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch (err) {
      console.error(`Failed to navigate to ${url}: ${JSON.stringify(err)}`);
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

  private logout(): void {
    MockAuthStore.logout();
    try {
      this.getUIContext().getPromptAction().showToast({ message: '已退出登录' });
    } catch (err) {
      console.error(`Failed to show logout toast: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      PageHeader({ title: '我的', showBack: false, onBack: () => {}, topInset: true });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 10 }) {
            Stack({ alignContent: Alignment.Center }) {
              Text(this.currentUser()?.avatarGlyph ?? '印')
                .fontFamily('Noto Serif SC')
                .fontSize(34)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.primary);
            }
            .width(78)
            .height(78)
            .border({ width: 1, color: '#ba7770' })
            .backgroundColor('#f8e4e1')
            .rotate({ angle: -4 });
            if (this.isAuthenticated()) {
              Text(this.currentUser()?.nickname ?? '个人称谓')
                .fontFamily('Noto Serif SC')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.ink);
              Text(this.currentUser()?.maskedPhone ?? '暂未登记在册')
                .fontFamily('monospace')
                .fontSize(14)
                .fontColor(MASK_SEAL.inkMuted);
              Text('演示数据 · 当前进程会话')
                .fontSize(12)
                .fontColor(MASK_SEAL.primary);
              SealButton({ text: '退出登录', secondary: true, onTap: () => this.logout() });
            } else {
              Text('未登录')
                .fontFamily('Noto Serif SC')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.ink);
              Text('登录后可管理您的个人档册与设置')
                .fontSize(14)
                .fontColor(MASK_SEAL.inkMuted);
              Row({ space: 12 }) {
                Column() {
                  SealButton({ text: '登录', secondary: false, onTap: () => this.openPage('pages/LoginPage') });
                }
                .layoutWeight(1);
                Column() {
                  SealButton({
                    text: '注册',
                    secondary: true,
                    onTap: () => this.openPage('pages/RegisterPage')
                  });
                }
                .layoutWeight(1);
              }
              .width('100%')
              .margin({ top: 12 });
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding(24)
          .backgroundColor(MASK_SEAL.paperSurface)
          .border({ width: 1, color: '#d9c4c0' });

          Column() {
            Text('个人与应用')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({ title: '用户设置', detail: '头像、昵称与登录安全', interactive: true,
              onTap: () => this.openPage('pages/UserSettingsPage') });
            SettingRow({ title: '应用设置', detail: '外观、语言与本地说明', interactive: true,
              onTap: () => this.openPage('pages/AppSettingsPage') });
          }

          Column() {
            Text('呈报依据')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({ title: '用户协议', detail: '界面示例文案', interactive: true,
              onTap: () => this.openPage('pages/UserAgreementPage') });
            SettingRow({ title: '隐私政策', detail: '界面示例文案', interactive: true,
              onTap: () => this.openPage('pages/PrivacyPolicyPage') });
          }

          Text(this.isAuthenticated() ? '演示档册 · 仅当前进程有效' : '未注册档册')
            .fontFamily('monospace')
            .fontSize(10)
            .fontColor('#8a5c57')
            .letterSpacing(1)
            .padding({ top: 4, bottom: 28 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 32, right: 32, top: 20, bottom: 28 });
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
