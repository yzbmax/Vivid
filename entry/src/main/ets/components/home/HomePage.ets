import { PaperBackground } from '../common/PaperBackground';
import { common } from '@kit.AbilityKit';
import { Theme } from '../common/Theme';
import { HeroCard } from './HeroCard';
import { CtaBlock } from './CtaBlock';
import { QuickToolsSection } from './QuickToolsSection';
import { RecentWorkSection } from './RecentWorkSection';
import { MetricsSection } from './MetricsSection';
import { ProcessSection } from './ProcessSection';
import { Footer } from './Footer';
import { FeatureItem, ToolItem } from './HomeModels';
import { WorkRecord, WorkStatus } from '../../models/WorkRecord';
import { mockWorkStore } from '../../models/MockWorkStore';
import { WorkUiState } from '../../models/WorkUiState';
import { EditEntrySource, EditorToolKey } from '../../models/EditModels';
import { PhotoPickerService, PhotoPickResult } from '../../services/PhotoPickerService';
import { draftStore, DraftRecord } from '../../models/DraftStore';
import { resolveWorkImageSource } from '../../utils/WorkImageUtils';

/**
 * 首页组件（HomePage）——「主阁 · 卷宗枢纽」
 *
 * 依据：Mask & Seal 官方设计规范（Canvas Hub 样板 _6）
 * - 顶栏：主阁（CANVAS HUB · 卷宗呈报）+ 朱砂金石印章案头直达
 * - 主视觉：呈交新卷宗（双层宣纸装裱 + 细红包边）
 * - 格物八法：浅纸白微浮雕底座 + 衬线金石题记
 * - 案头近辑：3:4 画廊装裱展卷卡 + 全部卷宗一键切换
 * - 卷宗台账：双栏累计封缄与存案总览指标
 * - 款识三序：立意、题签、落印三道工坊仪轨
 * - 文书落款：[ 炎国跨署呈报复核 · 卷宗第肆零玖号 ]
 */
@Component
export struct HomePage {
  @State features: FeatureItem[] = [
    new FeatureItem(
      $r('app.string.home_f1_title'),
      $r('app.string.home_f1_desc'),
      'M14 2 A12 12 0 1 0 14.01 2 M14 6 A8 8 0 1 0 14.01 6 M14 9 A5 5 0 1 0 14.01 9'
    ),
    new FeatureItem(
      $r('app.string.home_f2_title'),
      $r('app.string.home_f2_desc'),
      'M3 21 C8 21 12 17 12 12 C12 7 8 3 3 3 M3 12 L21 12'
    ),
    new FeatureItem(
      $r('app.string.home_f3_title'),
      $r('app.string.home_f3_desc'),
      'M14 2 L23 6 L23 13 C23 19 19 24 14 27 C9 24 5 19 5 13 L5 6 Z M9 14 L13 18 L20 11'
    ),
  ];

