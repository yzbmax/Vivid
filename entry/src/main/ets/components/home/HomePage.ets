// 首页组件（由 ljh 分支 pages/HomePage.ets 迁入 components/home/，去掉 @Entry 作为「首页」Tab 内容）。
// 布局：Stack 层叠 —— PaperBackground（背景层）在底，统一 PageHeader + Scroll（内容层）在上。
// 内容层按顺序堆叠 6 个子组件：HeroCard → CtaBlock → QuickToolsSection → RecentWorkSection → ProcessSection → Footer
//
// 顶部避让：由 PageHeader（topInset=true）按 statusBarHeight(vp) 避让并让头部背景延伸到屏幕顶部；
//   背景仍由 PaperBackground 的 Canvas 延展到屏幕顶端。

import { PaperBackground } from '../common/PaperBackground';
import { PageHeader } from '../common/PageHeader';
import { HeroCard } from './HeroCard';
import { CtaBlock } from './CtaBlock';
import { QuickToolsSection } from './QuickToolsSection';
import { RecentWorkSection } from './RecentWorkSection';
import { ProcessSection } from './ProcessSection';
import { Footer } from './Footer';
import { FeatureItem, WorkItem, ToolItem } from './HomeModels';

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

  // 近作列表数据：3 条近期作品
  @State works: WorkItem[] = [
    new WorkItem($r('app.string.home_work1_title'), $r('app.string.home_work1_date')),
    new WorkItem($r('app.string.home_work2_title'), $r('app.string.home_work2_date')),
    new WorkItem($r('app.string.home_work3_title'), $r('app.string.home_work3_date')),
  ];

  // 快捷功能数据：8 个工具入口，2×4 网格布局
  @State tools: ToolItem[] = [
    new ToolItem($r('app.string.home_tool1'), $r('app.media.home_ai_smart_Cutout')),
    new ToolItem($r('app.string.home_tool2'), $r('app.media.home_filter_spark')),
    new ToolItem($r('app.string.home_tool3'), $r('app.media.home_background')),
    new ToolItem($r('app.string.home_tool4'), $r('app.media.home_Adjust')),
    new ToolItem($r('app.string.home_tool5'), $r('app.media.home_object_scan')),
    new ToolItem($r('app.string.home_tool6'), $r('app.media.home_Sticker')),
    new ToolItem($r('app.string.home_tool7'), $r('app.media.home_Font')),
    new ToolItem($r('app.string.home_tool8'), $r('app.media.home_Template')),
  ];

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
            HeroCard()

            // ② 辅助说明：隐私文案
            CtaBlock()

            // ③ 快捷功能区：2×4 功能网格
            QuickToolsSection({ tools: this.tools })

            // ④ 近作横滑区
            RecentWorkSection({ works: this.works })

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