import { Theme } from './Theme';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';

/**
 * 卷轴装裱画框（预留组件 F1 的详情页形态）：纸面装裱 + 图片 + 底部卷宗编号。
 * 遵循原汁原味原本比例呈现画心，彻底杜绝裁切与画面遮挡。
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
  @Prop frameRatio: number = 0;
  /** 图片加载完成的原始尺寸回调 */
  onImageSize?: (width: number, height: number) => void;

  @State private naturalRatio: number = 0;

  aboutToAppear(): void {
    if (this.frameRatio > 0) {
      this.naturalRatio = this.frameRatio;
    }
  }

  private getImageRatio(): number {
    if (this.naturalRatio > 0) {
      return this.naturalRatio;
    }
    if (this.frameRatio > 0) {
      return this.frameRatio;
    }
    return 1.0;
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
      // 装裱纸卡（四周 12vp 雅致宣纸留白，底部放置 FILE . NO 案卷编号与文人验证印章）
      Column() {
        // 画心图片区：使用原本自然画幅比例，彻底杜绝任何裁切与遮挡
        Stack() {
          Image(resolveWorkImageSource(
            this.imageUri,
            '',
            this.image
          ))
            .width('100%')
            .aspectRatio(this.getImageRatio())
            .objectFit(ImageFit.Contain)
            .borderRadius(2)
            .onComplete((event) => {
              if (event && event.width > 0 && event.height > 0) {
                this.naturalRatio = event.width / event.height;
                if (this.onImageSize) {
                  this.onImageSize(event.width, event.height);
                }
              }
            })
        }
        .width('100%')
        .aspectRatio(this.getImageRatio())

        // 底部元数据：FILE . NO + 编号 + 已验证徽标
        Row() {
          Column({ space: 2 }) {
            Text('FILE . NO')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
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
      .backgroundColor(Theme.PAPER_SURFACE)
      .padding(12)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .shadow({ radius: 8, color: Theme.SHADOW_SM, offsetY: 4 })
    }
    .width('100%')
  }
}
