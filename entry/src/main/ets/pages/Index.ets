import { HomePage } from '../components/home/HomePage';
import { WorksPage } from './WorksPage';
import { Theme } from '../components/common/Theme';

/**
 * 主框架容器（MainTabs，首页 / 作品 / 我的）。
 *
 * 三个一级页面用底部 Tab 切换，启动默认进入首页（PRD F9）；
 * 「首页」复用组件 components/home/HomePage（ljh 迁入）；
 * 「作品」复用独立组件 WorksPage（其自身带宣纸背景与落款条）；
 * 「我的」在第二阶段接入 components/mine/MinePage，当前为占位。
 * 编辑页（EditPage）为独立路由，不在此导航。
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  /** 系统导航条高度（px，EntryAbility 全屏后写入；tab 栏底部按此避让） */
  @StorageProp('navBarHeight')
  navBarHeightPx: number = 0;

  @Builder
  tabBarItem(index: number, label: string) {
    Column() {
      Text(label)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(15)
        .letterSpacing(1)
        .fontColor(this.currentIndex === index ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: px2vp(this.navBarHeightPx) })
  }

  /** 我的占位（Phase 2 以 components/mine/MinePage 替换） */
  @Builder
  minePlaceholder() {
    Column() {
      Text('我的')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.ON_SURFACE)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Theme.PAPER_BASE)
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBarItem(0, '首页'))

      TabContent() {
        WorksPage()
      }
      .tabBar(this.tabBarItem(1, '作品'))

      TabContent() {
        this.minePlaceholder()
      }
      .tabBar(this.tabBarItem(2, '我的'))
    }
    .width('100%')
    .height('100%')
    // tab 栏高度 = 常规 56 + 底部导航条避让，使按钮文字始终位于系统手势条之上
    .barHeight(56 + px2vp(this.navBarHeightPx))
    .backgroundColor(Theme.PAPER_SURFACE)
    .divider({
      strokeWidth: 1,
      color: Theme.OUTLINE_VARIANT,
      startMargin: 0,
      endMargin: 0
    })
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}