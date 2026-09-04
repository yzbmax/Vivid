import { Theme } from '../common/Theme';
import { SealBadge } from '../common/SealBadge';
import { StatusTag } from '../common/StatusTag';
import { WorkRecord, WorkStatus } from '../../models/WorkRecord';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';

/**
 * 作品卡片：缩略图 + 浮印（SealBadge）/ 草稿遮罩 + 标题 + 日期 + 状态图标。
 * 参考：docs/公共组件预留文档.md C5 / stitch_ Works Page。
 * 注：事件字段名 onCardClick 规避与基类通用事件 onClick 的同名冲突。
 */
@Component
export struct WorkCard {
  data: WorkRecord = new WorkRecord();
  onCardClick: (id: string) => void = () => {};
  onCardLongPress: (id: string) => void = () => {};

  @Styles
  cardPressed() {
    .scale({ x: 0.98, y: 0.98 })
  }

  build() {
    Column() {
      // 缩略图区（h-40 等高于参考样板）
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.previewSource())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
        if (this.data.status === WorkStatus.Draft) {
          // 未完成遮罩：反色面半透明 + 居中状态标签
          Column() {
            StatusTag({ text: '未完成 (DRAFT)', tone: 'draft' })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Theme.INVERSE_SURFACE_40)
          .backdropBlur(2)
        } else if (this.data.status === WorkStatus.Damaged) {
          // 损坏遮罩：红色半透明 + 居中状态标签
          Column() {
            StatusTag({ text: '已损坏 (DAMAGED)', tone: 'draft' })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#40FF0000')
        } else if (this.data.sealGlyph.length > 0) {
          SealBadge({ glyph: this.data.sealGlyph, boxSize: 24 })
            .align(Alignment.TopEnd)
            .margin({ top: 8, right: 8 })
        }
      }
      .width('100%')
      .height(Theme.CARD_IMAGE_HEIGHT)
      // 信息区（p-3）
      Column({ space: 8 }) {
        Text(this.data.title)
          .width('100%')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_SURFACE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text(this.displayDate())
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.ON_SURFACE_VARIANT)
          Blank()
          Image(this.statusIcon())
            .width(14)
            .height(14)
            .fillColor(this.statusIconColor())
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Theme.SURFACE_CONTAINER)
    .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })
    .clip(true)
    .onClick(() => {
      this.onCardClick(this.data.id);
    })
    .gesture(
      GestureGroup(GestureMode.Parallel,
        LongPressGesture({ repeat: false })
          .onAction(() => {
            this.onCardLongPress(this.data.id);
          })
      )
    )
    .stateStyles({ pressed: this.cardPressed })
  }

  /** 日期显示：优先用 date 字段，无值时从 createdAt 格式化 */
  private displayDate(): string {
    if (this.data.date.length > 0) {
      return this.data.date;
    }
    if (this.data.createdAt <= 0) {
      return '';
    }
    const d = new Date(this.data.createdAt);
    const y = d.getFullYear().toString();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return y + '.' + m + '.' + day;
  }

  /**
   * 缩略图源：previewImageUri > sourceImageUri > previewImage > 兜底画作。
   * 通过 resolveWorkImageSource 补齐 file:// 前缀，并自动修复 .image 文件识别问题。
   */
  private previewSource(): ResourceStr {
    return resolveWorkImageSource(
      this.data.previewImageUri,
      this.data.sourceImageUri,
      this.data.previewImage
    );
  }

  private statusIcon(): Resource {
    return this.data.status === WorkStatus.Draft ? $r('app.media.icon_edit') : $r('app.media.icon_archive');
  }

  private statusIconColor(): string {
    return this.data.status === WorkStatus.Draft ? Theme.ON_SURFACE_VARIANT : Theme.PRIMARY;
  }
}
