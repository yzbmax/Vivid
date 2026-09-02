import { RegionKey } from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 主体 / 背景区域切换（公共组件预留文档冻结契约，编辑页专属）。
 *
 * props: selected: 'subject' | 'background'（默认 'subject'）
 * event: onChange(region)
 *
 * 交互红线（V2 §21）：切换区域不得重新调用 AI、不得重建蒙版、
 * 不得丢失另一区域参数——本组件只抛事件，状态由 EditPage 持有。
 */
@Component
export struct RegionTabs {
  @Prop selected: RegionKey = 'subject';
  onChange: (region: RegionKey) => void = () => {};

  private readonly regions: RegionKey[] = ['subject', 'background'];

  build() {
    Row() {
      ForEach(this.regions, (region: RegionKey) => {
        Column() {
          Text(region === 'subject' ? '主体' : '背景')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
            .fontWeight(600)
            .fontColor(region === this.selected ? Theme.ON_SURFACE : Theme.ON_SURFACE_VARIANT_70)
          Row()
            .width('100%')
            .height(3)
            .margin({ top: Theme.SPACE_MD })
            .backgroundColor(region === this.selected ? Theme.SEAL_RED : Color.Transparent)
        }
        .layoutWeight(1)
        .accessibilityText(region === 'subject' ? '主体区域' : '背景区域')
        .onClick(() => this.onChange(region))
      }, (region: RegionKey) => region)
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
  }
}
