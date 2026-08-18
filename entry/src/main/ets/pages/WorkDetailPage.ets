import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PageHeader } from '../components/common/PageHeader';
import { PaperFrame } from '../components/common/PaperFrame';
import { MetadataBar, MetadataItem } from '../components/common/MetadataBar';
import { NotesCard } from '../components/common/NotesCard';
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
struct WorkDetailPage {
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
        if (this.work != null) {
          // 待 C 在 main_pages.json 注册 pages/EditPage 后生效
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/EditPage',
            params: { source: 'work', workId: this.work.id }
          }).catch(() => {
            this.toast('编辑页尚未就绪');
          });
        }
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
        if (this.work == null) {
          // 无效 workId：显示错误态
          Column() {
            PageHeader({ title: '卷宗详情', showBack: true,
              onBack: () => this.getUIContext().getRouter().back(), topInset: true })
            Column() {
              Text('卷宗不存在')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(18)
                .fontColor(Theme.ON_SURFACE_VARIANT)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
          .width('100%')
          .height('100%')
        } else {
          Scroll() {
            Column() {
              // 统一头部标题栏（自顶避让状态栏，背景延伸至屏幕顶部）
              PageHeader({ title: this.work!.title, showBack: true,
                onBack: () => this.getUIContext().getRouter().back(), topInset: true })
              PaperFrame({ image: this.work!.previewImage, fileNo: this.work!.id })
                .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
                .margin({ bottom: 32 })
              MetadataBar({ columns: this.metadataItems() })
                .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 24 })
              NotesCard({ content: this.notesText() })
                .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, bottom: 32 })
              this.actionArea()
            }
            .width('100%')
            .padding({ bottom: 32 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
