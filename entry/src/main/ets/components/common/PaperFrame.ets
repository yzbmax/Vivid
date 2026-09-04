import { Theme } from './Theme';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';

/**
 * 卷轴装裱画框（预留组件 F1 的详情页形态）：纸面装裱 + 图片 + 网格叠层 + 底部卷宗编号。
 * 参考：docs/公共组件预留文档.md F1、stitch「Work Detail Page」Canvas Area。
 */
@Component
export struct PaperFrame {
  /** 图片（作品缩略图；后续可扩展为 PixelMap） */
  image: Resource | null = null;
  /** 图片 URI（用户保存作品的沙箱路径） */
  imageUri: string = '';
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

  /** 判断 image 是否有实际内容（排除空字符串）。 */
  private hasImage(): boolean {
    if (this.image == null) {
      return false;
    }
    if (typeof this.image === 'string') {
      return (this.image as string).length > 0;
    }
    return true;
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
          Image(resolveWorkImageSource(
            this.imageUri,
            '',
            this.image
          ))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
          this.gridOverlay()
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
              .fontFamily(Theme.FONT_SERIF)
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
