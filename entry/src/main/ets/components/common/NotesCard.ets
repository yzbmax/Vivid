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
        }
        .alignItems(VerticalAlign.Center)
        Text(this.content)
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(14)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .lineHeight(22)
          .textAlign(TextAlign.Start)
          .margin({ top: 12 })
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
