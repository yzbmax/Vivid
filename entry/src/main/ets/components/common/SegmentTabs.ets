import { Theme } from './Theme';

export interface SegmentItem {
  label: string;
  key: string;
}

/**
 * 通用分段切换。
 * chipMode=true：填充 chip + 激活角标（作品页筛选：全部卷宗/已封印/草稿，横向可滚动）。
 * chipMode=false：下划线指示条模式（编辑页主体/背景由 RegionTabs 语义封装复用）。
 * 参考：docs/公共组件预留文档.md B2。
 */
@Component
export struct SegmentTabs {
  @Prop items: SegmentItem[] = [];
  @Prop selected: string = '';
  /** 激活 chip 右下角装饰方块（作品页筛选态） */
  cornerMark: boolean = false;
  chipMode: boolean = true;
  onChange: (key: string) => void = () => {};

  @Styles
  chipBase() {
    .padding({
      left: Theme.CHIP_PADDING_X,
      right: Theme.CHIP_PADDING_X,
      top: Theme.CHIP_PADDING_Y,
      bottom: Theme.CHIP_PADDING_Y
    })
    .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })
  }

  @Styles
  chipPressed() {
    .scale({ x: 0.98, y: 0.98 })
  }

  build() {
    if (this.chipMode) {
      Scroll() {
        Row({ space: Theme.GUTTER }) {
          ForEach(this.items, (item: SegmentItem) => {
            Stack({ alignContent: Alignment.BottomEnd }) {
              Text(item.label)
                .fontFamily(Theme.FONT_MONO)
                .fontSize(Theme.FONT_SIZE_LABEL_MONO)
                .fontWeight(500)
                .fontColor(item.key === this.selected ? Theme.ON_PRIMARY : Theme.ON_SURFACE_VARIANT_70)
              if (this.selected === item.key && this.cornerMark) {
                Row()
                  .width(8)
                  .height(8)
                  .backgroundColor(Theme.ON_PRIMARY_FIXED_VARIANT)
              }
            }
            .chipBase()
            .backgroundColor(item.key === this.selected ? Theme.PRIMARY : Theme.SURFACE_CONTAINER_HIGHEST)
            .onClick(() => {
              this.onChange(item.key);
            })
            .stateStyles({ pressed: this.chipPressed })
            .animation({ duration: 150, curve: Curve.EaseOut })
          }, (item: SegmentItem) => item.key)
        }
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ top: 24, bottom: 24 })
    } else {
      Row() {
        ForEach(this.items, (item: SegmentItem) => {
          Column() {
            Text(item.label)
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
              .fontWeight(600)
              .fontColor(item.key === this.selected ? Theme.ON_SURFACE : Theme.ON_SURFACE_VARIANT_70)
            Row()
              .width('100%')
              .height(3)
              .margin({ top: 8 })
              .backgroundColor(item.key === this.selected ? Theme.SEAL_RED : Color.Transparent)
          }
          .layoutWeight(1)
          .onClick(() => {
            this.onChange(item.key);
          })
        }, (item: SegmentItem) => item.key)
      }
      .width('100%')
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    }
  }
}
