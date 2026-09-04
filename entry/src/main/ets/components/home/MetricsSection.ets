import { Theme } from '../common/Theme';

/**
 * 卷宗台账指标（MetricsSection）
 *
 * 依据：Mask & Seal 设计规范（Canvas Hub 样板 _6 §Quick Tools / Metrics）
 * - 双栏等宽卡片：累计封缄（朱砂红顶边）+ 存案总览（青绿墨玉顶边）
 * - 衬线体大号数据数字与等宽大写标签
 */
@Component
export struct MetricsSection {
  @Prop sealedCount: number = 0;
  @Prop totalCount: number = 0;

  build() {
    Row({ space: 12 }) {
      // 左卡：累计封缄
      Column() {
        Row()
          .width('100%')
          .height(2.5)
          .backgroundColor(Theme.PRIMARY)

        Column() {
          Text('TOTAL SEALED · 累计封印')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .letterSpacing(1)

          Row({ space: 4 }) {
            Text(this.sealedCount.toString())
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_HEADLINE_LG_MOBILE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY_CONTAINER)

            Text('卷')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(12)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .margin({ bottom: 4 })
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 14, right: 14, top: 12, bottom: 14 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .height(88)
      .backgroundColor(Theme.SURFACE_CONTAINER)
      .border({ width: 1, color: Theme.PRIMARY_20 })
      .borderRadius(Theme.RADIUS_DEFAULT)
      .clip(true)

      // 右卡：存案总览
      Column() {
        Row()
          .width('100%')
          .height(2.5)
          .backgroundColor(Theme.TERTIARY)

        Column() {
          Text('REPOSITORY · 存案总览')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .letterSpacing(1)

          Row({ space: 4 }) {
            Text(this.totalCount.toString())
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_HEADLINE_LG_MOBILE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.TERTIARY)

            Text('册')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(12)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .margin({ bottom: 4 })
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 14, right: 14, top: 12, bottom: 14 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .height(88)
      .backgroundColor(Theme.SURFACE_CONTAINER)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .borderRadius(Theme.RADIUS_DEFAULT)
      .clip(true)
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 14, bottom: 10 })
  }
}
