import { MASK_SEAL } from '../MaskSeal';
import { Theme } from './Theme';

interface InfoItem {
  name: string;
  scene: string;
  purpose: string;
  storage: string;
  frequency: string;
}

interface SdkShareItem {
  sdkName: string;
  entity: string;
  dataShared: string;
  purpose: string;
  shareMode: string;
}

/**
 * 个人信息保护“双清单”弹窗（符合工信部 292 号文及应用市场审核规范）
 * - 已收集个人信息清单
 * - 与第三方共享个人信息清单
 */
@Component
export struct DoubleListDialog {
  @Prop isVisible: boolean = false;
  onClose: () => void = () => {};

  @State activeTab: number = 0; // 0: 已收集清单, 1: 第三方共享清单

  private collectedItems: InfoItem[] = [
    {
      name: '本地照片素材（副本与像素数据）',
      scene: '用户在首页或编辑页主动从系统相册选取单张照片时',
      purpose: '在设备本地沙箱中进行滤镜调色、长卷装裱与钤印合成',
      storage: '本机私有沙箱（filesDir），完全不上云，作品删除即彻底销毁',
      frequency: '用户主动挑选单张照片时按需载入'
    },
    {
      name: '导出偏好与画质设置',
      scene: '用户在「应用设置」中配置或导出时弹窗确认规格时',
      purpose: '记录预设导出画质（原画/2K/1080P）与格式（JPEG/PNG/WebP等）',
      storage: '设备本机首选项（Preferences），卸载时由系统自动清除',
      frequency: '用户修改设置或导出照片时记录'
    },
    {
      name: '卷宗案卷草稿与历史元数据',
      scene: '用户在编辑过程中自动暂存草稿或主动落印保存作品时',
      purpose: '保存调色参数快照、印章坐标与装裱题跋文字，支持二次启封续编',
      storage: '本机私有沙箱（filesDir），在「作品」列表长按可彻底销毁',
      frequency: '用户编辑暂存或保存作品时记录'
    }
  ];

  private sdkItems: SdkShareItem[] = [
    {
      sdkName: '未接入任何第三方数据收集 SDK',
      entity: '无第三方机构或商业合作方',
      dataShared: '无任何个人信息或设备标识共享',
      purpose: '微霏为 100% 纯端侧离线美化工具，杜绝商业广告、统计分析与跨平台追踪',
      shareMode: '零网络外发 · 零云端同步 · 零第三方共享'
    }
  ];

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(36, 25, 24, 0.65)')
        .onClick(() => {
          this.onClose();
        });

      // 弹窗主卡片
      Column({ space: 14 }) {
        // 顶部标题
        Row({ space: 8 }) {
          Text('录')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(MASK_SEAL.sealRed)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .border({ width: 1, color: MASK_SEAL.sealRed })
            .borderRadius(2);

          Text('个人信息保护双清单')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(MASK_SEAL.ink);

          Blank();

          Text('✕')
            .fontSize(16)
            .fontColor(MASK_SEAL.inkMuted)
            .padding(6)
            .onClick(() => {
              this.onClose();
            });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        // 双清单切换 Tab
        Row() {
          Button('已收集清单')
            .layoutWeight(1)
            .height(34)
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeTab === 0 ? Color.White : MASK_SEAL.inkMuted)
            .backgroundColor(this.activeTab === 0 ? MASK_SEAL.primary : '#ebe2dc')
            .borderRadius({ topLeft: 4, bottomLeft: 4 })
            .onClick(() => {
              this.activeTab = 0;
            });

          Button('第三方共享清单')
            .layoutWeight(1)
            .height(34)
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.activeTab === 1 ? Color.White : MASK_SEAL.inkMuted)
            .backgroundColor(this.activeTab === 1 ? MASK_SEAL.primary : '#ebe2dc')
            .borderRadius({ topRight: 4, bottomRight: 4 })
            .onClick(() => {
              this.activeTab = 1;
            });
        }
        .width('100%');

        // 清单内容滚动区
        Scroll() {
          Column({ space: 10 }) {
            if (this.activeTab === 0) {
              ForEach(this.collectedItems, (item: InfoItem) => {
                Column({ space: 5 }) {
                  Text(item.name)
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.ink);

                  Text(`• 使用目的：${item.purpose}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 触发场景：${item.scene}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 存储位置：${item.storage}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 频次：${item.frequency}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding(10)
                .backgroundColor('#f8f5f2')
                .border({ width: 1, color: '#e5dbd7' })
                .borderRadius(4);
              })
            } else {
              ForEach(this.sdkItems, (item: SdkShareItem) => {
                Column({ space: 5 }) {
                  Text(item.sdkName)
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.primary);

                  Text(`• 合作主体：${item.entity}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 共享字段：${item.dataShared}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 使用说明：${item.purpose}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);

                  Text(`• 传输机制：${item.shareMode}`)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(11)
                    .fontColor(MASK_SEAL.inkMuted)
                    .lineHeight(16);
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding(10)
                .backgroundColor('#f8f5f2')
                .border({ width: 1, color: '#e5dbd7' })
                .borderRadius(4);
              })
            }
          }
          .width('100%');
        }
        .constraintSize({ maxHeight: 320 })
        .scrollBar(BarState.Off);

        // 底部关闭按钮
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
            this.onClose();
          });
      }
      .width('88%')
      .constraintSize({ maxWidth: 360 })
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
}
