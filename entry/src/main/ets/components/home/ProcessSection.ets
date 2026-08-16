// 技艺列表区：展示核心功能特点的纵向列表。
// 每条含左侧红点指示器（单点/四点）、标题与描述、右侧编号 01/02/03。
// 由 HomePage 通过 @Prop 传入 FeatureItem[] 数据。

import { FeatureItem } from './HomeModels';

@Component
export struct ProcessSection {
  @Prop features: FeatureItem[] = [];

  build() {
    Column() {
      // 区块标题：中文"技艺" + 英文"PROCESS"
      Row() {
        Text($r('app.string.home_section_cn'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_section_en'))
          .fontSize(11)
          .letterSpacing(2)
          .margin({ left: 8 })
          .fontColor($r('app.color.ink_red'))
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 技艺列表
      ForEach(this.features, (item: FeatureItem, index: number) => {
        Row() {
          // 左侧：红点指示器
          Column() {
            if (index === 0) {
              // 第一项：单点
              Column()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor($r('app.color.ink_red'))
            } else if (index === 1) {
              // 第二项：2×2 四点
              Column({ space: 4 }) {
                Row({ space: 4 }) {
                  Column().width(5).height(5).borderRadius(2.5).backgroundColor($r('app.color.ink_red'))
                  Column().width(5).height(5).borderRadius(2.5).backgroundColor($r('app.color.ink_red'))
                }
                Row({ space: 4 }) {
                  Column().width(5).height(5).borderRadius(2.5).backgroundColor($r('app.color.ink_red'))
                  Column().width(5).height(5).borderRadius(2.5).backgroundColor($r('app.color.ink_red'))
                }
              }
            } else {
              // 第三项：单点
              Column()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor($r('app.color.ink_red'))
            }
          }
          .width(28)
          .height(28)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          // 中间：标题 + 描述
          Column() {
            Text(item.title)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_dark'))

            Text(item.desc)
              .fontSize(12)
              .margin({ top: 4 })
              .lineHeight(18)
              .fontColor($r('app.color.stone_gray'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 16 })

          // 右侧：编号
          Text(`0${index + 1}`)
            .fontSize(11)
            .fontColor($r('app.color.stone_gray'))
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .alignItems(VerticalAlign.Center)
      }, (item: FeatureItem, index: number) => index.toString())
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 8 })
  }
}
