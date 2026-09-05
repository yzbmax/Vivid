import { HomePage } from '../components/home/HomePage';
import { WorksPage } from './WorksPage';
import { MinePage } from '../components/mine/MinePage';
import { Theme } from '../components/common/Theme';
import { MASK_SEAL } from '../components/MaskSeal';
import { font } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WorkUiState } from '../models/WorkUiState';
import { PreferencesHelper } from '../utils/PreferencesHelper';

/**
 * 主框架容器（MainTabs，首页 / 作品 / 我的）。
 *
 * 三个一级页面用底部 Tab 切换，启动默认进入首页（PRD F9）；
 * 「首页」复用组件 components/home/HomePage（ljh 迁入）；
 * 「作品」复用独立组件 WorksPage（其自身带宣纸背景与落款条）；
 * 「我的」复用组件 components/mine/MinePage（CentralOfUser 迁入）。
 * 编辑页（EditPage）为独立路由，不在此导航。
 *
 * 首次冷启动：自动检测并弹出《微霏服务协议与隐私政策》授权确认弹窗（华为应用市场合规必备）。
 * 字体注册：在 aboutToAppear() 中通过 font.registerFont() + $rawfile 程序化注册。
 */
@Entry
@Component
struct Index {
  @StorageLink('mainTabIndex') currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();
  @State showPrivacyModal: boolean = false;

  /** 系统导航条高度（vp，EntryAbility 换算后写入；tab 栏底部按此避让） */
  @StorageProp('navBarHeight')
  navBarHeightVp: number = 0;

  aboutToAppear(): void {
    // 注册自定义字体（$rawfile 仅在组件上下文中可解析）
    font.registerFont({ familyName: 'Noto Serif', familySrc: $rawfile('fonts/notoserif.ttf') });
    font.registerFont({ familyName: 'Noto Serif SC', familySrc: $rawfile('fonts/notoserifsc.ttf') });
    font.registerFont({ familyName: 'Kai', familySrc: $rawfile('fonts/gkai.ttf') });

    // 首次冷启动隐私合规检测
    this.checkPrivacyStatus();
  }

  private async checkPrivacyStatus(): Promise<void> {
    const agreed = AppStorage.get<boolean>('privacy_agreed');
    if (agreed === true) {
      return;
    }
    try {
      const helper = PreferencesHelper.getStore('vivid_default_pref');
      const val = await helper.getString('privacy_agreed');
      if (val === 'true') {
        AppStorage.setOrCreate('privacy_agreed', true);
      } else {
        this.showPrivacyModal = true;
      }
    } catch (_err) {
      this.showPrivacyModal = true;
    }
  }

  private agreePrivacy(): void {
    this.showPrivacyModal = false;
    AppStorage.setOrCreate('privacy_agreed', true);
    PreferencesHelper.getStore('vivid_default_pref').putString('privacy_agreed', 'true');
  }

  private exitApp(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (ctx && typeof ctx.terminateSelf === 'function') {
        ctx.terminateSelf();
      }
    } catch (_err) {
      this.showPrivacyModal = false;
    }
  }

  onPageShow(): void {
    WorkUiState.bumpRevision();
  }

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

  @Builder
  privacyModal() {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明背景遮罩，拦截下层手势
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(36, 25, 24, 0.70)')
        .backdropBlur(10)
        .onClick(() => {});

      // 居中授权卡片
      Column({ space: 16 }) {
        // 顶部徽记与标题
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text('印')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.sealRed)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .border({ width: 1, color: MASK_SEAL.sealRed })
              .borderRadius(2);
            Text('欢迎使用微霏')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
          }

          Text('服务条款与个人信息保护指引')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(11)
            .fontColor(MASK_SEAL.primary)
            .letterSpacing(1);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        // 摘要内容
        Column({ space: 8 }) {
          Text('在您开启长卷创作前，请审慎阅读并理解相关条款。微霏遵循端侧隐私安全与最小必要原则：')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .lineHeight(20)
            .fontColor(MASK_SEAL.ink);

          Column({ space: 6 }) {
            Text('• 纯本地端侧运算：全部调色滤镜与印章合成均在您本地设备内部完成，绝不向任何云端上传您的图片素材与创作作品。')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .lineHeight(19)
              .fontColor(MASK_SEAL.inkMuted);
            Text('• 免相册全局权限：仅在您主动从相册挑选或导出单张照片时交互，无法亦不会扫描或遍历您的系统相册。')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .lineHeight(19)
              .fontColor(MASK_SEAL.inkMuted);
            Text('• 零广告零追踪：不收集个人敏感数据，无第三方商业广告与跨平台追踪 SDK。')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .lineHeight(19)
              .fontColor(MASK_SEAL.inkMuted);
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#f8f5f2')
          .border({ width: 1, color: '#e5dbd7' })
          .borderRadius(4);

          // 条款直达超链接
          Row() {
            Text('点击阅读完整的 ')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .fontColor(MASK_SEAL.inkMuted);
            Text('《用户服务协议》')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .decoration({ type: TextDecorationType.Underline, color: MASK_SEAL.primary })
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/UserAgreementPage' }).catch(() => {});
              });
            Text(' 与 ')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .fontColor(MASK_SEAL.inkMuted);
            Text('《隐私政策》')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(12)
              .fontColor(MASK_SEAL.primary)
              .decoration({ type: TextDecorationType.Underline, color: MASK_SEAL.primary })
              .onClick(() => {
                this.getUIContext().getRouter().pushUrl({ url: 'pages/PrivacyPolicyPage' }).catch(() => {});
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 4 });
        }
        .width('100%');

        // 操作按钮
        Column({ space: 10 }) {
          Button('同意并开启创作')
            .width('100%')
            .height(46)
            .fontFamily(Theme.FONT_SERIF)
            .fontWeight(FontWeight.Bold)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor(MASK_SEAL.primary)
            .borderRadius(4)
            .onClick(() => {
              this.agreePrivacy();
            });

          Text('不同意并退出')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontColor(MASK_SEAL.inkMuted)
            .padding(6)
            .onClick(() => {
              this.exitApp();
            });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .width('88%')
      .constraintSize({ maxWidth: 360 })
      .padding(22)
      .backgroundColor(MASK_SEAL.paperSurface)
      .border({ width: 1, color: '#ba7770' })
      .borderRadius(8)
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.2)', offsetY: 6 });
    }
    .width('100%')
    .height('100%')
    .zIndex(9999);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
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
      // tab 栏高度 = 84 + 底部导航条避让，使按钮文字始终位于系统手势条之上
      .barHeight(84 + this.navBarHeightVp)
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

      if (this.showPrivacyModal) {
        this.privacyModal();
      }
    }
    .width('100%')
    .height('100%');
  }
}

