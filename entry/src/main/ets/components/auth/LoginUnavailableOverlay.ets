import { MASK_SEAL, SealButton } from '../MaskSeal';
import { Theme } from '../common/Theme';

@Component
export struct LoginUnavailableOverlay {
  onBack: () => void = () => {};
  title: string = '登录功能暂未开启';
  message: string = '因开发者付不起服务器钱所以登陆功能不可用，想加速上线登陆功能和云存储功能可以给我加个餐';
  @State showSponsorModal: boolean = false;
  @State selectedTier: number = 0; // 0: ¥2 赏瓶水喝, 1: ¥5 加个鸡腿

  @Builder
  sponsorModal(): void {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩蒙层，点击可关闭弹窗
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(36, 25, 24, 0.65)')
        .onClick(() => {
          this.showSponsorModal = false;
        });

      // 弹窗卡片
      Column({ space: 16 }) {
        // 顶部标题与副标题
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text('印')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.sealRed)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .border({ width: 1, color: MASK_SEAL.sealRed })
              .borderRadius(2);
            Text('给开发者加个餐')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
          }
          Text('每一份支持都将用于服务器续费与功能开发')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .fontColor(MASK_SEAL.inkMuted);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // 分段切换标签 (¥2 / ¥5)
        Row({ space: 8 }) {
          Button('赏瓶水喝 ¥2')
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(this.selectedTier === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedTier === 0 ? Color.White : MASK_SEAL.inkMuted)
            .backgroundColor(this.selectedTier === 0 ? MASK_SEAL.primary : '#eeebe6')
            .border({ width: 1, color: this.selectedTier === 0 ? MASK_SEAL.primary : '#d9c4c0' })
            .borderRadius(4)
            .onClick(() => {
              this.selectedTier = 0;
            });

          Button('加个鸡腿 ¥5')
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(this.selectedTier === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedTier === 1 ? Color.White : MASK_SEAL.inkMuted)
            .backgroundColor(this.selectedTier === 1 ? MASK_SEAL.primary : '#eeebe6')
            .border({ width: 1, color: this.selectedTier === 1 ? MASK_SEAL.primary : '#d9c4c0' })
            .borderRadius(4)
            .onClick(() => {
              this.selectedTier = 1;
            });
        }
        .width('100%');

        // 二维码展示区域
        Column({ space: 10 }) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.selectedTier === 0) {
              Image($r('app.media.sponsor_qr_water'))
                .width(220)
                .height(220)
                .objectFit(ImageFit.Contain)
                .borderRadius(6);
            } else {
              Image($r('app.media.sponsor_qr_chicken'))
                .width(220)
                .height(220)
                .objectFit(ImageFit.Contain)
                .borderRadius(6);
            }
          }
          .width(236)
          .height(236)
          .backgroundColor(Color.White)
          .padding(8)
          .border({ width: 1, color: '#e0d5d2' })
          .borderRadius(8);

          Row({ space: 4 }) {
            Text('支')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#1677ff')
              .borderRadius(2)
              .padding({ left: 3, right: 3 });
            Text('支持支付宝「扫一扫」赞赏')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(13)
              .fontColor(MASK_SEAL.primary);
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // 关闭/完成按钮
        Button('已加餐 / 收起')
          .width('100%')
          .height(48)
          .fontFamily(Theme.FONT_SERIF)
          .fontWeight(FontWeight.Bold)
          .fontSize(16)
          .fontColor(MASK_SEAL.primary)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: '#c8a4a0' })
          .borderRadius(4)
          .onClick(() => {
            this.showSponsorModal = false;
          });
      }
      .width('88%')
      .constraintSize({ maxWidth: 360 })
      .padding(24)
      .backgroundColor(MASK_SEAL.paperSurface)
      .border({ width: 1, color: '#ba7770' })
      .borderRadius(8)
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.25)', offsetY: 8 });
    }
    .width('100%')
    .height('100%')
    .zIndex(999);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明磨砂底遮罩，拦截下层点击
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(222, 221, 215, 0.90)')
        .backdropBlur(10)
        .onClick(() => {
          // 吸收点击事件，防止穿透至下层登录表单
        });

      // 主提示卡片
      Column({ space: 20 }) {
        // 印信徽章
        Column({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Text('暂')
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

          Text('服务维护中 · 诚邀加餐')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(12)
            .fontColor(MASK_SEAL.primary)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#f8e4e1')
            .borderRadius(2);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // 提示正文
        Text(this.message)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(15)
          .lineHeight(24)
          .fontColor(MASK_SEAL.inkMuted)
          .textAlign(TextAlign.Center)
          .padding({ left: 8, right: 8 });

        // 操作按钮区域
        Column({ space: 12 }) {
          Button('给开发者加个餐 🍗')
            .width('100%')
            .height(52)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
            .fontColor(Color.White)
            .backgroundColor(MASK_SEAL.primary)
            .borderRadius(4)
            .onClick(() => {
              this.showSponsorModal = true;
            });

          Button('返回上一页')
            .width('100%')
            .height(52)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
            .fontColor(MASK_SEAL.primary)
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#c8a4a0' })
            .borderRadius(4)
            .onClick(() => {
              this.onBack();
            });
        }
        .width('100%');

        Text('感谢每一位支持与包容的创作者')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(11)
          .fontColor('#9e8884');
      }
      .width('88%')
      .constraintSize({ maxWidth: 380 })
      .padding(24)
      .backgroundColor(MASK_SEAL.paperSurface)
      .border({ width: 1, color: '#ba7770' })
      .borderRadius(8)
      .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 });

      // 弹出的二维码弹窗
      if (this.showSponsorModal) {
        this.sponsorModal();
      }
    }
    .width('100%')
    .height('100%');
  }
}
