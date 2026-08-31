// 首页组件（由 ljh 分支 pages/HomePage.ets 迁入 components/home/，去掉 @Entry 作为「首页」Tab 内容）。
// 布局：Stack 层叠 —— PaperBackground（背景层）在底，统一 PageHeader + Scroll（内容层）在上。
// 内容层按顺序堆叠 6 个子组件：HeroCard → CtaBlock → QuickToolsSection → RecentWorkSection → ProcessSection → Footer
//
// 顶部避让：由 PageHeader（topInset=true）按 statusBarHeight(vp) 避让并让头部背景延伸到屏幕顶部；
//   背景仍由 PaperBackground 的 Canvas 延展到屏幕顶端。

import { PaperBackground } from '../common/PaperBackground';
import { common } from '@kit.AbilityKit';
import { PageHeader } from '../common/PageHeader';
import { HeroCard } from './HeroCard';
import { CtaBlock } from './CtaBlock';
import { QuickToolsSection } from './QuickToolsSection';
import { RecentWorkSection } from './RecentWorkSection';
import { ProcessSection } from './ProcessSection';
import { Footer } from './Footer';
import { FeatureItem, ToolItem } from './HomeModels';
import { WorkRecord } from '../../models/WorkRecord';
import { mockWorkStore } from '../../models/MockWorkStore';
import { WorkUiState } from '../../models/WorkUiState';
import { EditEntrySource, EditorToolKey, PendingEditIntent } from '../../models/EditModels';
import { MockAuthStore } from '../../models/MockAuthStore';
import { PendingEditIntentStore } from '../../models/PendingEditIntentStore';
import { PhotoPickerService, PhotoPickResult } from '../../services/PhotoPickerService';

@Component
export struct HomePage {
  // 技艺列表数据：3 条核心功能特点，每条含矢量图标 SVG 路径
  // SVG 坐标系 28×28（与 Path 组件尺寸一致，无需 viewBox）
  @State features: FeatureItem[] = [
    new FeatureItem(
      $r('app.string.home_f1_title'),
      $r('app.string.home_f1_desc'),
      // 靶心图标：三圈同心圆，中心 (14,14)
      'M14 2 A12 12 0 1 0 14.01 2 M14 6 A8 8 0 1 0 14.01 6 M14 9 A5 5 0 1 0 14.01 9'
    ),
    new FeatureItem(
      $r('app.string.home_f2_title'),
      $r('app.string.home_f2_desc'),
      // 坐标十字图标：十字线 + 中心圆
      'M14 2 L14 26 M2 14 L26 14 M14 9 A5 5 0 1 0 14.01 9'
    ),
    new FeatureItem(
      $r('app.string.home_f3_title'),
      $r('app.string.home_f3_desc'),
      // 盾牌对勾图标：盾牌外轮廓 + 对勾
      'M14 2 L23 6 L23 13 C23 19 19 24 14 27 C9 24 5 19 5 13 L5 6 Z M9 14 L13 18 L20 11'
    ),
  ];

  // 近作列表数据：从 MockWorkStore 获取最近 3 条
  @State works: WorkRecord[] = [];
  private unsubWorkUi: (() => void) | null = null;
  private isPickingImage: boolean = false;

  aboutToAppear(): void {
    mockWorkStore.init();
    this.works = mockWorkStore.list().slice(0, 3);
    this.unsubWorkUi = WorkUiState.onChange(() => {
      this.works = mockWorkStore.list().slice(0, 3);
    });
  }

  aboutToDisappear(): void {
    if (this.unsubWorkUi !== null) {
      this.unsubWorkUi();
      this.unsubWorkUi = null;
    }
  }

  // 快捷功能数据：8 个工具入口，2×4 网格布局
  @State tools: ToolItem[] = [
    new ToolItem('subject', $r('app.string.home_tool1'), $r('app.media.home_ai_smart_Cutout')),
    new ToolItem('filter', $r('app.string.home_tool2'), $r('app.media.home_filter_spark')),
    new ToolItem('background', $r('app.string.home_tool3'), $r('app.media.home_background')),
    new ToolItem('adjust', $r('app.string.home_tool4'), $r('app.media.home_Adjust')),
    new ToolItem('subject', $r('app.string.home_tool5'), $r('app.media.home_object_scan')),
    new ToolItem('sticker', $r('app.string.home_tool6'), $r('app.media.home_Sticker')),
    new ToolItem('text', $r('app.string.home_tool7'), $r('app.media.home_Font')),
    new ToolItem('template', $r('app.string.home_tool8'), $r('app.media.home_Template')),
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

      if (MockAuthStore.getSession().status === 'authenticated') {
        await this.openEditor(result.sourcePath, result.imageUri, initialTool);
        return;
      }

      const intent: PendingEditIntent = {
        imageUri: result.sourcePath,
        displayUri: result.imageUri,
        initialTool: initialTool,
        createdAt: Date.now()
      };
      PendingEditIntentStore.set(intent);
      this.showLoginGate();
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

  private showLoginGate(): void {
    this.getUIContext().showAlertDialog({
      title: '登录后方可呈报卷宗',
      message: '所选照片仅用于本次编辑，登录后将继续进入调色页。',
      primaryButton: {
        value: '前往登录',
        action: () => this.openLogin()
      },
      secondaryButton: {
        value: '暂不登录',
        action: () => PendingEditIntentStore.clear()
      },
      cancel: () => PendingEditIntentStore.clear()
    });
  }

  private async openLogin(): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' });
    } catch (_err) {
      PendingEditIntentStore.clear();
      this.showToast('无法打开登录页，请重试');
    }
  }

  private showToast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message, duration: 3000 });
    } catch (_err) {
    }
  }

  build() {
    Stack() {
      // 底层：宣纸背景（网格 + 朱砂柔光，Canvas 已扩展进安全区）
      PaperBackground()

      // 上层：统一头部 + 可滚动内容区
      Column() {
        // 统一头部标题栏（自顶避让状态栏，背景延伸至屏幕顶部）
        PageHeader({ title: '首页', showBack: false, onBack: () => {}, topInset: true })

        Scroll() {
          Column() {
            // ① 主视觉卡：点击可从相册选图
            HeroCard({ onImportClick: () => this.startImport('adjust') })

            // ② 辅助说明：隐私文案
            CtaBlock()

            // ③ 快捷功能区：2×4 功能网格
            QuickToolsSection({
              tools: this.tools,
              onToolClick: (key: EditorToolKey) => this.startImport(key)
            })

            // ④ 近作横滑区
            RecentWorkSection({
              works: this.works,
              onCardClick: (id: string) => {
                this.getUIContext().getRouter().pushUrl({
                  url: 'pages/EditPage',
                  params: { source: 'work', workId: id }
                }).catch(() => {});
              }
            })

            // ⑤ 技艺列表区
            ProcessSection({ features: this.features })

            // ⑥ 页脚
            Footer()
          }
          .width('100%')
          .padding({ top: 16 })
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
