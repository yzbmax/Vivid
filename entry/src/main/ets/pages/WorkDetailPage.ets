import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PaperFrame } from '../components/common/PaperFrame';
import { MetadataBar, MetadataItem } from '../components/common/MetadataBar';
import { NotesCard } from '../components/common/NotesCard';
import { SealBadge } from '../components/common/SealBadge';
import { WorkRecord } from '../models/WorkRecord';
import { findWork } from '../models/MockWorks';

/**
 * 作品详情页（Work Detail，stitch「Work Detail Page」卷宗详情样板）。
 *
 * 从作品页点击作品进入：展示装裱大图、卷宗元数据、案卷批注；
 * 「启封续编」为后续接入独立编辑页（EditPage）的入口，V1 先给轻提示。
 * 独立页面，不显示底部主导航（PRD F9）。
 */

@Entry
@Component
export struct WorkDetailPage {
  @State workId: string = '';
  @State work: WorkRecord | null = null;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    this.workId = params?.workId ?? '';
    this.work = findWork(this.workId);
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
      // 提示失败不影响页面
    }
  }

  /** 卷宗元数据三栏 */
  private metadataItems(): MetadataItem[] {
    return [
      { label: '分辨率', value: '4200 × 5600' },
      { label: '呈报日期', value: this.work?.date ?? '' },
      { label: '滤色覆膜', value: '朱砂 · 叁', valueColor: Theme.PRIMARY }
    ];
  }

  /** 页内标题区：返回链接 + 大标题 + 朱砂下划线 + 钤印 */
  @Builder
  header() {
    Row() {
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Image($r('app.media.icon_back'))
            .width(16)
            .height(16)
            .fillColor(Theme.PRIMARY)
          Text('返 回 卷 宗 库')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO)
            .fontColor(Theme.PRIMARY)
            .letterSpacing(1.3)
        }
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })
        Text(this.work?.title ?? '卷宗详情')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(Theme.FONT_SIZE_HEADLINE_LG_MOBILE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_SURFACE)
          .letterSpacing(0.7)
          .margin({ top: 12 })
        Row()
          .width(48)
          .height(2)
          .backgroundColor(Theme.PRIMARY)
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      if (this.work != null && this.work.sealGlyph !== '') {
        SealBadge({ glyph: this.work.sealGlyph, boxSize: 40, rotation: 3, filled: true })
      }
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    .margin({ bottom: 24 })
    .alignItems(VerticalAlign.Bottom)
  }

  /** 操作区：分享（ghost）+ 启封续编（primary） */
  @Builder
  actionArea() {
    Row({ space: 16 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text('↗')
          .fontSize(20)
          .fontColor(Theme.ON_SURFACE_VARIANT)
      }
      .width(64)
      .height(56)
      .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
      .onClick(() => {
        this.toast('分享后续接入');
      })
      Row({ space: 8 }) {
        Image($r('app.media.icon_edit'))
          .width(20)
          .height(20)
          .fillColor(Theme.ON_PRIMARY)
        Text('启封续编')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(18)
          .fontColor(Theme.ON_PRIMARY)
          .letterSpacing(3)
      }
      .layoutWeight(1)
      .height(56)
      .backgroundColor(Theme.PRIMARY)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.toast('编辑页后续接入');
      })
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
  }

  private notesText(): string {
    return '此帧明暗反差强烈，高光处略显单薄。建议后续复核时，加重天际线的墨色压暗处理，并微调青色通道以增强寒意。';
  }

  build() {
    // @Entry 根节点必须是内置容器组件，故以 Column 作为外层，宣纸背景作为子层铺满
    Column() {
      PaperBackground() {
        Scroll() {
          Column() {
            this.header()
            if (this.work != null) {
              PaperFrame({ image: this.work.previewImage, fileNo: this.work.id })
                .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
                .margin({ bottom: 32 })
              MetadataBar({ columns: this.metadataItems() })
                .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 24 })
            }
            NotesCard({ content: this.notesText() })
              .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 32 })
            this.actionArea()
          }
          .width('100%')
          .padding({ top: 24, bottom: 32 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}
