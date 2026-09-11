import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { mockWorkStore } from '../models/MockWorkStore';
import { draftStore } from '../models/DraftStore';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate('appContext', this.context);
    // 进程启动或冷启动时立即从沙箱持久化存储载入作品与草稿
    mockWorkStore.init(this.context);
    draftStore.init(this.context);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.getMainWindow((err, win) => {
      if (err.code || !win) {
        hilog.error(DOMAIN, 'testTag', 'Failed to obtain main window: %{public}s', JSON.stringify(err));
        return;
      }
      try {
        const updateAvoidAreas = (): void => {
          try {
            const sysAvoid = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
            const navAvoid = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
            const density: number = display.getDefaultDisplaySync().densityPixels;
            const toVp = (px: number): number => density > 0 ? px / density : 0;
            AppStorage.setOrCreate('statusBarHeight', toVp(sysAvoid.topRect.height));
            const rawNavH = Math.max(toVp(navAvoid.bottomRect.height), toVp(sysAvoid.bottomRect.height));
            // 导航指示条避让硬保底至少 28vp
            const safeNavH = Math.max(rawNavH, 28);
            AppStorage.setOrCreate('navBarHeight', safeNavH);
          } catch (e) {
            AppStorage.setOrCreate('navBarHeight', 28);
          }
        };

        // 沉浸式布局：窗口全屏，页面背景可延伸至状态栏 / 导航栏之外
        win.setWindowLayoutFullScreen(true).then(() => {
          // 全屏生效后读取系统安全区高度（px），换算为 vp 后写入 AppStorage，供页面内容上下避让
          updateAvoidAreas();
          // 监听安全区域动态变化（如折叠屏展开/折叠、横竖屏切换）
          win.on('avoidAreaChange', (_options: window.AvoidAreaOptions): void => {
            updateAvoidAreas();
          });
        }).catch((err: Error) => {
          hilog.error(DOMAIN, 'testTag', 'Failed to set full screen. Cause: %{public}s', JSON.stringify(err));
        });
      } catch (configErr) {
        hilog.error(DOMAIN, 'testTag', 'Failed to configure window. Cause: %{public}s', JSON.stringify(configErr));
      }
    });

    // 主框架 MainTabs（pages/Index）为启动页；WorksPage 作为「作品」Tab 挂载于 Index。
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      try {
        const win = windowStage.getMainWindowSync();
        // 宣纸底色：过渡动画与安全区缺口处与页面 paper-base 一致（设计令牌 paper_base）
        win.setWindowBackgroundColor('#DEDDD7');
      } catch (colorErr) {
        hilog.warn(DOMAIN, 'testTag', 'Failed to set window background color: %{public}s', JSON.stringify(colorErr));
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}