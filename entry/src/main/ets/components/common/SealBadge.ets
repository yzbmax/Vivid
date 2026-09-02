import { Theme } from './Theme';

/**
 * 钤印（装饰印章）：红底白字 / 红框红字的方形印章，落于图片角、作品卡片角。
 * 参考：docs/公共组件预留文档.md B6。
 * 注：字段名 boxSize / rotation 规避与基类通用属性 size / rotate 的同名冲突。
 */
@Component
export struct SealBadge {
  /** 印章文字（支持 1-2 字） */
  glyph: string = '甲';
  /** 边长 vp（卡片小印 24 ~ 标题印 40） */
  boxSize: number = 24;
  /** 微旋转（-6°~+3°，印章感） */
  rotation: number = 0;
  /** true=红底白字，false=红框红字 */
  filled: boolean = true;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.glyph)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(this.boxSize * 0.42)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.filled ? Theme.ON_PRIMARY : Theme.SEAL_RED)
    }
    .width(this.boxSize)
    .height(this.boxSize)
    .backgroundColor(this.filled ? Theme.PRIMARY : Color.Transparent)
    .border({ width: this.filled ? 0 : 1, color: Theme.SEAL_RED })
    .rotate({ angle: this.rotation })
    .shadow({ radius: 6, color: '#1A000000', offsetY: 2 })
  }
}
