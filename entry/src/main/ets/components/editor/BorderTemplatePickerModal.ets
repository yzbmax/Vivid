import {
  BORDER_TEMPLATES,
  BorderTemplate,
  BorderCategory,
  BorderCategoryInfo,
  BORDER_CATEGORIES,
  isWatermarkTemplate
} from '../../features/editor/border/BorderCatalog';
import { Theme } from '../common/Theme';

/**
 * 规整图片路径以符合 ArkUI 图像加载规范：沙箱裸路径补齐 `file://` 前缀
 */
function normalizeImageSrc(src: string): string | Resource {
  if (!src || src.trim().length === 0) {
    return $r('app.media.work_mountain');
  }
  if (src.startsWith('/') && !src.startsWith('file://')) {
    return `file://${src}`;
  }
  return src;
}

/**
 * 全屏模版列表预览选择器（沉浸式分类模版库）。
 *
 * 功能规范：
 * 1. 顶部沉浸式标题栏：返回按钮与当前分类标题；
 * 2. 分类滑动 Tab：全部、经典水印、品牌大师、旅拍打卡、复古胶片、艺术装裱；
 * 3. 2 列瀑布流网格预览卡片，每张卡片直观渲染模版装裱/水印视觉效果；
 * 4. 选中态高亮（金黄色 2.5vp 描边与中央选中指示器）；
 * 5. 点击即选即用，优雅关闭全屏并刷新画布。
 */
@Component
export struct BorderTemplatePickerModal {
  @Prop currentTemplateId: string = 'none';
  @Prop imageSrc: string = '';
  onSelectTemplate: (templateId: string) => void = () => {};
  onClose: () => void = () => {};

  @State selectedCategory: BorderCategory = 'all';

  private getFilteredTemplates(): BorderTemplate[] {
    if (this.selectedCategory === 'all') {
      return BORDER_TEMPLATES;
    }
    const result: BorderTemplate[] = [];
    for (let i = 0; i < BORDER_TEMPLATES.length; i++) {
      if (BORDER_TEMPLATES[i].category === this.selectedCategory) {
        result.push(BORDER_TEMPLATES[i]);
      }
    }
    return result;
  }

  private getCategoryName(catId: BorderCategory): string {
    for (let i = 0; i < BORDER_CATEGORIES.length; i++) {
      if (BORDER_CATEGORIES[i].id === catId) {
        return BORDER_CATEGORIES[i].name;
      }
    }
    return '全部';
  }

