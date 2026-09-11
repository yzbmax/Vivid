import { curves } from '@kit.ArkUI';
import { Theme } from '../common/Theme';

/**
 * 卷宗封缄阶段
 */
export type ArchiveStage = 'render' | 'border' | 'export' | 'sealed';

/**
 * 「文书封缄 · 朱砂落印」仪式感弹窗组件
 *
 * 依据：
 *  - docs/stitch_/stitch_/_4/code.html（Archive 呈报已复核与朱砂御批印）
 *  - docs/stitch_/stitch_/mask_seal/DESIGN.md（Mask & Seal 炎国卷轴设计规范）
 *
 * 特性：
 *  1. 宣纸毛玻璃遮罩：阻断误触，优雅虚化后台编辑画布；
 *  2. 宣纸小令卡片：四角回纹折角饰边，双层朱砂内衬红线；
 *  3. 双态朱砂方印：处理中轻柔呼吸，完成瞬间触发 stamp-in 物理弹性盖印；
 *  4. 阶段古风文案：点染赋彩 -> 款识装裱 -> 落印相册 -> 已封缄。
 */
@Component
export struct SealArchiveDialog {
  /** 是否显示弹窗 */
  @Prop visible: boolean = false;
  /** 当前封缄阶段 */
  @Prop @Watch('onStageChange') stage: ArchiveStage = 'render';
  /** 卷宗落款编号（如 0409） */
  @Prop archiveNo: string = '0409';

  // 内部动画状态
  @State private sealScale: number = 1.0;
  @State private sealRotate: number = 0;
  @State private sealOpacity: number = 1.0;

  aboutToAppear(): void {
    this.startBreathAnimation();
  }

  private onStageChange(): void {
    if (this.stage === 'sealed') {
      // 触发 stamp-in 盖印动效：从 1.45x、5° 倾斜凌空落印至 1.0x、0°
      this.sealScale = 1.45;
      this.sealRotate = 5;
      this.sealOpacity = 0.5;

      this.getUIContext().animateTo({
        duration: 550,
        curve: curves.cubicBezierCurve(0.175, 0.885, 0.32, 1.275)
      }, () => {
        this.sealScale = 1.0;
        this.sealRotate = 0;
        this.sealOpacity = 1.0;
      });
    } else {
      this.startBreathAnimation();
    }
  }

  private startBreathAnimation(): void {
    this.getUIContext().animateTo({
      duration: 850,
      iterations: -1,
      playMode: PlayMode.Alternate,
      curve: Curve.EaseInOut
    }, () => {
      this.sealScale = 1.04;
    });
  }

  private getMainTitle(): string {
    if (this.stage === 'sealed') {
      return '呈报已复核 · 卷宗已归档';
    }
    return '精工装裱 · 卷宗封缄';
  }

  private getSubTitle(): string {
    switch (this.stage) {
      case 'render':
        return '正在点染全画幅色彩…';
      case 'border':
        return '正在款识装裱与题签…';
      case 'export':
        return '正在落印相册入册…';
      case 'sealed':
        return '朱砂定印 · 长卷入册';
      default:
        return '正在封缄卷宗…';
    }
  }

  private getDetailNote(): string {
    switch (this.stage) {
      case 'render':
        return 'C++ 3D LUT · 全画幅调色矩阵运算';
      case 'border':
        return 'EXIF 智能批注 · 相机装裱绘制';
      case 'export':
        return '高保真压缩编码 · 安全写入相册';
      case 'sealed':
        return '已成功保存在系统相册与本地案卷';
      default:
        return '';
    }
  }

