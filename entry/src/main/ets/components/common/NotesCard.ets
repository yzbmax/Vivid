import { Theme } from './Theme';

/**
 * 案卷批注卡片（预留组件 F2）：标题 + 正文 + 右下角水印大字。
 * 参考：docs/公共组件预留文档.md F2、stitch「Work Detail Page」Notes。
 */
@Component
export struct NotesCard {
  title: string = '案卷批注';
  content: string = '';
  watermarkGlyph: string = '阅';
  toneLabel: string = '';
  suggestion: string = '';

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row({ space: 8 }) {
          Row()
            .width(4)
            .height(16)
            .backgroundColor(Theme.PRIMARY)
          Text(this.title)
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(16)
            .fontWeight(600)
            .fontColor(Theme.ON_SURFACE)

          if (this.toneLabel && this.toneLabel.length > 0) {
            Row() {
              Text(`调性 · ${this.toneLabel}`)
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(11)
                .fontColor(Theme.PRIMARY)
                .letterSpacing(1)
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(Theme.SURFACE_CONTAINER_HIGH)
            .border({ width: 0.5, color: Theme.OUTLINE_VARIANT })
            .margin({ left: 4 })
          }
        }
        .alignItems(VerticalAlign.Center)

        Text(this.content)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(14)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .lineHeight(22)
          .textAlign(TextAlign.Start)
          .margin({ top: 12 })

        if (this.suggestion && this.suggestion.length > 0) {
          Column({ space: 4 }) {
            Row({ space: 6 }) {
              Row()
                .width(3)
                .height(12)
                .backgroundColor(Theme.SEAL_RED)
              Text('官署校勘')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.SEAL_RED)
                .letterSpacing(1)
            }
            .alignItems(VerticalAlign.Center)

            Text(this.suggestion.replace(/^【官署校勘】/, ''))
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .lineHeight(18)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .margin({ top: 14 })
          .backgroundColor(Theme.SURFACE_CONTAINER_LOW)
          .border({ width: 0.5, color: Theme.OUTLINE_VARIANT, style: BorderStyle.Dashed })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(20)
      // 右下角水印大字
      Text(this.watermarkGlyph)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(64)
        .fontColor(Theme.PRIMARY)
        .opacity(0.12)
        .position({ right: 16, bottom: 4 })
    }
    .width('100%')
    .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
    .shadow({ radius: 4, color: Theme.SHADOW_SM, offsetY: 1 })
  }
}
