// 辅助说明区：隐私说明文案，紧跟 HeroCard 之后。

import { Theme } from '../common/Theme';

@Component
export struct CtaBlock {
  build() {
    Row() {
      Text($r('app.string.home_cta_note'))
        .fontFamily(Theme.FONT_MONO)
        .fontSize(11)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .letterSpacing(1.2)
    }
    .width('100%')
    .padding({ top: 14, bottom: 6 })
    .justifyContent(FlexAlign.Center)
  }
}
