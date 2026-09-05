import { Theme } from './Theme';

/**
 * 空状态：作品页无作品时的引导（图标 + 文案 + 主按钮）。
 * 参考：docs/公共组件预留文档.md B8 / PRD F10。
 */
@Component
export struct EmptyState {
  title: string = '暂无作品';
  description: string = '从首页导入图片，开始第一次分区调色';
  actionText: string = '前往首页';
  onAction: () => void = () => {};

  @Styles
  primaryPressed() {
    .scale({ x: 0.98, y: 0.98 })
  }

  build() {
    Column({ space: 12 }) {
      Image($r('app.media.icon_archive'))
        .width(48)
        .height(48)
        .fillColor(Theme.OUTLINE)
        .opacity(0.6)
      Text(this.title)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text(this.description)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .textAlign(TextAlign.Center)
      Row() {
        Text(this.actionText)
          .fontFamily(Theme.FONT_SANS)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ON_PRIMARY)
      }
      .width(160)
      .height(48)
      .margin({ top: 12 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Theme.PRIMARY)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .onClick(() => {
        this.onAction();
      })
      .stateStyles({ pressed: this.primaryPressed })
    }
    .width('100%')
    .padding({ top: 96, bottom: 96 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
