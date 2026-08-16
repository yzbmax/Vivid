// 页头：红色方块 V 图标 + 品牌名 VIVID + 卷宗编号 Nº 001。
// 左侧红底白字方块，右侧纵向排列品牌名与编号，呼应文书卷宗的标题栏。

@Component
export struct Header {
  build() {
    Row() {
      // 朱砂红方块 + 白色 V 字
      Text('V')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.ink_red'))
        .borderRadius(6)
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)

      // 品牌名 + 编号（纵向排列）
      Column() {
        Text($r('app.string.home_brand'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(4)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_archive_no'))
          .fontSize(11)
          .letterSpacing(1)
          .margin({ top: 2 })
          .fontColor($r('app.color.stone_gray'))
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 0, bottom: 16 })
  }
}
