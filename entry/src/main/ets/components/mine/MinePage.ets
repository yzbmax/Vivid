import { MASK_SEAL, SealButton, SettingRow } from '../MaskSeal';
import { PageHeader } from '../common/PageHeader';
import { PaperBackground } from '../common/PaperBackground';
import { Theme } from '../common/Theme';
import { DoubleListDialog } from '../common/DoubleListDialog';
import { ArchiveStats, computeArchiveStats } from '../../models/ArchiveStats';
import { workRepository } from '../../models/WorkRepository';
import { WorkUiState } from '../../models/WorkUiState';

/**
 * 「我的」Tab 内容组件（卷宗案牍志与工坊营造）。
 * 
 * 核心升级：
 * 1. 彻底解耦用户登录体系，无网络账号/个人资料依赖；
 * 2. 顶部主视觉为【卷宗案牍志】（端侧创作数据看板）；
 * 3. 实时响应作品变动（WorkUiState 联动）；
 * 4. 契合「炎国卷轴 · 文书钤印」设计风骨。
 */
@Component
export struct MinePage {
  @State stats: ArchiveStats = computeArchiveStats([]);
  @State showStorageDialog: boolean = false;
  @State showDoubleListDialog: boolean = false;
  private unregisterWorkListener: (() => void) | null = null;

  aboutToAppear(): void {
    this.refreshStats();
    this.unregisterWorkListener = WorkUiState.onChange(() => {
      this.refreshStats();
    });
  }

  aboutToDisappear(): void {
    if (this.unregisterWorkListener) {
      this.unregisterWorkListener();
      this.unregisterWorkListener = null;
    }
  }

  private refreshStats(): void {
    try {
      const works = workRepository.list();
      this.stats = computeArchiveStats(works);
    } catch (_e) {
      // 容错降级
      this.stats = computeArchiveStats([]);
    }
  }

  private async openPage(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch (err) {
      console.error(`Failed to navigate to ${url}: ${JSON.stringify(err)}`);
    }
  }

  private goToWorks(): void {
    // 切换至底栏第二个 Tab（作品）
    AppStorage.setOrCreate('mainTabIndex', 1);
  }

  @Builder
  storageDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(36, 25, 24, 0.65)')
        .onClick(() => {
          this.showStorageDialog = false;
        });

