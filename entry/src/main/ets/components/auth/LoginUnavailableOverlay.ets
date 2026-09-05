import { MASK_SEAL } from '../MaskSeal';
import { Theme } from '../common/Theme';

@Component
export struct LoginUnavailableOverlay {
  onBack: () => void = () => {};
  title: string = '账号服务升级中';
  message: string = '微霏当前专注于提供纯离线的本地图像调色、金石印章与长卷装裱体验。\n\n所有作品均安全存储于您设备的私有沙箱内，无需登录即可畅享全部创作功能。\n\n云端账号与多端同步服务正在升级开发中，感谢您的支持与理解。';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明磨砂底遮罩，拦截下层点击
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(222, 221, 215, 0.92)')
        .backdropBlur(12)
        .onClick(() => {
          // 拦截点击
        });

      // 主提示卡片
      Column({ space: 20 }) {
        // 印信徽章
        Column({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Text('微')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.primary);
          }
          .width(68)
          .height(68)
          .border({ width: 2, color: '#ba7770' })
          .backgroundColor('#f8e4e1')
          .rotate({ angle: -3 });

          Text(this.title)
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(MASK_SEAL.ink);

          Text('纯本地离线创作 · 安全私密')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(12)
            .fontColor(MASK_SEAL.primary)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .backgroundColor('#f8e4e1')
            .borderRadius(2);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // 提示正文
        Text(this.message)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(14)
          .lineHeight(23)
          .fontColor(MASK_SEAL.inkMuted)
          .textAlign(TextAlign.Center)
          .padding({ left: 12, right: 12 });

        // 操作按钮区域
        Column({ space: 12 }) {
          Button('我知道了，返回创作')
            .width('100%')
            .height(48)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(FontWeight.Bold)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(MASK_SEAL.primary)
            .borderRadius(4)
            .onClick(() => {
              this.onBack();
            });
        }
        .width('100%');

        Text('微霏 · 东方美学数字画卷工坊')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(11)
          .fontColor('#9e8884');
      }
      .width('88%')
      .constraintSize({ maxWidth: 360 })
      .padding(24)
      .backgroundColor(MASK_SEAL.paperSurface)
      .border({ width: 1, color: '#ba7770' })
      .borderRadius(8)
      .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 });
    }
    .width('100%')
    .height('100%');
  }
}

