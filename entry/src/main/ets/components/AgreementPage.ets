import { MASK_SEAL, SealPaperBackground } from './MaskSeal';
import { PageHeader } from './common/PageHeader';

@Component
export struct AgreementPage {
  @Prop title: string = '';
  @Prop updatedAt: string = '2026 年 08 月 13 日';
  @Prop sections: string[] = [];

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
      PageHeader({ title: this.title, showBack: true, onBack: () => this.goBack() });
      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 6 }) {
            Text('呈报依据')
              .fontFamily('monospace')
              .fontSize(11)
              .fontColor(MASK_SEAL.primary)
              .letterSpacing(2);
            Text(this.title)
              .fontFamily('Noto Serif SC')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
            Text(`更新日期：${this.updatedAt}`)
              .fontFamily('monospace')
              .fontSize(11)
              .fontColor(MASK_SEAL.inkMuted);
          }
          .width('100%');
          Text('界面示例，非正式法律文本')
            .width('100%')
            .fontSize(13)
            .fontColor(MASK_SEAL.primary)
            .backgroundColor('#f8e4e1')
            .border({ width: 1, color: '#d9a9a3' })
            .padding(12);
          ForEach(this.sections, (section: string, index: number) => {
            Column({ space: 8 }) {
              Text(`第 ${index + 1} 条`)
                .fontFamily('Noto Serif SC')
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(MASK_SEAL.ink);
              Text(section)
                .fontSize(15)
                .lineHeight(25)
                .fontColor(MASK_SEAL.inkMuted);
            }
            .width('100%')
            .padding(18)
            .backgroundColor(MASK_SEAL.paperSurface)
            .border({ width: 1, color: '#ded0cc' });
          }, (section: string) => section);
          Text('呈报复核 · 文书示例')
            .fontFamily('monospace')
            .fontSize(10)
            .fontColor('#8a5c57')
            .letterSpacing(1)
            .padding({ top: 8, bottom: 28 });
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
