// 首页组件（由 ljh 分支 pages/HomePage.ets 迁入 components/home/，去掉 @Entry 作为「首页」Tab 内容）。
// 布局：Stack 层叠 —— PaperBackground（背景层，宣纸灰网格 + 顶部朱砂柔光）在底，Scroll（内容层）在上。
// 内容层按顺序堆叠 7 个子组件：
//   Header → HeroCard → CtaBlock → QuickToolsSection → RecentWorkSection → ProcessSection → Footer
//
// 顶部避让（与 LXT 统一，替代 ljh 的 topAvoidHeight）：
//   EntryAbility 全屏后把状态栏高度（px）写入 AppStorage.statusBarHeight，
//   这里用 @StorageProp 监听并在内容列顶部 pad，使文字不被状态栏遮挡，
//   背景仍由 PaperBackground 的 Canvas 延展到屏幕顶端。

import { PaperBackground } from '../common/PaperBackground';
import { Header } from './Header';
import { HeroCard } from './HeroCard';
import { CtaBlock } from './CtaBlock';
import { QuickToolsSection } from './QuickToolsSection';
import { RecentWorkSection } from './RecentWorkSection';
import { ProcessSection } from './ProcessSection';
import { Footer } from './Footer';
import { FeatureItem, WorkItem, ToolItem } from './HomeModels';

@Component
export struct HomePage {
  // 状态栏避让高度（px，全屏后由 EntryAbility 写入；布局前转 vp）
  @StorageProp('statusBarHeight')
  statusBarHeightPx: number = 0;

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
    new ToolItem($r('app.string.home_tool1'),
      'M9 10 A3 3 0 1 0 9.01 10 M19 10 A3 3 0 1 0 19.01 10 M11 12 L22 22 M17 12 L6 22'),
    new ToolItem($r('app.string.home_tool2'),
      'M14 3 L16 11 L24 14 L16 17 L14 25 L12 17 L4 14 L12 11 Z M21 4 L22 7 L24 8 L22 9 L21 12 L20 9 L18 8 L20 7 Z',
      true),
    new ToolItem($r('app.string.home_tool3'),
      'M8 5 L18 5 L24 11 L14 21 L4 21 L4 11 Z M4 21 L24 11'),
    new ToolItem($r('app.string.home_tool4'),
      'M9 9 A4 4 0 1 0 9.01 9 M19 9 A4 4 0 1 0 19.01 9 M14 19 A4 4 0 1 0 14.01 19'),
    new ToolItem($r('app.string.home_tool5'),
      'M14 3 L25 9 L14 15 L3 9 Z M3 14 L14 20 L25 14 M3 19 L14 25 L25 19'),
    new ToolItem($r('app.string.home_tool6'),
      'M7 16 L21 16 L21 22 L7 22 Z M9 16 L9 8 L19 8 L19 16'),
    new ToolItem($r('app.string.home_tool7'),
      'M4 5 L24 5 L16 14 L16 24 L12 22 L12 14 Z'),
    new ToolItem($r('app.string.home_tool8'),
      'M4 4 L12 4 L12 12 L4 12 Z M16 4 L24 4 L24 12 L16 12 Z M4 16 L12 16 L12 24 L4 24 Z M16 16 L24 16 L24 24 L16 24 Z'),
  ];

  build() {
    Stack() {
      // 底层：宣纸背景（网格 + 朱砂柔光，Canvas 已扩展进安全区）
      PaperBackground()

      // 上层：可滚动内容区（顶部按状态栏高度避让）
      Scroll() {
        Column() {
          // ① 页头：品牌名 + 卷宗编号
          Header()

          // ② 主视觉卡：点击可从相册选图
          HeroCard()

          // ③ 辅助说明：隐私文案
          CtaBlock()

          // ④ 快捷功能区：2×4 功能网格
          QuickToolsSection({ tools: this.tools })

          // ⑤ 近作横滑区
          RecentWorkSection({ works: this.works })

          // ⑥ 技艺列表区
          ProcessSection({ features: this.features })

          // ⑦ 页脚
          Footer()
        }
        .width('100%')
        .padding({ top: px2vp(this.statusBarHeightPx) })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}