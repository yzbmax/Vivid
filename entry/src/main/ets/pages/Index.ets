import router from '@ohos.router';
import { MASK_SEAL, SealButton, SealPageHeader, SealPaperBackground, SettingRow } from '../components/MaskSeal';

@Entry
@Component
struct MinePage {
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      SealPageHeader({ title: '我的' });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 10 }) {
            Stack({ alignContent: Alignment.Center }) {
              Text('印')
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
            Text('未登录呈报者')
              .fontFamily('Noto Serif SC')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
            Text('登录后可管理您的个人卷宗与设置')
              .fontSize(14)
              .fontColor(MASK_SEAL.inkMuted);
            Row({ space: 12 }) {
              SealButton({ text: '呈验登录', onTap: () => router.pushUrl({ url: 'pages/LoginPage' }) })
                .width(148);
              SealButton({ text: '登记在册', secondary: true, onTap: () => router.pushUrl({ url: 'pages/RegisterPage' }) })
                .width(148);
            }
            .margin({ top: 12 });
          }
          .width('100%')
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
            SettingRow({ title: '用户设置', detail: '头像、昵称与登录安全', onTap: () => router.pushUrl({ url: 'pages/UserSettingsPage' }) });
            SettingRow({ title: '应用设置', detail: '外观、语言与本地说明', onTap: () => router.pushUrl({ url: 'pages/AppSettingsPage' }) });
          }

          Column() {
            Text('呈报依据')
              .fontFamily('monospace')
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(1.5)
              .width('100%')
              .padding({ bottom: 8 });
            SettingRow({ title: '用户协议', detail: '界面示例文案', onTap: () => router.pushUrl({ url: 'pages/UserAgreementPage' }) });
            SettingRow({ title: '隐私政策', detail: '界面示例文案', onTap: () => router.pushUrl({ url: 'pages/PrivacyPolicyPage' }) });
          }

          Text('炎国跨署呈报复核 · 未登记卷宗')
            .fontFamily('monospace')
            .fontSize(10)
            .fontColor('#8a5c57')
            .letterSpacing(1)
            .padding({ top: 4, bottom: 28 });
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
