// 辅助说明区：隐私说明文案，紧跟 HeroCard 之后。

@Component
export struct CtaBlock {
  build() {
    Column() {
      Text($r('app.string.home_cta_note'))
        .fontSize(12)
        .fontColor($r('app.color.stone_gray'))
    }
    .width('100%')
    .padding({ top: 16, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }
}
