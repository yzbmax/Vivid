// 近作横滑区：展示近期作品的横向滚动列表。
// 卡片采用浅色底（米白/淡粉交替），中央放置圆形"印"印章，底部左下角显示标题与日期。
// 由 HomePage 通过 @Prop 传入 WorkItem[] 数据。

import { WorkItem } from './HomeModels';

@Component
export struct RecentWorkSection {
  @Prop works: WorkItem[] = [];

  build() {
    Column() {
      // 区块标题：中文"近作" + 英文"RECENT WORKS"
      Row() {
        Text($r('app.string.home_work_cn'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))


        Text($r('app.string.home_work_en'))
          .fontSize(11)
          .letterSpacing(2)
          .margin({ left: 8 })
          .fontColor($r('app.color.ink_red'))
      }
      .width('100%')
      .margin({ bottom: 16 })
      .padding({ left: 24, right: 24 })

      // 横向滚动列表
      List({ space: 12 }) {
        ForEach(this.works, (item: WorkItem, index: number) => {
          ListItem() {
            this.WorkCard(item, index)
          }
        }, (item: WorkItem, index: number) => index.toString())
      }
      .width('100%')
      .height(140)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .padding({ top: 24, bottom: 8 })
  }

  // 单个作品卡片：浅色底 + 中央印章 + 底部标题日期
  @Builder
  WorkCard(item: WorkItem, index: number) {
    Column() {
      // 顶部留白，将印章推至中部偏上
      Blank()
        .layoutWeight(1)

      // 圆形"印"印章居中
      Row() {
        Blank()
          .layoutWeight(1)

        Text($r('app.string.home_seal'))
          .fontSize(26)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_red'))
          .width(48)
          .height(48)
          .borderRadius(24)
          .border({ width: 1.5, color: $r('app.color.ink_red') })
          .textAlign(TextAlign.Center)

        Blank()
          .layoutWeight(1)
      }
      .width('100%')

      // 底部留白
      Blank()
        .layoutWeight(1)

      // 作品标题
      Text(item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_dark'))

      // 作品日期
      Text(item.date)
        .fontSize(11)
        .margin({ top: 4 })
        .fontColor($r('app.color.stone_gray'))
    }
    .width(140)
    .height(140)
    .padding(12)
    .borderRadius(12)
    // 交替背景色：偶数米白，奇数淡粉
    .backgroundColor(index % 2 === 0 ? $r('app.color.paper_white') : $r('app.color.paper_pink'))
    .alignItems(HorizontalAlign.Start)
  }
}
