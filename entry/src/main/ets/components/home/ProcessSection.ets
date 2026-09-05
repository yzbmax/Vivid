import { FeatureItem } from './HomeModels';
import { Theme } from '../common/Theme';

/**
 * 款识三序（ProcessSection）——「工坊仪轨」
 *
 * 依据：Mask & Seal 设计规范
 * - 替换生硬红点技术条目为典雅的金石题记（立意 / 题签 / 落印）
 * - 细线装裱，宋风衬线排印
 */
@Component
export struct ProcessSection {
  @Prop features: FeatureItem[] = [];

  build() {
    Column() {
      // 区块标题：中文"款识三序" + 英文"RITES"
      Row() {
        Text($r('app.string.home_section_cn'))
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_SURFACE)
          .letterSpacing(1.5)

        Text($r('app.string.home_section_en'))
          .fontFamily(Theme.FONT_MONO)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .letterSpacing(1.5)
          .margin({ left: 8 })
          .fontColor(Theme.PRIMARY)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 三序列表
      Column() {
        ForEach(this.features, (item: FeatureItem, index: number) => {
          Column() {
            Row() {
              // 左侧：朱砂微印编号标牌
              Stack({ alignContent: Alignment.Center }) {
                Text(`0${index + 1}`)
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.PRIMARY)
                  .letterSpacing(0.5)
              }
              .width(26)
              .height(26)
              .borderRadius(Theme.RADIUS_DEFAULT)
              .backgroundColor(Theme.SURFACE_CONTAINER_LOW)
              .border({ width: 1, color: Theme.PRIMARY_20 })

              // 中间：标题 + 描述
              Column({ space: 3 }) {
                Text(item.title)
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ON_SURFACE)
                  .letterSpacing(1)

                Text(item.desc)
                  .fontFamily(Theme.FONT_SANS)
                  .fontSize(12)
                  .lineHeight(17)
                  .fontColor(Theme.ON_SURFACE_VARIANT)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 14 })
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })

            // 细若游丝的项间分隔线
            if (index < this.features.length - 1) {
              Divider()
                .color(Theme.OUTLINE_VARIANT)
                .strokeWidth(0.5)
                .margin({ left: 40 })
            }
          }
          .width('100%')
        }, (item: FeatureItem, index: number) => index.toString())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      .backgroundColor(Theme.SURFACE_CONTAINER_LOW)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .borderRadius(Theme.RADIUS_DEFAULT)
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 16, bottom: 8 })
  }
}
