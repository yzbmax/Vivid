import { WorksPage } from './WorksPage';
import { Theme } from '../components/common/Theme';

/**
 * 主框架容器（MainTabs，首页 / 作品 / 我的）。
 *
 * 三个一级页面用底部 Tab 切换，启动默认进入首页（PRD F9）；
 * 「作品」Tab 复用独立页 WorksPage（其自身带宣纸背景与落款条）；
 * 首页 / 我的暂为占位，ImportCard / SettingsList 后续接入。
 * 编辑页（EditPage）为独立路由，不在此导航。
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  @Builder
  tabBarItem(index: number, label: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? Theme.PRIMARY_CONTAINER : Theme.ON_SURFACE_VARIANT_70)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {


      TabContent() {
        WorksPage()
      }
      .tabBar(this.tabBarItem(1, '作品'))


    }
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
