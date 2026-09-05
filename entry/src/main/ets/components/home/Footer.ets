import { Theme } from '../common/Theme';

/**
 * 页脚（Footer）
 *
 * 依据：Mask & Seal 设计规范（Canvas Hub 样板 _6 §页脚落款 pill）
 * - 专属文书落款封签：[ 炎国跨署呈报复核 · 卷宗第肆零玖号 ]
 * - 等宽宽距数字艺术档案署名
 */
@Component
export struct Footer {
  build() {
    Column({ space: 10 }) {
      // 卷宗落款 Pill
      Row() {
        Text($r('app.string.home_footer'))
          .fontFamily(Theme.FONT_MONO)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.PRIMARY_60)
          .letterSpacing(1.8)
      }
      .padding({ left: 14, right: 14, top: 4, bottom: 4 })
      .border({ width: 1, color: Theme.PRIMARY_20 })
      .backgroundColor(Theme.PRIMARY_05)
      .borderRadius(2)

      // 品牌典藏署名
      Text('VIVID · DIGITAL ART ARCHIVE')
        .fontFamily(Theme.FONT_MONO)
        .fontSize(10)
        .letterSpacing(2)
        .fontColor(Theme.OUTLINE)
    }
    .width('100%')
    .padding({ top: 20, bottom: 36 })
    .alignItems(HorizontalAlign.Center)
  }
}