  build() {
    if (this.visible) {
      Stack() {
        // 1. 宣纸毛玻璃遮罩层（拦截触摸，防止后台误触）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(222, 221, 215, 0.84)')
          .backdropBlur(18)
          .onClick(() => {
            // 阻断点击
          })

        // 2. 中央宣纸小令卡片
        Stack() {
          // 卡片主体
          Column() {
            // 2.1 核心朱砂方印（Seal Badge）
            Stack() {
              if (this.stage === 'sealed') {
                // 已落印态：实心朱砂红印章，白墨竖排篆书
                Column() {
                  Text('已')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.SURFACE)
                    .lineHeight(16)
                  Text('封')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.SURFACE)
                    .lineHeight(16)
                  Text('缄')
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.SURFACE)
                    .lineHeight(16)
                }
                .width(62)
                .height(62)
                .backgroundColor(Theme.SEAL_RED)
                .border({ width: 2, color: Theme.PRIMARY })
                .borderRadius(2)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .shadow({
                  radius: 8,
                  color: 'rgba(178, 59, 47, 0.35)',
                  offsetY: 3
                })
              } else {
                // 处理中态：朱砂红细线镂空方框，内部带温润呼吸转圈
                Stack() {
                  Column()
                    .width(58)
                    .height(58)
                    .backgroundColor('rgba(178, 59, 47, 0.06)')
                    .border({ width: 1.5, color: Theme.SEAL_RED })
                    .borderRadius(2)

                  LoadingProgress()
                    .width(26)
                    .height(26)
                    .color(Theme.SEAL_RED)
                }
                .width(62)
                .height(62)
                .alignContent(Alignment.Center)
              }
            }
            .scale({ x: this.sealScale, y: this.sealScale })
            .rotate({ angle: this.sealRotate })
            .opacity(this.sealOpacity)
            .margin({ top: 4, bottom: 16 })

            // 2.2 古风衬线主标题
            Text(this.getMainTitle())
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ON_SURFACE)
              .letterSpacing(1.5)
              .margin({ bottom: 8 })

            // 2.3 动态阶段副标题
            Text(this.getSubTitle())
              .fontFamily(Theme.FONT_SANS)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.PRIMARY)
              .letterSpacing(0.8)
              .margin({ bottom: 4 })

            // 2.4 技术说明小字
            Text(this.getDetailNote())
              .fontFamily(Theme.FONT_SANS)
              .fontSize(10)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .opacity(0.7)
              .margin({ bottom: 16 })

            // 2.5 底部古风卷宗落款条
            Row({ space: 6 }) {
              Text(`卷宗第${this.archiveNo}号`)
                .fontFamily(Theme.FONT_MONO)
                .fontSize(9)
                .fontColor(Theme.PRIMARY)
                .letterSpacing(1.2)

              Text('·')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(9)
                .fontColor(Theme.PRIMARY)

              Text('精工留存')
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(9)
                .fontColor(Theme.PRIMARY)
            }
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .backgroundColor(Theme.PRIMARY_05)
            .border({ width: 1, color: Theme.PRIMARY_20 })
            .borderRadius(Theme.RADIUS_DEFAULT)
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 22, bottom: 18 })
          .backgroundColor(Theme.SURFACE)
          .border({ width: 1, color: Theme.PRIMARY_20 })
          .borderRadius(Theme.RADIUS_DEFAULT)
          .shadow({
            radius: 20,
            color: 'rgba(58, 45, 44, 0.12)',
            offsetY: 8
          })

          // 2.6 四角古典折角花纹装饰（Corner Brackets）
          // 左上折角
          Row()
            .width(10)
            .height(10)
            .borderWidth({ top: 1.5, left: 1.5 })
            .borderColor({ top: Theme.PRIMARY, left: Theme.PRIMARY })
            .position({ x: 5, y: 5 })

          // 右上折角
          Row()
            .width(10)
            .height(10)
            .borderWidth({ top: 1.5, right: 1.5 })
            .borderColor({ top: Theme.PRIMARY, right: Theme.PRIMARY })
            .position({ x: 255, y: 5 })

          // 左下折角
          Row()
            .width(10)
            .height(10)
            .borderWidth({ bottom: 1.5, left: 1.5 })
            .borderColor({ bottom: Theme.PRIMARY, left: Theme.PRIMARY })
            .position({ x: 5, y: 223 })

          // 右下折角
          Row()
            .width(10)
            .height(10)
            .borderWidth({ bottom: 1.5, right: 1.5 })
            .borderColor({ bottom: Theme.PRIMARY, right: Theme.PRIMARY })
            .position({ x: 255, y: 223 })
        }
        .width(270)
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
    }
  }
}
