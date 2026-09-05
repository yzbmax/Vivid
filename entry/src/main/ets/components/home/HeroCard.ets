import { Theme } from '../common/Theme';

/**
 * 主视觉卡（HeroCard）——「呈交新卷宗」
 *
 * 依据：Mask & Seal 设计规范（Canvas Hub 样板 _6）
 * - 剔除生硬位移阴影，引入宣纸装裱与细线包边（1px Theme.PRIMARY_20）
 * - 右上角装饰扇形印玺柔光水纹，左上嵌朱砂方印徽记
 * - 具备文书呈报的动词化叙事与平滑按压微动效
 */
@Component
export struct HeroCard {
  onImportClick: () => void = () => {};

  @Styles
  cardPressed() {
    .scale({ x: 0.985, y: 0.985 })
  }

  build() {
    Column() {
      // 卡片主要内容
      Column() {
        // 顶栏：朱砂方印徽标（左）+ 卷宗 KICKER（右）
        Row() {
          // 典雅金石朱文引首印（替代突兀的现代数码相册白色线框）
          Stack({ alignContent: Alignment.Center }) {
            // 内衬古典印规细边框
            Row()
              .width(26)
              .height(26)
              .border({ width: 0.8, color: 'rgba(242, 241, 237, 0.4)' })
              .borderRadius(1)

            // 金石印文：「呈」（与「呈交新卷宗」呼应，温润宣纸白，杜绝刺眼死白）
            Text('呈')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PAPER_SURFACE)
              .letterSpacing(0)
          }
          .width(36)
          .height(36)
          .borderRadius(Theme.RADIUS_DEFAULT)
          .backgroundColor(Theme.PRIMARY)
          .shadow({ radius: 4, color: 'rgba(123, 23, 27, 0.25)', offsetY: 1 })

          Blank()

          // 卷宗签号
          Text($r('app.string.home_hero_kicker'))
            .fontFamily(Theme.FONT_MONO)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(1.5)
            .fontColor(Theme.PRIMARY)
        }
        .width('100%')

        // 标题与释义区
        Column({ space: 8 }) {
          Text($r('app.string.home_hero_title'))
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY_CONTAINER)
            .letterSpacing(2)

          Text($r('app.string.home_hero_subtitle'))
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO)
            .lineHeight(20)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .letterSpacing(0.5)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 20, bottom: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })

      // 卡片底缘：宣纸装裱细红金线
      Row()
        .width('100%')
        .height(3)
        .backgroundColor(Theme.PRIMARY_20)
    }
    .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    .backgroundColor(Theme.SURFACE_CONTAINER)
    .border({ width: 1, color: Theme.PRIMARY_20 })
    .borderRadius(Theme.RADIUS_DEFAULT)
    .shadow({ radius: 8, color: 'rgba(139, 113, 111, 0.12)', offsetY: 2 })
    .clip(true)
    .stateStyles({ pressed: this.cardPressed })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .onClick(() => {
      this.onImportClick();
    })
  }
}
