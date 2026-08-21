// 主视觉卡只负责展示并上报点击；选图、认证和路由由 HomePage 集中编排。

@Component
export struct HeroCard {
  onImportClick: () => void = () => {};

  build() {
    // 整张卡片可点击
    Column() {
      // 顶栏：上传图标（左）+ COLOR LAB 标签（右）
      Row() {
        // 朱砂红方块 + 白色上传图标（图片+加号）
        Stack({ alignContent: Alignment.Center }) {
          Path()
            .commands('M2 5 L14 5 L14 17 L2 17 Z M5 9 A1.5 1.5 0 1 0 5.01 9 M2 15 L6 11 L9 14 L13 10 M17 3 L17 7 M15 5 L19 5')
            .width(20)
            .height(20)
            .fillOpacity(0)
            .stroke('#FFFFFF')
            .strokeWidth(1.5)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width(36)
        .height(36)
        .borderRadius(8)
        .backgroundColor($r('app.color.ink_red'))

        Blank()

        Text($r('app.string.home_hero_kicker'))
          .fontSize(11)
          .letterSpacing(2)
          .fontColor($r('app.color.ink_red'))
      }
      .width('100%')

      // 主体区：标题 + 副标题
      Column() {
        Text($r('app.string.home_hero_title'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_hero_subtitle'))
          .fontSize(13)
          .margin({ top: 8 })
          .lineHeight(20)
          .fontColor($r('app.color.stone_gray'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 24 })
    }
    .margin({ left: 16, right: 16 })
    .padding({ left: 24, right: 24, top: 24, bottom: 28 })
    .backgroundColor($r('app.color.paper_pink'))
    .borderRadius(16)
    .onClick(() => {
      this.onImportClick();
    })
  }
}
