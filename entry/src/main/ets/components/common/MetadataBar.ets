import { Theme } from './Theme';

/** 元数据栏单项 */
export interface MetadataItem {
  label: string;
  value: string;
  valueColor?: string;
}

/**
 * 三栏元数据条（预留组件 F3）：左朱砂竖条 + 分栏数据（竖线分隔）。
 * 布局用 Row：左竖条 height 100% 拉伸，内容行撑起整条高度。
 * 参考：docs/公共组件预留文档.md F3、stitch「Work Detail Page」Metadata。
 */
@Component
export struct MetadataBar {
  columns: MetadataItem[] = [];

  build() {
    Row() {
      // 左朱砂竖条（stretch 整行高度）
      Row()
        .width(4)
        .height(50)
        .backgroundColor(Theme.PRIMARY)
      // 分栏数据
      Row() {
        ForEach(this.columns, (col: MetadataItem, index: number) => {
          if (index > 0) {
            Row()
              .width(1)
              .height(28)
              .backgroundColor(Theme.OUTLINE_VARIANT)
              .opacity(0.6)
          }
          Column({ space: 2 }) {
            Text(col.label)
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .letterSpacing(1.3)
            Text(col.value)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontColor(col.valueColor ?? Theme.ON_SURFACE)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: index > 0 ? 16 : 0 })
        }, (col: MetadataItem, index: number) => `${index}-${col.label}`)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 13, right: 0, top: 20, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE)
    .shadow({ radius: 4, color: Theme.SHADOW_SM, offsetY: 1 })
  }
}
