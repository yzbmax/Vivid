import { MASK_SEAL, SealPaperBackground } from './MaskSeal';
import { PageHeader } from './common/PageHeader';
import { Theme } from './common/Theme';

export interface AgreementSection {
  title: string;
  content: string;
}

@Component
export struct AgreementPage {
  @Prop title: string = '';
  @Prop updatedAt: string = '2026 年 09 月 04 日';
  @Prop sections: AgreementSection[] = [];

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
        PageHeader({ title: this.title, showBack: true, onBack: () => this.goBack(), topInset: true });
        Scroll() {
          Column({ space: 18 }) {
            Column({ space: 6 }) {
              Text('法律合规与服务准则')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(11)
                .fontColor(MASK_SEAL.primary)
                .letterSpacing(2);
              Text(this.title)
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.ink);
              Text(`生效及更新日期：${this.updatedAt}`)
                .fontFamily(Theme.FONT_MONO)
                .fontSize(11)
                .fontColor(MASK_SEAL.inkMuted);
            }
            .width('100%');

            // 核心承诺提示卡
            Row({ space: 10 }) {
              Text('印')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.sealRed)
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .border({ width: 1, color: MASK_SEAL.sealRed })
                .borderRadius(2)
                .flexShrink(0);
              Text('微霏恪守端侧隐私安全与最小必要原则，图像本地离线运算，竭诚守护您的创作资产。')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(12)
                .lineHeight(20)
                .fontColor(MASK_SEAL.primary)
                .layoutWeight(1);
            }
            .width('100%')
            .backgroundColor('#f8e4e1')
            .border({ width: 1, color: '#d9a9a3' })
            .padding(12)
            .borderRadius(4);

            ForEach(this.sections, (section: AgreementSection, index: number) => {
              Column({ space: 10 }) {
                Text(section.title)
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MASK_SEAL.ink);
                Text(section.content)
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(14)
                  .lineHeight(24)
                  .fontColor(MASK_SEAL.inkMuted);
              }
              .width('100%')
              .padding(18)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#ded0cc' })
              .borderRadius(4);
            }, (section: AgreementSection, index: number) => `${index}_${section.title}`);

            Text('微霏 · 尊重并守护您的创作隐私与合法权益')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(10)
              .fontColor('#8a5c57')
              .letterSpacing(1)
              .padding({ top: 8, bottom: 36 });
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

