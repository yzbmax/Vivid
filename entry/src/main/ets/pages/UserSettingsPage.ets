import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { FloatingInput, MASK_SEAL, SealPageHeader, SealPaperBackground, SettingRow } from '../components/MaskSeal';

@Entry
@Component
struct UserSettingsPage {
  @State nickname: string = '';

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      SealPageHeader({ title: '用户设置', showBack: true, onBack: () => router.back() });
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
            .border({ width: 1, color: '#d9c4c0' });
            FloatingInput({ value: this.nickname, label: '卷宗称谓',
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
              onTap: () => promptAction.showToast({ message: '登录后可管理' }) });
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
