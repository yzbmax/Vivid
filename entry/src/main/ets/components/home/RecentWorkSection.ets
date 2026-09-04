import { WorkRecord, WorkStatus } from '../../models/WorkRecord';
import { Theme } from '../common/Theme';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';

/**
 * 案头近辑（RecentWorkSection）
 *
 * 依据：Mask & Seal 设计规范（Canvas Hub 样板 _6）
 * - 3:4 比例画廊装裱卡（含 4px 宣纸衬边装裱），分离照片与底部批注
 * - 右上角快速通达「全部卷宗 ›」
 * - 独立文书元数据区：宋体题名、等宽纪年与微型朱红钤印
 */
@Component
export struct RecentWorkSection {
  @Prop works: WorkRecord[] = [];
  onCardClick: (id: string) => void = () => {};
  onViewAllClick: () => void = () => {};

  @Styles
  cardPressed() {
    .scale({ x: 0.97, y: 0.97 })
  }

  private formatDate(createdAt: number): string {
    if (!createdAt || createdAt <= 0) {
      return '甲辰年';
    }
    const d = new Date(createdAt);
    const y = d.getFullYear().toString();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}.${m}.${day}`;
  }

  build() {
    Column() {
      // 区块标题：中文"案头近辑" + 英文"RECENT ARCHIVES" + 右侧"全部卷宗 ›"
      Row() {
        Row() {
          Text($r('app.string.home_work_cn'))
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ON_SURFACE)
            .letterSpacing(1.5)

          Text($r('app.string.home_work_en'))
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .letterSpacing(1.5)
            .margin({ left: 8 })
            .fontColor(Theme.PRIMARY)
        }

        Blank()

        // 全部卷宗入口
        Row({ space: 2 }) {
          Text('全部卷宗')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(11)
            .fontColor(Theme.PRIMARY)
            .letterSpacing(1)
          Text('›')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
        }
        .onClick(() => this.onViewAllClick())
      }
      .width('100%')
      .margin({ bottom: 14 })
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      if (this.works.length === 0) {
        // 雅致空状态
        Column({ space: 6 }) {
          Text('案头尚无归档 · 待呈佳作')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontColor(Theme.OUTLINE)
            .letterSpacing(1)
          Text('轻触上方「呈交新卷宗」启幕')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(11)
            .fontColor(Theme.OUTLINE_VARIANT)
        }
        .width('100%')
        .height(160)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .border({ width: 1, color: Theme.OUTLINE_VARIANT, style: BorderStyle.Dashed })
        .borderRadius(Theme.RADIUS_DEFAULT)
        .margin({ left: 20, right: 20 })
      } else {
        // 横向滚动画廊
        List({ space: 14 }) {
          ForEach(this.works, (item: WorkRecord) => {
            ListItem() {
              this.ScrollCard(item)
            }
          }, (item: WorkRecord) => item.id)
        }
        .width('100%')
        .height(224)
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }
    }
    .width('100%')
    .padding({ top: 20, bottom: 8 })
  }

  // 3:4 比例宣纸装裱展卷卡
  @Builder
  ScrollCard(item: WorkRecord) {
    Column() {
      // 宣纸装裱画芯区（四周带 4px 纸白装裱衬垫）
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(resolveWorkImageSource(
          item.previewImageUri,
          item.sourceImageUri,
          item.previewImage
        ))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(2)

        // 状态微角标
        if (item.status === WorkStatus.Draft) {
          Text('草稿')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(9)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .backgroundColor(Theme.PAPER_SURFACE_80)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius(2)
            .margin({ left: 6, bottom: 6 })
        }
      }
      .width('100%')
      .height(154)
      .padding(4)
      .backgroundColor(Theme.PAPER_SURFACE)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .clip(true)

      // 独立元数据区（不盖在画面上）
      Column({ space: 4 }) {
        Text(item.title)
          .width('100%')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_SURFACE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(item.date && item.date.length > 0 ? item.date : this.formatDate(item.createdAt))
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .letterSpacing(0.5)

          Blank()

          Image(item.status === WorkStatus.Draft ? $r('app.media.icon_edit') : $r('app.media.icon_archive'))
            .width(13)
            .height(13)
            .fillColor(item.status === WorkStatus.Draft ? Theme.ON_SURFACE_VARIANT : Theme.PRIMARY)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 6, bottom: 8 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width(152)
    .height(220)
    .backgroundColor(Theme.SURFACE_CONTAINER_LOW)
    .border({ width: 1, color: Theme.OUTLINE_VARIANT })
    .borderRadius(Theme.RADIUS_DEFAULT)
    .shadow({ radius: 3, color: Theme.SHADOW_SM, offsetY: 1 })
    .clip(true)
    .stateStyles({ pressed: this.cardPressed })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .onClick(() => {
      this.onCardClick(item.id);
    })
  }
}