  @State allWorks: WorkRecord[] = [];
  @State works: WorkRecord[] = [];
  @State currentDraft: DraftRecord | null = null;
  private unsubWorkUi: (() => void) | null = null;
  private isPickingImage: boolean = false;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    mockWorkStore.init(context);
    this.refreshWorks();
    this.refreshDraft();
    this.unsubWorkUi = WorkUiState.onChange(() => {
      this.refreshWorks();
      this.refreshDraft();
    });
  }

  aboutToDisappear(): void {
    if (this.unsubWorkUi !== null) {
      this.unsubWorkUi();
      this.unsubWorkUi = null;
    }
  }

  private refreshWorks(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    mockWorkStore.init(context);
    this.allWorks = mockWorkStore.list();
    this.works = this.allWorks.slice(0, 5);
  }

  private async refreshDraft(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await draftStore.init(context);
    this.currentDraft = draftStore.get();
  }

  private async resumeDraft(): Promise<void> {
    if (!this.currentDraft) {
      return;
    }
    try {
      await this.getUIContext().getRouter().pushUrl({
        url: 'pages/EditPage',
        params: {
          source: EditEntrySource.Draft,
          workId: this.currentDraft.workId,
          imageUri: this.currentDraft.imageUri,
          initialTool: this.currentDraft.activeTool ?? 'adjust'
        }
      });
    } catch (_err) {
      this.showToast('无法恢复编辑页，请重试');
    }
  }

  private discardDraft(): void {
    this.getUIContext().showAlertDialog({
      title: '舍弃当前草稿？',
      message: '确定清除本次暂存的编辑草稿？清除后将无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认舍弃',
        action: () => {
          draftStore.clear();
          this.currentDraft = null;
          WorkUiState.bumpRevision();
        }
      }
    });
  }

  private formatDraftSubtitle(draft: DraftRecord): string {
    const d = new Date(draft.savedAt);
    const h = String(d.getHours()).padStart(2, '0');
    const m = String(d.getMinutes()).padStart(2, '0');
    const tools: string[] = [];
    if (draft.adjustments && (draft.adjustments.exposure !== 0 || draft.adjustments.brightness !== 0 ||
      draft.adjustments.contrast !== 0 || draft.adjustments.saturation !== 0 || draft.adjustments.temperature !== 0)) {
      tools.push('调色');
    }
    if (draft.editorSnapshot?.filter?.filterId && draft.editorSnapshot.filter.filterId !== 'original') {
      tools.push('滤镜');
    }
    if (draft.editorSnapshot?.textLayers && draft.editorSnapshot.textLayers.length > 0) {
      tools.push('文字');
    }
    if (draft.editorSnapshot?.stickers && draft.editorSnapshot.stickers.length > 0) {
      tools.push('贴纸');
    }
    if (draft.editorSnapshot?.border && draft.editorSnapshot.border.templateId !== 'none') {
      tools.push('装裱');
    }
    const toolStr = tools.length > 0 ? tools.join('·') : '调色';
    return `${h}:${m} 暂存 · ${toolStr}`;
  }

  private sealedCount(): number {
    return this.allWorks.filter((w: WorkRecord) => w.status === WorkStatus.Sealed).length;
  }

  private totalCount(): number {
    return this.allWorks.length;
  }

  // 快捷功能数据：8 个工具入口，2×4 网格布局
  @State tools: ToolItem[] = [
    new ToolItem('subject', $r('app.string.home_tool1'), $r('app.media.home_ai_smart_Cutout')),
    new ToolItem('filter', $r('app.string.home_tool2'), $r('app.media.home_filter_spark')),
    new ToolItem('background', $r('app.string.home_tool3'), $r('app.media.home_background')),
    new ToolItem('adjust', $r('app.string.home_tool4'), $r('app.media.home_adjust')),
    new ToolItem('subject', $r('app.string.home_tool5'), $r('app.media.home_object_scan')),
    new ToolItem('sticker', $r('app.string.home_tool6'), $r('app.media.home_Sticker')),
    new ToolItem('text', $r('app.string.home_tool7'), $r('app.media.home_font')),
    new ToolItem('border', $r('app.string.home_tool8'), $r('app.media.home_Template')),
  ];

  private async startImport(initialTool: EditorToolKey): Promise<void> {
    if (this.isPickingImage) {
      return;
    }
    this.isPickingImage = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const result: PhotoPickResult = await PhotoPickerService.pickSingleImage(context);
      if (result.status === 'cancelled') {
        return;
      }
      if (result.status === 'failed') {
        this.showToast($r('app.string.home_cta_failed'));
        return;
      }

      await this.openEditor(result.sourcePath, result.imageUri, initialTool);
    } finally {
      this.isPickingImage = false;
    }
  }

  private async openEditor(
    imageUri: string,
    displayUri: string,
    initialTool: EditorToolKey
  ): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({
        url: 'pages/EditPage',
        params: {
          source: EditEntrySource.Picker,
          imageUri: imageUri,
          displayUri: displayUri,
          initialTool: initialTool
        }
      });
    } catch (_err) {
      this.showToast('无法进入编辑页，请重试');
    }
  }

  private showToast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message, duration: 3000 });
    } catch (_err) {
    }
  }

  @Builder
  HomeHeader() {
    Column() {
      Row() {
        // 左侧占位（等宽保证标题绝对居中）
        Blank()
          .width(36)

        // 居中品牌标题：主阁 + CANVAS HUB
        Column({ space: 1 }) {
          Text('主  阁')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ON_SURFACE)
            .letterSpacing(3)

          Text('CANVAS HUB · 卷宗呈报')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(9)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.PRIMARY)
            .letterSpacing(1.5)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 右侧朱砂金石印章个人中心按钮
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.icon_person'))
            .width(17)
            .height(17)
            .fillColor(Theme.ON_PRIMARY)
        }
        .width(32)
        .height(32)
        .borderRadius(Theme.RADIUS_FULL)
        .backgroundColor(Theme.PRIMARY)
        .shadow({ radius: 4, color: 'rgba(123, 23, 27, 0.25)', offsetY: 1 })
        .onClick(() => {
          AppStorage.setOrCreate('mainTabIndex', 2);
        })
      }
      .width('100%')
      .height(Theme.HEADER_HEIGHT + 6)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ top: AppStorage.get<number>('statusBarHeight') ?? 0 })
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: Theme.OUTLINE_VARIANT })
  }

  // 断点续辑横幅卡片
  @Builder
  DraftResumeBanner() {
    if (this.currentDraft !== null && this.currentDraft.imageUri.length > 0) {
      Row() {
        // 预览缩略图（44×44，宣纸细边框）
        Stack() {
          Image(resolveWorkImageSource(
            this.currentDraft.previewUri,
            this.currentDraft.imageUri
          ))
            .width(44)
            .height(44)
            .objectFit(ImageFit.Cover)
            .borderRadius(4)
        }
        .width(44)
        .height(44)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .border({ width: 1, color: Theme.OUTLINE_VARIANT })
        .clip(true)
        .flexShrink(0)

        // 卷宗信息（居中自适应，防碰撞截断）
        Column({ space: 3 }) {
          Row() {
            // 草稿微角标
            Text('草稿')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(9)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.PRIMARY)
              .backgroundColor('rgba(123, 23, 27, 0.08)')
              .border({ width: 1, color: 'rgba(123, 23, 27, 0.22)' })
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(2)
              .flexShrink(0)

            // 精炼标题，避免与右侧按钮防撞重叠
            Text('未完草稿')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ON_SURFACE)
              .margin({ left: 6 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.formatDraftSubtitle(this.currentDraft))
            .width('100%')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .letterSpacing(0.5)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10, right: 8 })
        .clip(true)

        // 操作区：继续编辑 + 舍弃（固定尺寸不挤压）
        Row({ space: 6 }) {
          Button('继续编辑')
            .fontSize(11)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ON_PRIMARY)
            .backgroundColor(Theme.PRIMARY)
            .height(28)
            .padding({ left: 8, right: 8 })
            .borderRadius(Theme.RADIUS_DEFAULT)
            .onClick(() => {
              this.resumeDraft();
            })

          Text('舍弃')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(11)
            .fontColor(Theme.ON_SURFACE_VARIANT)
            .padding({ left: 4, right: 4, top: 4, bottom: 4 })
            .onClick(() => {
              this.discardDraft();
            })
        }
        .flexShrink(0)
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 12, bottom: 8 })
      .backgroundColor(Theme.PAPER_SURFACE)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .shadow({ radius: 4, color: Theme.SHADOW_SM, offsetY: 1 })
      .animation({ duration: 250, curve: Curve.EaseOut })
    }
  }

  build() {
    Stack() {
      // 底层：宣纸背景（网格 + 朱砂柔光，Canvas 已扩展进安全区）
      PaperBackground()

      // 上层：主阁头部 + 可滚动内容区
      Column() {
        this.HomeHeader()

        Scroll() {
          Column() {
            // ⓪ 断点续辑：未结卷宗浮条
            this.DraftResumeBanner()

            // ① 主视觉卡：呈交新卷宗
            HeroCard({ onImportClick: () => this.startImport('adjust') })

            // ② 辅助说明：机内安全运算微注
            CtaBlock()

            // ③ 快捷功能区：格物八法
            QuickToolsSection({
              tools: this.tools,
              onToolClick: (key: EditorToolKey) => this.startImport(key)
            })

            // ④ 近作展卷区：案头近辑（支持点击全部卷宗直达 WorksPage）
            RecentWorkSection({
              works: this.works,
              onCardClick: (id: string) => {
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/EditPage',
                  params: { source: 'work', workId: id }
                }).catch(() => {});
              },
              onViewAllClick: () => {
                AppStorage.setOrCreate('mainTabIndex', 1);
              }
            })

            // ⑤ 卷宗台账指标卡：累计封缄 + 存案总览
            MetricsSection({
              sealedCount: this.sealedCount(),
              totalCount: this.totalCount()
            })

            // ⑥ 款识三序区
            ProcessSection({ features: this.features })

            // ⑦ 专属文书落款页脚
            Footer()
          }
          .width('100%')
          .padding({ top: 14 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
