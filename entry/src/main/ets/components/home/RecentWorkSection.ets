// 近作横滑区：展示近期作品的横向滚动列表。
// 卡片显示作品缩略图 + 底部半透明信息栏（标题与日期）。
// 无作品时显示空状态提示。
// 由 HomePage 通过 @Prop 传入 WorkRecord[] 数据。

import { WorkRecord } from '../../models/WorkRecord';
import { Theme } from '../common/Theme';

@Component
export struct RecentWorkSection {
  @Prop works: WorkRecord[] = [];
  onCardClick: (id: string) => void = () => {};

  build() {
    Column() {
      // 区块标题：中文"近作" + 英文"RECENT WORKS"
      Row() {
        Text($r('app.string.home_work_cn'))
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_work_en'))
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(11)
          .letterSpacing(2)
          .margin({ left: 8 })
          .fontColor($r('app.color.ink_red'))
      }
      .width('100%')
      .margin({ bottom: 16 })
      .padding({ left: 24, right: 24 })

      if (this.works.length === 0) {
        // 空状态提示
        Column() {
          Text('暂无近作')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(14)
            .fontColor($r('app.color.stone_gray'))
          Text('去编辑一张吧')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .margin({ top: 4 })
            .fontColor($r('app.color.stone_gray'))
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 横向滚动列表
        List({ space: 12 }) {
          ForEach(this.works, (item: WorkRecord, index: number) => {
            ListItem() {
              this.WorkCard(item)
            }
          }, (item: WorkRecord) => item.id)
        }
        .width('100%')
        .height(180)
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .padding({ left: 24, right: 24 })
      }
    }
    .width('100%')
    .padding({ top: 24, bottom: 8 })
  }

  @Builder
  WorkCard(item: WorkRecord) {
    Column() {
      // 上方图片区
      Stack({ alignContent: Alignment.BottomStart }) {
        if (item.previewImage !== null) {
          // 种子作品：使用 Resource 预览图
          Image(item.previewImage)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else if (item.previewImageUri.length > 0) {
          // 用户保存作品：使用沙箱 URI 预览图
          Image(item.previewImageUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          // 无预览图：显示占位
          Column() {
            Text($r('app.string.home_seal'))
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(26)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_red'))
              .width(48)
              .height(48)
              .borderRadius(24)
              .border({ width: 1.5, color: $r('app.color.ink_red') })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.paper_white'))
        }

        // 底部半透明信息栏
        Row() {
          Column() {
            Text(item.title)
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.date)
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(10)
              .margin({ top: 2 })
              .fontColor('#CCFFFFFF')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#66000000')
      }
      .width('100%')
      .height('100%')
      .borderRadius(12)
      .clip(true)
    }
    .width(140)
    .height(180)
    .borderRadius(12)
    .onClick(() => {
      this.onCardClick(item.id);
    })
  }
}
