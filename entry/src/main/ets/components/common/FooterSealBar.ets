import { Theme } from './Theme';

/**
 * 卷宗落款信息条：底导航上方居中一条 pill（强化「呈报复核」语境）。
 * 参考：docs/公共组件预留文档.md A4。
 */
@Component
export struct FooterSealBar {
  /** 卷宗编号（中文数字） */
  number: string = '肆零玖';

  build() {
    Row() {
      Text(`卷宗第${this.number}号`)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO)
        .fontWeight(500)
        .fontColor(Theme.PRIMARY_60)
        .letterSpacing(1.3)
    }
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .border({ width: 1, color: Theme.PRIMARY_20 })
    .backgroundColor(Theme.PRIMARY_05)
  }
}
