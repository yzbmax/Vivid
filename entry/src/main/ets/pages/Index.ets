import { HomePage } from '../components/home/HomePage';
import { WorksPage } from './WorksPage';
import { MinePage } from '../components/mine/MinePage';
import { Theme } from '../components/common/Theme';

/**
 * 主框架容器（MainTabs，首页 / 作品 / 我的）。
 *
 * 三个一级页面用底部 Tab 切换，启动默认进入首页（PRD F9）；
 * 「首页」复用组件 components/home/HomePage（ljh 迁入）；
 * 「作品」复用独立组件 WorksPage（其自身带宣纸背景与落款条）；
 * 「我的」复用组件 components/mine/MinePage（CentralOfUser 迁入）。
 * 编辑页（EditPage）为独立路由，不在此导航。
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  /** 系统导航条高度（vp，EntryAbility 换算后写入；tab 栏底部按此避让） */
  @StorageProp('navBarHeight')
  navBarHeightVp: number = 0;

  @Builder
  tabBarItem(index: number, label: string, icon: Resource) {
    Column({ space: 2 }) {
      // 图标槽：预留统一图标位，激活/未激活跟随主题色
      Image(icon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(this.currentIndex === index ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)

      Text(label)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(11)
        .letterSpacing(1)
        .fontColor(this.currentIndex === index ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: this.navBarHeightVp })
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBarItem(0, '首页', $r('app.media.icon_home')))

      TabContent() {
        WorksPage()
      }
      .tabBar(this.tabBarItem(1, '作品', $r('app.media.icon_archive')))

      TabContent() {
        MinePage()
      }
      .tabBar(this.tabBarItem(2, '我的', $r('app.media.icon_person')))
    }
    .width('100%')
    .height('100%')
    // tab 栏高度 = 64 + 底部导航条避让，使按钮文字始终位于系统手势条之上
    .barHeight(64 + this.navBarHeightVp)
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