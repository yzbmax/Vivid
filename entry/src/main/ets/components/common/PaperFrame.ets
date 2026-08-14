import { Theme } from './Theme';

/**
 * 卷轴装裱画框（预留组件 F1 的详情页形态）：纸面装裱 + 图片 + 网格叠层 + 四角括号 + 底部卷宗编号。
 * 参考：docs/公共组件预留文档.md F1、stitch「Work Detail Page」Canvas Area。
 */
@Component
export struct PaperFrame {
  /** 图片（作品缩略图；后续可扩展为 PixelMap） */
  image: Resource | null = null;
  /** 卷宗编号（FILE . NO 值，如 0409-A） */
  fileNo: string = '';
  /** 是否显示背后堆叠阴影 */
  showShadow: boolean = true;
  /** 宽高比（命名规避与 ArkUI 通用属性 aspectRatio 冲突） */
  frameRatio: number = 3 / 4;

  /** 图片上的分析网格叠层（白线 10%，约 2×2 细分） */
  @Builder
  gridOverlay() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            ['#1AFFFFFF', 0], ['#1AFFFFFF', 0.02], ['#00FFFFFF', 0.02], ['#00FFFFFF', 0.5],
            ['#1AFFFFFF', 0.5], ['#1AFFFFFF', 0.52], ['#00FFFFFF', 0.52], ['#00FFFFFF', 1]
          ]
        })
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#1AFFFFFF', 0], ['#1AFFFFFF', 0.02], ['#00FFFFFF', 0.02], ['#00FFFFFF', 0.5],
            ['#1AFFFFFF', 0.5], ['#1AFFFFFF', 0.52], ['#00FFFFFF', 0.52], ['#00FFFFFF', 1]
          ]
        })
    }
    .width('100%')
    .height('100%')
    .opacity(0.4)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背后堆叠阴影（纸张层次）：与装裱纸同宽高比，偏移 8,8 露出边角（避免百分比高度塌陷）
      if (this.showShadow) {
        Stack()
          .width('100%')
          .aspectRatio(this.frameRatio)
          .backgroundColor(Theme.SURFACE_CONTAINER_HIGH)
          .translate({ x: 8, y: 8 })
      }
      // 装裱纸（p-3，底部 pb-12 给元数据留位）
      Column() {
        // 图片区
        Stack() {
          if (this.image != null) {
            Image(this.image)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text('无预览')
                .fontColor(Theme.ON_SURFACE_VARIANT)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          this.gridOverlay()
          // 四角括号（定位用 position + markAnchor；BorderOptions 按边用 width/color 的对象形式）
          Row()
            .width(12)
            .height(12)
            .border({
              width: { top: 2, left: 2 },
              color: { top: Theme.ON_SURFACE_VARIANT, left: Theme.ON_SURFACE_VARIANT }
            })
            .position({ x: 0, y: 0 })
          Row()
            .width(12)
            .height(12)
            .border({
              width: { top: 2, right: 2 },
              color: { top: Theme.ON_SURFACE_VARIANT, right: Theme.ON_SURFACE_VARIANT }
            })
            .position({ x: '100%', y: 0 })
            .markAnchor({ x: 12, y: 0 })
          Row()
            .width(12)
            .height(12)
            .border({
              width: { bottom: 2, left: 2 },
              color: { bottom: Theme.ON_SURFACE_VARIANT, left: Theme.ON_SURFACE_VARIANT }
            })
            .position({ x: 0, y: '100%' })
            .markAnchor({ x: 0, y: 12 })
          Row()
            .width(12)
            .height(12)
            .border({
              width: { bottom: 2, right: 2 },
              color: { bottom: Theme.ON_SURFACE_VARIANT, right: Theme.ON_SURFACE_VARIANT }
            })
            .position({ x: '100%', y: '100%' })
            .markAnchor({ x: 12, y: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .clip(true)

        // 底部元数据：FILE . NO + 编号 + 已验证徽标
        Row() {
          Column({ space: 2 }) {
            Text('FILE . NO')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.OUTLINE)
              .letterSpacing(1.3)
            Text(this.fileNo)
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO)
              .fontColor(Theme.ON_SURFACE_VARIANT)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Row() {
            Text('✓')
              .fontSize(16)
              .fontColor(Theme.PRIMARY)
          }
          .width(32)
          .height(32)
          .backgroundColor(Theme.PRIMARY_20)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding({ top: 12 })
      }
      .width('100%')
      .aspectRatio(this.frameRatio)
      .backgroundColor(Theme.PAPER_SURFACE)
      .padding(12)
      .shadow({ radius: 8, color: Theme.SHADOW_SM, offsetY: 4 })
    }
    .width('100%')
  }
}
