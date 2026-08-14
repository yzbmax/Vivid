import { Theme } from './Theme';

/**
 * 状态标签：sealed=深朱砂底白字；draft=纸面底墨字；damaged=错误容器。
 * 参考：docs/公共组件预留文档.md B5。
 */
@Component
export struct StatusTag {
  text: string = '';
  tone: string = 'sealed';
  /** 是否覆盖展示在图片上（V1 作品页用于草稿遮罩居中标签） */
  absolute: boolean = true;

  build() {
    Text(this.text)
      .fontFamily(Theme.FONT_MONO)
      .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
      .fontWeight(500)
      .fontColor(this.textColor())
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.bgColor())
      .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })
  }

  private bgColor(): string {
    if (this.tone === 'sealed') {
      return Theme.PRIMARY;
    }
    if (this.tone === 'damaged') {
      return Theme.ERROR_CONTAINER;
    }
    return Theme.SURFACE_CONTAINER;
  }

  private textColor(): string {
    if (this.tone === 'sealed') {
      return Theme.ON_PRIMARY;
    }
    if (this.tone === 'damaged') {
      return Theme.ON_ERROR_CONTAINER;
    }
    return Theme.ON_SURFACE;
  }
}
