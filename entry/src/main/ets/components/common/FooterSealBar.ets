import { Theme } from './Theme';

/**
 * 卷宗落款信息条：底导航上方居中一条 pill，展示已汇集的作品总数。
 * 参考：docs/公共组件预留文档.md A4。
 */
@Component
export struct FooterSealBar {
  /** 作品总数 */
  count: number = 0;

  build() {
    Row() {
      Text(`汇集佳作 · 共 ${this.count} 卷`)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO)
        .fontWeight(500)
        .fontColor(Theme.PRIMARY_60)
        .letterSpacing(1.3)
    }
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .border({ width: 1, color: Theme.PRIMARY_20 })
    // .backgroundColor(Theme.PRIMARY_05)
  }
}