  build() {
    Column() {
      // 1. 顶部状态栏避让、下拉把手与导航栏
      Column() {
        // 下拉指示抓手条
        Row() {
          Column()
            .width(36)
            .height(4)
            .borderRadius(2)
            .backgroundColor(Theme.OUTLINE)
        }
        .width('100%')
        .height(16)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onClose();
        })

        Row() {
          // 返回按钮
          Row({ space: 6 }) {
            Image($r('app.media.icon_back'))
              .width(22)
              .height(22)
              .fillColor(Theme.PRIMARY)
            Text(this.selectedCategory === 'all' ? '装裱全卷 · 边式大库' : this.getCategoryName(this.selectedCategory))
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ON_SURFACE)
          }
          .onClick(() => {
            this.onClose();
          })

          Blank()

          // 模版总数计数
          Row({ space: 4 }) {
            Text('卷宗')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(11)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Text(`${this.getFilteredTemplates().length}`)
              .fontFamily(Theme.FONT_MONO)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
            Text('款')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(11)
              .fontColor(Theme.ON_SURFACE_VARIANT)
          }
        }
        .width('100%')
        .height(Theme.HEADER_HEIGHT)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        // 2. 水平分类切换栏
        Scroll() {
          Row({ space: 8 }) {
            ForEach(BORDER_CATEGORIES, (cat: BorderCategoryInfo) => {
              this.categoryTab(cat.id, cat.name)
            }, (cat: BorderCategoryInfo) => cat.id)
          }
          .padding({ left: 16, right: 16, top: 4, bottom: 10 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .padding({ top: AppStorage.get<number>('statusBarHeight') ?? 0 })
      .backgroundColor(Theme.PAPER_SURFACE_80)
      .border({ width: { bottom: 0.5 }, color: Theme.OUTLINE_VARIANT })

      // 3. 2 列瀑布流网格预览
      Grid() {
        ForEach(this.getFilteredTemplates(), (tpl: BorderTemplate) => {
          GridItem() {
            this.templatePreviewCard(tpl)
          }
        }, (tpl: BorderTemplate) => tpl.templateId)

        // 底栏文书落款 Pill
        GridItem() {
          Row({ space: 4 }) {
            Text('炎国艺术档案复核 · 装裱模板选辑')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(10)
              .fontColor(Theme.PRIMARY_60)
              .letterSpacing(1.2)
          }
          .width('100%')
          .height(28)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(Theme.PRIMARY_05)
          .border({ width: 0.5, color: Theme.PRIMARY_20 })
          .borderRadius(14)
          .margin({ top: 12, bottom: 20 })
        }
        .columnStart(0)
        .columnEnd(1)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(14)
      .padding({ left: 14, right: 14, top: 12, bottom: 40 })
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(Theme.PAPER_BASE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.PAPER_BASE)
  }

  /** 单个分类胶囊 Tab（Mask & Seal Chip） */
  @Builder
  categoryTab(catId: BorderCategory, name: string) {
    Row() {
      Text(name)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(13)
        .fontWeight(this.selectedCategory === catId ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedCategory === catId ? Theme.ON_PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .backgroundColor(this.selectedCategory === catId ? Theme.PRIMARY : Theme.PAPER_SURFACE)
    .border({
      width: 0.8,
      color: this.selectedCategory === catId ? Theme.PRIMARY : Theme.OUTLINE_VARIANT
    })
    .borderRadius(16)
    .shadow(this.selectedCategory === catId ? { radius: 4, color: 'rgba(123,23,27,0.18)', offsetY: 1 } : { radius: 0, color: Color.Transparent })
    .onClick(() => {
      this.selectedCategory = catId;
    })
  }

  /** 单个 2 列瀑布流模版预览卡片（文书装裱纸卡） */
  @Builder
  templatePreviewCard(tpl: BorderTemplate) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        // 卡片画幅装裱模拟区
        this.cardVisualContainer(tpl)

        // 选中高亮状态：右上角古典朱砂方印
        if (this.currentTemplateId === tpl.templateId) {
          Row() {
            Text('印')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ON_PRIMARY)
          }
          .width(22)
          .height(22)
          .borderRadius(3)
          .backgroundColor(Theme.SEAL_RED)
          .border({ width: 1, color: '#FFFFFF' })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .shadow({ radius: 3, color: 'rgba(178,59,47,0.3)', offsetY: 1 })
          .margin({ top: 6, right: 6 })
        }
      }
      .width('100%')
      .height(210)
      .borderRadius(6)
      .clip(true)
      .backgroundColor(Theme.PAPER_SURFACE)
      .border({
        width: this.currentTemplateId === tpl.templateId ? 2 : 0.8,
        color: this.currentTemplateId === tpl.templateId ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT
      })

      // 模版标题与简介
      Row() {
        Column({ space: 2 }) {
          Text(tpl.name)
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(13)
            .fontWeight(this.currentTemplateId === tpl.templateId ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentTemplateId === tpl.templateId ? Theme.PRIMARY : Theme.ON_SURFACE)
            .maxLines(1)
          if (tpl.description) {
            Text(tpl.description)
              .fontFamily(Theme.FONT_SANS)
              .fontSize(10)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .maxLines(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.currentTemplateId === tpl.templateId) {
          Row() {
            Text('已选定')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.SEAL_RED)
          }
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .backgroundColor(Theme.PRIMARY_05)
          .border({ width: 0.5, color: Theme.SEAL_RED })
          .borderRadius(2)
        }
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 6, bottom: 2 })
    }
    .width('100%')
    .padding(4)
    .backgroundColor(Theme.PAPER_SURFACE)
    .borderRadius(8)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 1 })
    .onClick(() => {
      this.onSelectTemplate(tpl.templateId);
    })
  }

  /** 模拟各款模版的装裱形态卡片视觉 */
  @Builder
  cardVisualContainer(tpl: BorderTemplate) {
    if (tpl.templateId === 'none') {
      // 保持原片
      Image(normalizeImageSrc(this.imageSrc))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    } else if (tpl.templateId === 'watermark_travel_stamp') {
      // 齿孔邮票：深灰蓝底卡 + 锯齿打孔边 + 月份 01
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .border({ width: 1, color: '#D5D0C5', style: BorderStyle.Dashed })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 32 })
        .backgroundColor('#FBFBF9')

        // 邮票底栏
        Row() {
          Text('01')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2A2621')
          Column({ space: 1 }) {
            Text('TRAVEL')
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#3D3833')
            Text('POSTAGE LOG')
              .fontSize(7)
              .fontColor('#7C756B')
          }
          .margin({ left: 4 })
          .alignItems(HorizontalAlign.Start)

          Blank()

          Text('AIR MAIL')
            .fontSize(7)
            .fontColor('#6E6559')
            .border({ width: 0.5, color: '#998F82' })
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })
        }
        .width('100%')
        .height(30)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_travel_postcard') {
      // 旅行明信片：天青底卡 + 白色照片勾边 + 手写去有风的地方
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .border({ width: 1.5, color: '#FFFFFF' })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 36 })
        .backgroundColor('#E4ECF0')

        // 明信片底栏
        Row() {
          Column({ space: 1 }) {
            Text('去有风的地方')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#243A47')
            Text('WANDERLUST · 2026')
              .fontSize(7)
              .fontColor('#5A7382')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 双圈航空邮戳示意
          Row() {
            Text('POST')
              .fontSize(6)
              .fontWeight(FontWeight.Bold)
              .fontColor('#476375')
          }
          .width(22)
          .height(22)
          .borderRadius(11)
          .border({ width: 1, color: '#476375' })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(34)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_gradient_frame') {
      // 蔡司幻彩双色渐变框
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .borderRadius(4)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 6, right: 6, top: 6, bottom: 28 })
        .linearGradient({
          angle: 135,
          colors: [['#00D2FF', 0.0], ['#0055FF', 0.5], ['#FF7A00', 1.0]]
        })

        // 底栏黑色磨砂
        Row() {
          Text('vivo | ZEISS')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Blank()

          Row() {
            Text('ZEISS')
              .fontSize(7)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 3, right: 3, top: 1, bottom: 1 })
          .backgroundColor('#0047BA')
          .borderRadius(2)
        }
        .width('100%')
        .height(26)
        .padding({ left: 8, right: 8 })
        .backgroundColor('rgba(18, 18, 20, 0.92)')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_leather_badge') {
      // 皮革彩虹标：碳黑皮革底 + 彩虹徽章
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.15)' })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 30 })
        .backgroundColor('#1F1E1D')

        Row() {
          Column({ space: 1 }) {
            Text('Color : Vivid')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(8)
              .fontColor('#EDEAE6')
            Text('Shot on camera')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(7)
              .fontColor('#9E978F')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 经典六色彩虹徽章示意
          Row() {
            Row() {
              Column().width(2).height(12).backgroundColor('#E53935')
              Column().width(2).height(12).backgroundColor('#FB8C00')
              Column().width(2).height(12).backgroundColor('#FDD835')
              Column().width(2).height(12).backgroundColor('#43A047')
              Column().width(2).height(12).backgroundColor('#1E88E5')
              Column().width(2).height(12).backgroundColor('#8E24AA')
            }
            Text('VIVID')
              .fontSize(6)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ left: 3 })
          }
          .padding({ left: 2, right: 4, top: 1, bottom: 1 })
          .backgroundColor('#2B2927')
          .border({ width: 0.5, color: '#423F3C' })
          .borderRadius(2)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_mint_film') {
      // 清新薄荷绿：治愈薄荷底 + 相机图标
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 28 })
        .backgroundColor('#A3E4D7')

        Row() {
          Row({ space: 4 }) {
            Text('📷')
              .fontSize(9)
            Text('MINT FILM')
              .fontSize(8)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1D453B')
          }

          Blank()

          Text('f/2.8 · 1/250s')
            .fontSize(7)
            .fontColor('#154035')
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .backgroundColor('rgba(255, 255, 255, 0.85)')
            .borderRadius(8)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#A3E4D7')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_slim_white') {
      // 极简细白条
      Stack({ alignContent: Alignment.Bottom }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Row() {
          Text('LEICA M11')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')
          Blank()
          Text('35mm · ISO 100')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(7)
            .fontColor('#666666')
        }
        .width('100%')
        .height(18)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'camera_watermark') {
      // 经典相机水印
      Stack({ alignContent: Alignment.Bottom }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Cover)

        Row() {
          Row({ space: 4 }) {
            Row()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor('#E4002B')
            Text('LEICA M11')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111111')
          }

          Blank()

          Text('50mm · f/1.4 · 1/200s · ISO 100')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(7)
            .fontColor('#666666')
        }
        .width('100%')
        .height(26)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_master_grid') {
      // 影展矩阵
      Stack({ alignContent: Alignment.Bottom }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Cover)

        Row() {
          Column({ space: 1 }) {
            Text('EXHIBITION · MASTER')
              .fontSize(7)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111111')
            Text('50mm | f/1.4 | 1/250s | ISO 100')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(6)
              .fontColor('#777777')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Row() {
            Text('印')
              .fontSize(6)
              .fontColor('#FFFFFF')
          }
          .width(14)
          .height(14)
          .backgroundColor('#B23B2F')
          .borderRadius(2)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_blur_pip') {
      // 画中画虚化
      Stack({ alignContent: Alignment.Center }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(20)

        Image(normalizeImageSrc(this.imageSrc))
          .width('78%')
          .height('78%')
          .objectFit(ImageFit.Cover)
          .borderRadius(6)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.5)' })
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_cinematic') {
      // 电影影集
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row()
            .width('100%')
            .height(16)
            .backgroundColor('#000000')
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
          Row() {
            Text('CINEMATIC 2.39:1 · WIDESCREEN')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(6)
              .fontColor('#E0DCD3')
          }
          .width('100%')
          .height(16)
          .backgroundColor('#000000')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_retro_film') {
      // 复古胶片
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 28 })
        .backgroundColor('#F5F2E8')

        Row() {
          Text('Retro 1984 · FUJIFILM')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(8)
            .fontColor('#444444')
          Blank()
          Text('No.24')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(7)
            .fontColor('#888888')
        }
        .width('100%')
        .height(26)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_overlay') {
      // 无界悬浮
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Row({ space: 4 }) {
          Text('✦')
            .fontSize(8)
            .fontColor('#FFFFFF')
          Text('50mm f/1.4 · 1/200s · ISO 100')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(7)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor('rgba(0, 0, 0, 0.55)')
        .borderRadius(8)
        .margin({ left: 8, bottom: 8 })
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_nordic_gallery') {
      // 北欧画廊
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 28 })
        .backgroundColor('#FFFFFF')

        Row() {
          Row()
            .width(5)
            .height(5)
            .borderRadius(2.5)
            .backgroundColor('#FF6600')
          Text('HASSELBLAD')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ left: 4 })
          Blank()
          Text('55mm F2.8')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(7)
            .fontColor('#777777')
        }
        .width('100%')
        .height(26)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_editorial_mag') {
      // 纪实画报
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 4, right: 4, top: 4, bottom: 26 })
        .backgroundColor('#1A1A1A')

        Row() {
          Row()
            .width(3)
            .height(12)
            .backgroundColor('#FFD700')
          Text('THE MOMENT')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ left: 4 })
          Blank()
          Text("30°15'N 120°10'E")
            .fontFamily(Theme.FONT_MONO)
            .fontSize(6)
            .fontColor('#AAAAAA')
        }
        .width('100%')
        .height(24)
        .padding({ left: 8, right: 8 })
        .backgroundColor('#1A1A1A')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_contact_sheet') {
      // 暗房印样
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row() {
            Text('KODAK PORTRA 400')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(6)
              .fontColor('#D4A373')
            Blank()
            Text('▶ 36A')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(6)
              .fontColor('#D4A373')
          }
          .width('100%')
          .height(16)
          .padding({ left: 6, right: 6 })
          .backgroundColor('#1A1A1A')
          .alignItems(VerticalAlign.Center)

          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)

          Row() {
            Text('[-2..0..+2]')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(6)
              .fontColor('#D4A373')
          }
          .width('100%')
          .height(16)
          .padding({ left: 6, right: 6 })
          .backgroundColor('#1A1A1A')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'watermark_oriental_seal') {
      // 文书钤印
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .border({ width: 0.8, color: 'rgba(178, 59, 47, 0.7)' })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 28 })
        .backgroundColor('#F7F4EB')

        Row() {
          Text('澄怀观道')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(9)
            .fontColor('#241918')
          Blank()
          Row() {
            Text('澄心')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(7)
              .fontColor('#F7F4EB')
          }
          .width(16)
          .height(16)
          .backgroundColor('#A32924')
          .border({ width: 0.5, color: '#F7F4EB' })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(26)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'paper_white') {
      // 宣纸留白
      Stack({ alignContent: Alignment.Center }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('82%')
          .height('82%')
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    } else if (tpl.templateId === 'ink_black') {
      // 墨框
      Stack({ alignContent: Alignment.Center }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('82%')
          .height('82%')
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1A1A1A')
    } else if (tpl.templateId === 'floating_shadow') {
      // 浮光卡片
      Stack({ alignContent: Alignment.Center }) {
        Image(normalizeImageSrc(this.imageSrc))
          .width('76%')
          .height('76%')
          .objectFit(ImageFit.Cover)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.45)' })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ECEAE6')
    } else if (tpl.templateId === 'film_negative') {
      // 胶片齿孔
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row({ space: 4 }) {
            ForEach([1, 2, 3, 4, 5, 6, 7, 8], (_: number) => {
              Row().width(6).height(6).borderRadius(1).backgroundColor('#FFFFFF')
            }, (n: number) => n.toString())
          }
          .width('100%')
          .height(12)
          .backgroundColor('#1A1A1A')
          .justifyContent(FlexAlign.SpaceEvenly)

          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)

          Row({ space: 4 }) {
            ForEach([1, 2, 3, 4, 5, 6, 7, 8], (_: number) => {
              Row().width(6).height(6).borderRadius(1).backgroundColor('#FFFFFF')
            }, (n: number) => n.toString())
          }
          .width('100%')
          .height(12)
          .backgroundColor('#1A1A1A')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'polaroid') {
      // 拍立得
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(normalizeImageSrc(this.imageSrc))
            .width('100%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 38 })
        .backgroundColor('#F5F2E8')
      }
      .width('100%')
      .height('100%')
    } else if (tpl.templateId === 'scroll_mount') {
      // 卷轴装裱
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#5C4033')
          Image(normalizeImageSrc(this.imageSrc))
            .width('84%')
            .layoutWeight(1)
            .objectFit(ImageFit.Cover)
            .border({ width: 1, color: '#C49A5B' })
          Row()
            .width('100%')
            .height(8)
            .backgroundColor('#5C4033')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EFEBD9')
    } else {
      Image(normalizeImageSrc(this.imageSrc))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
  }
}
