// 快捷功能区：2×4 功能网格，展示核心快捷入口。
// 每个格子含一个矢量图标（Path 手绘 SVG）和名称标签。
// 由 HomePage 通过 @Prop 传入 ToolItem[] 数据。

import { ToolItem } from './HomeModels';
import { EditorToolKey } from '../../models/EditModels';

@Component
export struct QuickToolsSection {
  @Prop tools: ToolItem[] = [];
  onToolClick: (key: EditorToolKey) => void = () => {};

  @Styles
  toolPressed() {
    .scale({ x: 0.98, y: 0.98 })
  }

  build() {
    Column() {
      // 区块标题：中文"快捷功能" + 英文"QUICK TOOLS"
      Row() {
        Text($r('app.string.home_tools_cn'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_tools_en'))
          .fontSize(11)
          .letterSpacing(2)
          .margin({ left: 8 })
          .fontColor($r('app.color.stone_gray'))
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 4 列 × 2 行网格
      Grid() {
        ForEach(this.tools, (item: ToolItem) => {
          GridItem() {
            this.ToolCell(item)
          }
        }, (_item: ToolItem, index: number) => index.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(0)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 8 })
  }

  // 单个功能格子
  @Builder
  ToolCell(item: ToolItem) {
    Column() {
      // 图标容器 + 角标
      Stack({ alignContent: Alignment.TopEnd }) {
        // 圆角方形容器
        Column() {
          Image(item.icon)
            .width(28)
            .height(28)
        }
        .width(48)
        .height(48)
        .borderRadius(12)
        .backgroundColor($r('app.color.paper_pink'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)


      }
      .width(48)
      .height(48)

      // 功能名称
      Text(item.name)
        .fontSize(11)
        .fontColor($r('app.color.ink_dark'))
        .margin({ top: 6 })
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onToolClick(item.key))
    .stateStyles({ pressed: this.toolPressed })
    .animation({ duration: 150, curve: Curve.EaseOut })
  }
}
