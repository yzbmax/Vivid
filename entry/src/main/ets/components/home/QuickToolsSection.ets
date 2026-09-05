import { ToolItem } from './HomeModels';
import { EditorToolKey } from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 快捷功能区（QuickToolsSection）——「格物八法」
 *
 * 依据：Mask & Seal 设计规范
 * - 去除彩色大杂烩粉红底色，采用纸白微浮雕底座（Theme.PAPER_SURFACE）与细边框（Theme.OUTLINE_VARIANT）
 * - 衬线体宋风排印，按压微动效增强金石器物的交互质感
 */
@Component
export struct QuickToolsSection {
  @Prop tools: ToolItem[] = [];
  onToolClick: (key: EditorToolKey) => void = () => {};

  private scroller: Scroller = new Scroller();
  @State scrollProgress: number = 0;

  @Styles
  toolPressed() {
    .scale({ x: 0.94, y: 0.94 })
  }

  build() {
    Column() {
      // 区块标题：中文"格物八法" + 英文"QUICK INSTRUMENTS" + 右侧横滑引导
      Row() {
        Row() {
          Text($r('app.string.home_tools_cn'))
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ON_SURFACE)
            .letterSpacing(1.5)

          Text($r('app.string.home_tools_en'))
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .letterSpacing(1.5)
            .margin({ left: 8 })
            .fontColor(Theme.PRIMARY)
        }

        Blank()

        // 显式可滑动指引（与案头近辑"全部卷宗 ›"对齐统一）
        Row({ space: 3 }) {
          Text('滑动浏览')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(11)
            .fontColor(Theme.ON_SURFACE_VARIANT)

          Text('›')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
        }
      }
      .width('100%')
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .margin({ bottom: 12 })

      // 单行横向滚轴条目（卡片尺寸精调，确保右侧始终露出半张卡片 Peek Affordance）
      List({ space: 10, scroller: this.scroller }) {
        ForEach(this.tools, (item: ToolItem, index: number) => {
          ListItem() {
            this.ToolCell(item)
          }
        }, (item: ToolItem, index: number) => `${item.key}_${index}`)
      }
      .width('100%')
      .height(80)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .onScrollIndex((start: number, _end: number) => {
        const maxStart = Math.max(1, this.tools.length - 4);
        const progress = Math.min(1, Math.max(0, start / maxStart));
        this.scrollProgress = progress;
      })

      // 底部微指示条（28vp 极简宣纸轨道 + 朱砂滑块，直观反馈滑动进度）
      Row() {
        Stack({ alignContent: Alignment.Start }) {
          // 轨道
          Row()
            .width(28)
            .height(3)
            .borderRadius(1.5)
            .backgroundColor(Theme.OUTLINE_VARIANT)

          // 朱砂滑块
          Row()
            .width(12)
            .height(3)
            .borderRadius(1.5)
            .backgroundColor(Theme.PRIMARY)
            .translate({ x: 16 * this.scrollProgress })
            .animation({ duration: 120, curve: Curve.EaseOut })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 18, bottom: 6 })
  }

  // 单个功能格子
  @Builder
  ToolCell(item: ToolItem) {
    Column() {
      // 典雅纸白微浮雕底座
      Stack({ alignContent: Alignment.Center }) {
        Image(item.icon)
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .borderRadius(Theme.RADIUS_LG)
      .backgroundColor(Theme.PAPER_SURFACE)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })

      // 功能名称
      Text(item.name)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(10.5)
        .fontColor(Theme.ON_SURFACE)
        .margin({ top: 5 })
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .letterSpacing(0.3)
    }
    .width(60)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onToolClick(item.key))
    .stateStyles({ pressed: this.toolPressed })
    .animation({ duration: 150, curve: Curve.EaseOut })
  }
}
