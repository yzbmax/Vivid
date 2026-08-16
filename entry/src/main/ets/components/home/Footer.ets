// 页脚：品牌署名 VIVID · DIGITAL ART ARCHIVE。
// 居中排列，石灰副色小字，呼应文书卷宗的落款。

@Component
export struct Footer {
  build() {
    Column() {
      // 分隔线
      Divider()
        .color($r('app.color.line_light'))
        .strokeWidth(0.5)
        .width('60%')
        .margin({ bottom: 12 })

      // 落款
      Text($r('app.string.home_footer'))
        .fontSize(11)
        .letterSpacing(2)
        .fontColor($r('app.color.stone_gray'))
    }
    .width('100%')
    .padding({ top:15, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }
}