      Column({ space: 14 }) {
        Row({ space: 8 }) {
          Text('密')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(MASK_SEAL.sealRed)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .border({ width: 1, color: MASK_SEAL.sealRed })
            .borderRadius(2);

          Text('本地私有沙箱说明')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(MASK_SEAL.ink);
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);

        Column({ space: 8 }) {
          Text('微霏严格遵循华为鸿蒙纯端侧隐私规范：')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontColor(MASK_SEAL.ink);

          Text('• 私有沙箱存储：全部作品元数据、调色参数快照及缓存均保存在本设备沙箱（filesDir / cacheDir）中，绝不上传云端。')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .lineHeight(18)
            .fontColor(MASK_SEAL.inkMuted);

          Text('• 离线端侧运算：图像解码、直方图分析与印章合成均在芯片本地即时完成，断网亦可全功能创作。')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .lineHeight(18)
            .fontColor(MASK_SEAL.inkMuted);

          Text('• 零广告零采集：不收集您的任何个人身份信息或摄影作品素材。')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .lineHeight(18)
            .fontColor(MASK_SEAL.inkMuted);
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#f8f5f2')
        .border({ width: 1, color: '#e5dbd7' })
        .borderRadius(4);

        Button('谨悉')
          .width('100%')
          .height(42)
          .fontFamily(Theme.FONT_SERIF)
          .fontWeight(FontWeight.Bold)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor(MASK_SEAL.primary)
          .borderRadius(4)
          .onClick(() => {
            this.showStorageDialog = false;
          });
      }
      .width('86%')
      .constraintSize({ maxWidth: 340 })
      .padding(20)
      .backgroundColor(MASK_SEAL.paperSurface)
      .border({ width: 1, color: '#ba7770' })
      .borderRadius(6)
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.25)', offsetY: 6 });
    }
    .width('100%')
    .height('100%')
    .zIndex(999);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      PaperBackground();
      Column() {
        PageHeader({ title: '我的', showBack: false, onBack: () => {}, topInset: true });
        Scroll() {
          Column({ space: 20 }) {
            // ① 【卷宗案牍志】核心数据看板卡片
            Column({ space: 0 }) {
              // 卡片顶部标题栏
              Row() {
                Row({ space: 6 }) {
                  Text('案牍')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.sealRed)
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .border({ width: 1, color: MASK_SEAL.sealRed })
                    .borderRadius(2);

                  Text('卷宗案牍志')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.ink);
                }

                Blank();

                Text('共 ' + this.stats.totalCountChinese + ' 卷 · 纯本地')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(11)
                  .fontColor(MASK_SEAL.primary)
                  .letterSpacing(0.5);
              }
              .width('100%')
              .alignItems(VerticalAlign.Center);

              // 细分割线
              Row()
                .width('100%')
                .height(1)
                .backgroundColor('#eadbd7')
                .margin({ top: 10, bottom: 12 });

              // 核心指标与风骨（左右舒展排版，杜绝三栏挤压）
              Row() {
                // 左侧：藏卷总量与状态
                Column({ space: 3 }) {
                  Row({ space: 3 }) {
                    Text(this.stats.totalCount.toString())
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(32)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(MASK_SEAL.primary);
                    Text('卷')
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(13)
                      .fontColor(MASK_SEAL.inkMuted)
                      .padding({ bottom: 4 });
                  }
                  .alignItems(VerticalAlign.Bottom);

                  Text('已封 ' + this.stats.sealedCount.toString() + ' · 草稿 ' + this.stats.draftCount.toString())
                    .fontFamily(Theme.FONT_MONO)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted);
                }
                .alignItems(HorizontalAlign.Start);

                Blank();

                // 右侧：气象与风骨标签签条
                Column({ space: 6 }) {
                  Row({ space: 6 }) {
                    Text('主流气象')
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(11)
                      .fontColor(MASK_SEAL.inkMuted);
                    Text(this.stats.dominantTone)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(MASK_SEAL.ink);
                  }
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor('#f5ede7')
                  .borderRadius(3);

                  Row({ space: 6 }) {
                    Text('设色风骨')
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(11)
                      .fontColor(MASK_SEAL.inkMuted);
                    Text(this.stats.temperatureBias)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(MASK_SEAL.ink);
                  }
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor('#f5ede7')
                  .borderRadius(3);
                }
                .alignItems(HorizontalAlign.End);
              }
              .width('100%')
              .alignItems(VerticalAlign.Center);

              // 底栏：题跋总评注脚（内嵌引号自适应折行，加朱印竖边饰）
              Row() {
                Text('“ ' + this.stats.poeticSummary + ' ”')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.inkMuted)
                  .lineHeight(19)
                  .width('100%');
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor('#f8f4f0')
              .border({ width: { left: 2 }, color: MASK_SEAL.sealRed })
              .margin({ top: 12 });

              // 底部轻量跳转入口
              Row() {
                Blank();
                Row({ space: 3 }) {
                  Text('检视全部案卷')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(12)
                    .fontColor(MASK_SEAL.primary);
                  Text('›')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(14)
                    .fontColor(MASK_SEAL.primary);
                }
                .padding({ left: 10, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#f6eeea')
                .border({ width: 1, color: '#e5d3cf' })
                .borderRadius(3)
                .onClick(() => this.goToWorks());
              }
              .width('100%')
              .margin({ top: 10 });
            }
            .width('100%')
            .padding(16)
            .backgroundColor(MASK_SEAL.paperSurface)
            .border({ width: 1, color: '#d9c4c0' });

            // ② 【工坊营造】（系统导出与存储）
            Column() {
              Text('工坊营造')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .letterSpacing(1.5)
                .width('100%')
                .padding({ bottom: 8 });

              SettingRow({
                title: '应用与导出设置',
                detail: '预设画质、格式与弹窗询问设置',
                interactive: true,
                onTap: () => this.openPage('pages/AppSettingsPage')
              });

              SettingRow({
                title: '本地私有沙箱',
                detail: '端侧存储说明 · 绝不上云',
                interactive: true,
                onTap: () => {
                  this.showStorageDialog = true;
                }
              });
            }

            // ③ 【法度与规约】（服务协议与隐私政策）
            Column() {
              Text('法度与规约')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .letterSpacing(1.5)
                .width('100%')
                .padding({ bottom: 8 });

              SettingRow({
                title: '用户服务协议',
                detail: '微霏服务条款与知识产权声明',
                interactive: true,
                onTap: () => this.openPage('pages/UserAgreementPage')
              });

              SettingRow({
                title: '隐私政策指引',
                detail: '个人信息保护与设备权限说明',
                interactive: true,
                onTap: () => this.openPage('pages/PrivacyPolicyPage')
              });

              SettingRow({
                title: '个人信息双清单',
                detail: '已收集清单 · 第三方共享清单',
                interactive: true,
                onTap: () => {
                  this.showDoubleListDialog = true;
                }
              });

              SettingRow({
                title: '纯端侧运行承诺',
                detail: '零网络上传 · 零广告追踪 · 无第三方商业 SDK',
                interactive: false,
                onTap: () => {}
              });
            }

            // 页脚说明
            Column({ space: 4 }) {
              Text('微霏 V1.0.3 · 东方美学数字画卷工坊')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(11)
                .fontColor(MASK_SEAL.inkMuted)
                .letterSpacing(1);

              Text('纯本地离线创作 · 恪守端侧隐私安全')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(10)
                .fontColor(MASK_SEAL.primary);
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 4, bottom: 28 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 16, bottom: 28 + Math.max(AppStorage.get<number>('navBarHeight') ?? 28, 28) });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true });
      }
      .width('100%')
      .height('100%');

      // 本地沙箱说明弹窗
      if (this.showStorageDialog) {
        this.storageDialog();
      }

      // 个人信息保护双清单弹窗
      if (this.showDoubleListDialog) {
        DoubleListDialog({
          isVisible: this.showDoubleListDialog,
          onClose: () => {
            this.showDoubleListDialog = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%');
  }
}
