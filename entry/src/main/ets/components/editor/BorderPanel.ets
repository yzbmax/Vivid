import {
  BorderState,
  clampBorderRadiusRatio,
  clampBorderShadow,
  clampBorderWidthRatio,
  WatermarkConfig,
  WatermarkLogoType,
  defaultWatermarkConfig,
  cloneWatermarkConfig
} from '../../models/SharedContracts';
import {
  BORDER_TEMPLATES,
  BorderTemplate,
  templateSupportsCapability,
  isWatermarkTemplate
} from '../../features/editor/border/BorderCatalog';
import { Theme } from '../common/Theme';

interface LogoOption {
  id: WatermarkLogoType;
  label: string;
}

interface DevicePreset {
  name: string;
  logo: WatermarkLogoType;
}

/**
 * 边框面板（装裱 · 边式）。
 *
 * 遵循 Mask & Seal 语言：
 * - 标题使用衬线字体
 * - 参数标签使用等宽字体
 * - 选中态使用朱砂 #B23B2F，主要动作 #7B171B
 * - 滑块沿用朱砂方块滑块头
 * - 边框缩略图使用四角括号和浅朱砂内线（占位 SVG 已实现）
 * - 支持相机水印专属配置（机型、Logo、参数、时间自选与自由切换）
 */
@Component
export struct BorderPanel {
  @Prop borderState: BorderState = {
    templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0, radiusRatio: 0
  };
  @Prop imageSrc: string = '';
  onSelectTemplate: (templateId: string) => void = () => {};
  onWidthRatioChange: (value: number) => void = () => {};
  onRadiusChange: (value: number) => void = () => {};
  onColorChange: (colorArgb: number) => void = () => {};
  onShadowChange: (value: number) => void = () => {};
  onWatermarkChange: (watermark: WatermarkConfig) => void = () => {};
  onExtractExif: () => void = () => {};
  onOpenFullPicker: () => void = () => {};

  @State activeWatermarkTab: number = 0; // 0: 机型与标识, 1: 参数与时间, 2: 边框底色

  /** 8 色板（Mask & Seal · 固定色板）：墨黑/纸白/朱砂/深朱砂/青瓷/琥珀/灰墨/反色纸白。 */
  private readonly colorPalette: number[] = [
    0xFF1A1A1A, // 墨黑
    0xFFF5F2E8, // 纸白
    0xFFB23B2F, // 朱砂
    0xFF7B171B, // 深朱砂
    0xFF8CA3A3, // 青瓷
    0xFFC49A5B, // 琥珀
    0xFF574140, // 灰墨
    0xFFF2F1ED  // 反色纸白
  ];

  private readonly logoOptions: LogoOption[] = [
    { id: 'zeiss', label: '蔡司 ZEISS' },
    { id: 'leica', label: '徕卡 LEICA' },
    { id: 'hasselblad', label: '哈苏 HASSELBLAD' },
    { id: 'xmage', label: '华为 XMAGE' },
    { id: 'fujifilm', label: '富士 FUJIFILM' },
    { id: 'xiaomi', label: '小米 Xiaomi' },
    { id: 'huawei', label: '华为 HUAWEI' },
    { id: 'apple', label: 'Apple' },
    { id: 'samsung', label: '三星 SAMSUNG' },
    { id: 'vivo', label: 'vivo' },
    { id: 'oppo', label: 'OPPO' },
    { id: 'honor', label: '荣耀 HONOR' },
    { id: 'sony', label: '索尼 SONY' },
    { id: 'canon', label: '佳能 Canon' },
    { id: 'nikon', label: '尼康 Nikon' },
    { id: 'master', label: 'Master 影展' },
    { id: 'none', label: '无标识' }
  ];

  private readonly devicePresets: DevicePreset[] = [
    { name: 'vivo X300 Pro', logo: 'zeiss' },
    { name: 'HUAWEI Mate 60 Pro', logo: 'xmage' },
    { name: 'HUAWEI Pura 70 Ultra', logo: 'huawei' },
    { name: 'Xiaomi 14 Ultra', logo: 'leica' },
    { name: 'Xiaomi 15 Pro', logo: 'xiaomi' },
    { name: 'iPhone 16 Pro', logo: 'apple' },
    { name: 'iPhone 15 Pro Max', logo: 'apple' },
    { name: 'Samsung S24 Ultra', logo: 'samsung' },
    { name: 'OPPO Find X7 Ultra', logo: 'hasselblad' },
    { name: 'HONOR Magic6 Pro', logo: 'honor' },
    { name: 'Fujifilm X-T5', logo: 'fujifilm' },
    { name: 'Fujifilm X100VI', logo: 'fujifilm' },
    { name: 'Sony α7 IV', logo: 'sony' },
    { name: 'Canon EOS R5', logo: 'canon' },
    { name: 'Nikon Z8', logo: 'nikon' },
    { name: 'Leica M11', logo: 'leica' }
  ];

  build() {
    Column({ space: 6 }) {
      // ── 标题 ──
      Row() {
        Text('装裱 · 边式')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontWeight(600)
          .fontColor(Theme.ON_SURFACE)
        Blank()
        Row({ space: 8 }) {
          // 相机水印模版快捷直出 EXIF 读取按钮
          if (isWatermarkTemplate(this.borderState.templateId)) {
            Row({ space: 2 }) {
              Text('⚡')
                .fontSize(10)
              Text('读EXIF')
                .fontFamily(Theme.FONT_SANS)
                .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
                .fontColor(Theme.SEAL_RED)
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
            .borderRadius(10)
            .onClick(() => {
              this.onExtractExif();
            })
          }

          Text(this.borderState.templateId === 'none' ? '无' : this.templateNameOf(this.borderState.templateId))
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.PRIMARY)

          // 展开全屏模版库按钮
          Row({ space: 3 }) {
            Text('全屏库')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.SEAL_RED)
            Text('⤢')
              .fontSize(11)
              .fontColor(Theme.SEAL_RED)
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
          .borderRadius(10)
          .onClick(() => {
            this.onOpenFullPicker();
          })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(24)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      // ── 边式横向选择列表 ──
      Scroll() {
        Row({ space: 8 }) {
          // 首项：直达全屏模版库的大卡片
          this.allTemplatesEntryCard()

          ForEach(BORDER_TEMPLATES, (tpl: BorderTemplate) => {
            this.templateCard(tpl)
          }, (tpl: BorderTemplate) => tpl.templateId)
        }
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(72)

      // ── 参数控件区域 ──
      if (isWatermarkTemplate(this.borderState.templateId)) {
        this.watermarkCustomization()
      } else {
        this.defaultBorderControls()
      }
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 8, bottom: 10 })
  }

  /** 相机水印专属配置抽屉 */
  @Builder
  watermarkCustomization() {
    Column({ space: 6 }) {
      // 1. 无边框分段控制器（Segmented Pill 单体胶囊控制条）
      Row() {
        this.segmentedTabItem('机型 & 标识', 0)
        this.segmentedTabItem('参数 & 时间', 1)
        this.segmentedTabItem('底栏边框', 2)
      }
      .width('100%')
      .height(34)
      .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
      .borderRadius(17)
      .padding(3)

      // 2. Tab 内容
      if (this.activeWatermarkTab === 0) {
        // Tab 0: 机型与标识
        Column({ space: 6 }) {
          // 机型输入与开关
          Row({ space: 8 }) {
            Text('机型')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .width(32)
            Toggle({ type: ToggleType.Switch, isOn: this.currentWatermark().showDevice })
              .selectedColor(Theme.SEAL_RED)
              .onChange((isOn: boolean) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.showDevice = isOn;
                this.onWatermarkChange(next);
              })
            TextInput({ text: this.currentWatermark().deviceModel, placeholder: '输入机型型号' })
              .layoutWeight(1)
              .height(28)
              .fontSize(12)
              .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
              .borderRadius(4)
              .enabled(this.currentWatermark().showDevice)
              .onChange((val: string) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.deviceModel = val;
                this.onWatermarkChange(next);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 常用机型快捷预设
          Scroll() {
            Row({ space: 6 }) {
              ForEach(this.devicePresets, (preset: DevicePreset) => {
                Text(preset.name)
                  .fontSize(11)
                  .fontFamily(Theme.FONT_SANS)
                  .fontColor(this.currentWatermark().deviceModel === preset.name ? Theme.SEAL_RED : Theme.ON_SURFACE_VARIANT)
                  .backgroundColor(this.currentWatermark().deviceModel === preset.name ? Theme.SURFACE_CONTAINER_HIGHEST : Theme.PAPER_SURFACE)
                  .border({ width: 0.5, color: this.currentWatermark().deviceModel === preset.name ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT })
                  .borderRadius(12)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .onClick(() => {
                    const next = cloneWatermarkConfig(this.currentWatermark());
                    next.deviceModel = preset.name;
                    next.logo = preset.logo;
                    next.showDevice = true;
                    next.showLogo = true;
                    this.onWatermarkChange(next);
                  })
              }, (p: DevicePreset) => p.name)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          // Logo 标识选择
          Row({ space: 8 }) {
            Text('Logo')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .width(32)
            Toggle({ type: ToggleType.Switch, isOn: this.currentWatermark().showLogo })
              .selectedColor(Theme.SEAL_RED)
              .onChange((isOn: boolean) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.showLogo = isOn;
                this.onWatermarkChange(next);
              })
            Scroll() {
              Row({ space: 6 }) {
                ForEach(this.logoOptions, (opt: LogoOption) => {
                  Text(opt.label)
                    .fontSize(11)
                    .fontFamily(Theme.FONT_SANS)
                    .fontColor(this.currentWatermark().logo === opt.id ? Theme.SEAL_RED : Theme.ON_SURFACE_VARIANT)
                    .backgroundColor(this.currentWatermark().logo === opt.id ? Theme.SURFACE_CONTAINER_HIGHEST : Theme.PAPER_SURFACE)
                    .border({ width: 0.5, color: this.currentWatermark().logo === opt.id ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT })
                    .borderRadius(12)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .onClick(() => {
                      const next = cloneWatermarkConfig(this.currentWatermark());
                      next.logo = opt.id;
                      next.showLogo = true;
                      this.onWatermarkChange(next);
                    })
                }, (opt: LogoOption) => opt.id)
              }
            }
            .layoutWeight(1)
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      } else if (this.activeWatermarkTab === 1) {
        // Tab 1: 参数与时间
        Column({ space: 6 }) {
          // 参数行
          Row({ space: 8 }) {
            Text('参数')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .width(32)
            Toggle({ type: ToggleType.Switch, isOn: this.currentWatermark().showParams })
              .selectedColor(Theme.SEAL_RED)
              .onChange((isOn: boolean) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.showParams = isOn;
                this.onWatermarkChange(next);
              })
            TextInput({ text: this.currentWatermark().paramsText, placeholder: '85mm f/2.67 1/10s ISO10492' })
              .layoutWeight(1)
              .height(28)
              .fontSize(11)
              .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
              .borderRadius(4)
              .enabled(this.currentWatermark().showParams)
              .onChange((val: string) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.paramsText = val;
                this.onWatermarkChange(next);
              })
            Button('读EXIF')
              .fontSize(10)
              .height(26)
              .fontColor(Theme.SEAL_RED)
              .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
              .border({ width: 0.5, color: Theme.SEAL_RED })
              .borderRadius(4)
              .onClick(() => {
                this.onExtractExif();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 时间行
          Row({ space: 8 }) {
            Text('时间')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .width(32)
            Toggle({ type: ToggleType.Switch, isOn: this.currentWatermark().showTime })
              .selectedColor(Theme.SEAL_RED)
              .onChange((isOn: boolean) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.showTime = isOn;
                this.onWatermarkChange(next);
              })
            TextInput({ text: this.currentWatermark().timeText, placeholder: '2026.09.03 16:30' })
              .layoutWeight(1)
              .height(28)
              .fontSize(11)
              .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
              .borderRadius(4)
              .enabled(this.currentWatermark().showTime)
              .onChange((val: string) => {
                const next = cloneWatermarkConfig(this.currentWatermark());
                next.timeText = val;
                this.onWatermarkChange(next);
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      } else {
        // Tab 2: 边框底色与高度
        Column({ space: 4 }) {
          Row({ space: 10 }) {
            Text('高度')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Slider({
              value: this.borderState.widthRatio,
              min: 0.04,
              max: 0.20,
              step: 0.01,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .blockColor(Theme.SEAL_RED)
              .selectedColor(Theme.SEAL_RED)
              .trackColor(Theme.OUTLINE_VARIANT)
              .onChange((value: number) => {
                const snapped = this.snapWidthRatio(clampBorderWidthRatio(value));
                this.onWidthRatioChange(snapped);
              })
            Text(this.formatWidthLabel(this.borderState.widthRatio))
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO)
              .fontColor(Theme.PRIMARY)
              .width(56)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(30)

          Row({ space: 10 }) {
            Text('圆角')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Slider({
              value: this.borderState.radiusRatio ?? 0,
              min: 0,
              max: 1,
              step: 0.01,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .blockColor(Theme.SEAL_RED)
              .selectedColor(Theme.SEAL_RED)
              .trackColor(Theme.OUTLINE_VARIANT)
              .onChange((value: number) => {
                const snapped = this.snapRadiusRatio(clampBorderRadiusRatio(value));
                this.onRadiusChange(snapped);
              })
            Text(this.formatRadiusLabel(this.borderState.radiusRatio ?? 0))
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO)
              .fontColor(Theme.PRIMARY)
              .width(56)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(30)

          Row({ space: 6 }) {
            Text('底色')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .width(28)
            Scroll() {
              Row({ space: 6 }) {
                this.defaultColorPill()
                ForEach(this.colorPalette, (color: number) => {
                  this.colorSwatch(color)
                })
              }
              .alignItems(VerticalAlign.Center)
            }
            .layoutWeight(1)
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .height(30)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
  }

  @Builder
  segmentedTabItem(label: string, index: number) {
    Row() {
      Text(label)
        .fontSize(11)
        .fontFamily(Theme.FONT_SANS)
        .fontWeight(this.activeWatermarkTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeWatermarkTab === index ? Theme.SEAL_RED : Theme.ON_SURFACE_VARIANT)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.activeWatermarkTab === index ? '#FFFFFF' : Color.Transparent)
    .borderRadius(14)
    .shadow(this.activeWatermarkTab === index ? { radius: 4, color: 'rgba(0,0,0,0.08)', offsetY: 1 } : { radius: 0, color: Color.Transparent })
    .animation({ duration: 180, curve: Curve.FastOutSlowIn })
    .onClick(() => {
      this.activeWatermarkTab = index;
    })
  }

  private currentWatermark(): WatermarkConfig {
    return this.borderState.watermark ? this.borderState.watermark : defaultWatermarkConfig();
  }

  /** 标准边框控件（边宽 / 色纸 / 投影） */
  @Builder
  defaultBorderControls() {
    Column({ space: 4 }) {
      // 边宽滑块
      Row({ space: 10 }) {
        Text('边宽')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(this.enabledWidth() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
        Slider({
          value: this.borderState.widthRatio,
          min: 0,
          max: 0.25,
          step: 0.01,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .enabled(this.enabledWidth())
          .blockColor(Theme.SEAL_RED)
          .selectedColor(Theme.SEAL_RED)
          .trackColor(Theme.OUTLINE_VARIANT)
          .onChange((value: number) => {
            const snapped = this.snapWidthRatio(clampBorderWidthRatio(value));
            this.onWidthRatioChange(snapped);
          })
        Text(this.formatWidthLabel(this.borderState.widthRatio))
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO)
          .fontColor(Theme.PRIMARY)
          .width(56)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(32)

      // 圆角滑块
      Row({ space: 10 }) {
        Text('圆角')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(this.enabledRadius() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
        Slider({
          value: this.borderState.radiusRatio ?? 0,
          min: 0,
          max: 1,
          step: 0.01,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .enabled(this.enabledRadius())
          .blockColor(Theme.SEAL_RED)
          .selectedColor(Theme.SEAL_RED)
          .trackColor(Theme.OUTLINE_VARIANT)
          .onChange((value: number) => {
            const snapped = this.snapRadiusRatio(clampBorderRadiusRatio(value));
            this.onRadiusChange(snapped);
          })
        Text(this.formatRadiusLabel(this.borderState.radiusRatio ?? 0))
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO)
          .fontColor(Theme.PRIMARY)
          .width(56)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(32)

      // 色板
      Row({ space: 6 }) {
        Text('色纸')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(this.enabledColor() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
          .width(28)
        Scroll() {
          Row({ space: 6 }) {
            this.defaultColorPill()
            ForEach(this.colorPalette, (color: number) => {
              this.colorSwatch(color)
            })
          }
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height(30)
      .alignItems(VerticalAlign.Center)

      // 投影滑块
      Row({ space: 10 }) {
        Text('投影')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(this.enabledShadow() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
        Slider({
          value: this.borderState.shadowStrength,
          min: 0,
          max: 1,
          step: 0.01,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .enabled(this.enabledShadow())
          .blockColor(Theme.SEAL_RED)
          .selectedColor(Theme.SEAL_RED)
          .trackColor(Theme.OUTLINE_VARIANT)
          .onChange((value: number) => this.onShadowChange(clampBorderShadow(value)))
        Text(`${Math.round(this.borderState.shadowStrength * 100)}`)
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO)
          .fontColor(Theme.PRIMARY)
          .width(32)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(32)
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
  }

  /** 当前模板是否支持边宽调节（非 none 且 widthRatio 能力开启）。 */
  private enabledWidth(): boolean {
    return this.borderState.templateId !== 'none' &&
      templateSupportsCapability(this.borderState.templateId, 'width');
  }

  /** 当前模板是否支持圆角调节。 */
  private enabledRadius(): boolean {
    return this.borderState.templateId !== 'none' &&
      templateSupportsCapability(this.borderState.templateId, 'radius');
  }

  /** 当前模板是否支持色纸调节。 */
  private enabledColor(): boolean {
    return templateSupportsCapability(this.borderState.templateId, 'color');
  }

  /** 当前模板是否支持投影调节。 */
  private enabledShadow(): boolean {
    return templateSupportsCapability(this.borderState.templateId, 'shadow');
  }

  private templateNameOf(templateId: string): string {
    for (const tpl of BORDER_TEMPLATES) {
      if (tpl.templateId === templateId) {
        return tpl.name;
      }
    }
    return templateId;
  }

  private normalizedSrc(): string | Resource {
    if (!this.imageSrc || this.imageSrc.trim().length === 0) {
      return $r('app.media.work_mountain');
    }
    if (this.imageSrc.startsWith('/') && !this.imageSrc.startsWith('file://')) {
      return `file://${this.imageSrc}`;
    }
    return this.imageSrc;
  }

  /** 圆角比例磁吸：在 0%（直角）、25%（微圆）、50%（圆润）、100%（全圆）关键刻度处产生 ±2.5% 吸附 */
  private snapRadiusRatio(val: number): number {
    const snapPoints: number[] = [0, 0.25, 0.50, 1.0];
    for (let i = 0; i < snapPoints.length; i++) {
      if (Math.abs(val - snapPoints[i]) <= 0.025) {
        return snapPoints[i];
      }
    }
    return val;
  }

  /** 边宽/底栏高度磁吸：在 8%（精细）、12%（黄金比例）处产生 ±1% 吸附 */
  private snapWidthRatio(val: number): number {
    const snapPoints: number[] = [0.08, 0.12];
    for (let i = 0; i < snapPoints.length; i++) {
      if (Math.abs(val - snapPoints[i]) <= 0.01) {
        return snapPoints[i];
      }
    }
    return val;
  }

  /** 人性化圆角刻度文本 */
  private formatRadiusLabel(ratio: number): string {
    const pct = Math.round(ratio * 100);
    if (pct === 0) {
      return '0% 直角';
    }
    if (pct === 25) {
      return '25% 微圆';
    }
    if (pct === 50) {
      return '50% 圆润';
    }
    if (pct === 100) {
      return '100% 全圆';
    }
    return `${pct}%`;
  }

  /** 人性化边宽刻度文本 */
  private formatWidthLabel(ratio: number): string {
    const pct = Math.round(ratio * 100);
    if (pct === 8) {
      return '8% 精细';
    }
    if (pct === 12) {
      return '12% 黄金';
    }
    return `${pct}%`;
  }

  /** 获取当前模板官方推荐的默认色 */
  private getTemplateDefaultColor(): number {
    const id = this.borderState.templateId;
    if (id === 'retro_film' || id === 'watermark_cinematic' || id === 'shadow_box' || id === 'polaroid_dark') {
      return 0xFF1A1A1A;
    }
    if (id === 'scroll_mount' || id === 'watermark_oriental_seal') {
      return 0xFFF5F2E8;
    }
    if (id === 'watermark_leather_badge') {
      return 0xFF2A221C;
    }
    if (id === 'watermark_mint_film') {
      return 0xFF2C3E3A;
    }
    return 0xFFFFFFFF;
  }

  /** 横向预选栏首位「全部模版 ⤢」大入口卡片 */
  @Builder
  allTemplatesEntryCard() {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 3 }) {
          // 印章四方格微缩徽标
          Row({ space: 3 }) {
            Column().width(6).height(6).backgroundColor('#B23B2F').borderRadius(1)
            Column().width(6).height(6).backgroundColor('#7B171B').borderRadius(1)
          }
          Row({ space: 3 }) {
            Column().width(6).height(6).backgroundColor('#8CA3A3').borderRadius(1)
            Column().width(6).height(6).backgroundColor('#C49A5B').borderRadius(1)
          }
          Text('全部 23 款')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
        }
        .width(64)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F3EFE6')
        .border({ width: 0.8, color: '#C8C1B0', style: BorderStyle.Dashed })
        .borderRadius(2)
      }
      Text('模版库 ⤢')
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(Theme.SEAL_RED)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .width(72)
    .height(68)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onOpenFullPicker();
    })
  }

  /** 官方推荐原厂色快捷微标 */
  @Builder
  defaultColorPill() {
    Row({ space: 2 }) {
      Text('✨')
        .fontSize(9)
      Text('原色')
        .fontFamily(Theme.FONT_SANS)
        .fontSize(10)
        .fontColor(this.borderState.colorArgb === this.getTemplateDefaultColor() ? Theme.SEAL_RED : Theme.ON_SURFACE_VARIANT)
    }
    .height(24)
    .padding({ left: 6, right: 6 })
    .backgroundColor(this.borderState.colorArgb === this.getTemplateDefaultColor() ? Theme.SURFACE_CONTAINER_HIGHEST : Theme.PAPER_SURFACE)
    .border({
      width: 0.8,
      color: this.borderState.colorArgb === this.getTemplateDefaultColor() ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT
    })
    .borderRadius(12)
    .enabled(this.enabledColor())
    .opacity(this.enabledColor() ? 1 : 0.4)
    .onClick(() => {
      if (this.enabledColor()) {
        this.onColorChange(this.getTemplateDefaultColor());
      }
    })
  }

  /** 单个边式卡片（含四角括号装饰）。 */
  @Builder
  templateCard(tpl: BorderTemplate) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 预览区（64×48）：各模版真实专属微缩样态
        this.miniTemplateVisual(tpl)

        // 选中态：朱砂 2px 边框
        if (this.borderState.templateId === tpl.templateId) {
          Column()
            .width(64)
            .height(48)
            .border({ width: 2, color: Theme.SEAL_RED })
            .borderRadius(2)
        }
      }
      Text(tpl.name)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(this.borderState.templateId === tpl.templateId ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
        .fontWeight(this.borderState.templateId === tpl.templateId ? FontWeight.Bold : FontWeight.Normal)
        .maxLines(1)
    }
    .width(72)
    .height(68)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onSelectTemplate(tpl.templateId))
  }

  @Builder
  miniTemplateVisual(tpl: BorderTemplate) {
    if (tpl.templateId === 'none') {
      Image(this.normalizedSrc())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(2)
    } else if (tpl.templateId === 'camera_watermark') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .padding({ bottom: 10 })
          .objectFit(ImageFit.Cover)
        Row() {
          Row().width(4).height(4).borderRadius(2).backgroundColor('#E4002B').margin({ left: 3 })
          Row().width(14).height(2).backgroundColor('#333333').margin({ left: 2 })
          Blank()
          Row().width(12).height(2).backgroundColor('#888888').margin({ right: 3 })
        }
        .width('100%')
        .height(10)
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_master_grid') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .padding({ bottom: 12 })
          .objectFit(ImageFit.Cover)
        Row() {
          Row().width(12).height(3).backgroundColor('#333333').margin({ left: 3 })
          Blank()
          Row({ space: 2 }) {
            Column().width(1).height(6).backgroundColor('#D0D0D0')
            Column().width(1).height(6).backgroundColor('#D0D0D0')
            Column().width(1).height(6).backgroundColor('#D0D0D0')
          }.margin({ right: 3 })
        }
        .width('100%')
        .height(12)
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_blur_pip') {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(10)
        Image(this.normalizedSrc())
          .width(46)
          .height(34)
          .objectFit(ImageFit.Cover)
          .borderRadius(2)
          .shadow({ radius: 3, color: 'rgba(0,0,0,0.5)' })
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_travel_stamp') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .border({ width: 0.5, color: '#D5D0C5', style: BorderStyle.Dashed })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 3, right: 3, top: 3, bottom: 12 })
        .backgroundColor('#FBFBF9')
        Row() {
          Text('01')
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2A2621')
            .margin({ left: 3 })
          Blank()
          Text('POST')
            .fontSize(5)
            .fontColor('#6E6559')
            .border({ width: 0.5, color: '#998F82' })
            .padding(1)
            .margin({ right: 3 })
        }
        .width('100%')
        .height(12)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_travel_postcard') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .border({ width: 1, color: '#FFFFFF' })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 3, right: 3, top: 3, bottom: 13 })
        .backgroundColor('#E4ECF0')
        Row() {
          Text('去有风')
            .fontSize(5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#243A47')
            .margin({ left: 2 })
          Blank()
          Row()
            .width(8)
            .height(8)
            .borderRadius(4)
            .border({ width: 0.5, color: '#476375' })
            .margin({ right: 3 })
        }
        .width('100%')
        .height(13)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_gradient_frame') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .padding({ left: 2, right: 2, top: 2, bottom: 10 })
        Row() {
          Text('ZEISS')
            .fontSize(5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ left: 3 })
          Blank()
          Row()
            .width(6)
            .height(4)
            .backgroundColor('#0047BA')
            .borderRadius(1)
            .margin({ right: 3 })
        }
        .width('100%')
        .height(10)
        .backgroundColor('rgba(18, 18, 20, 0.92)')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .linearGradient({ angle: 135, colors: [['#00D2FF', 0.0], ['#0055FF', 0.5], ['#FF7A00', 1.0]] })
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_leather_badge') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 2, right: 2, top: 2, bottom: 11 })
        .backgroundColor('#1F1E1D')
        Row() {
          Text('VIVID')
            .fontSize(5)
            .fontColor('#EDEAE6')
            .margin({ left: 3 })
          Blank()
          Row() {
            Row().width(1).height(6).backgroundColor('#E53935')
            Row().width(1).height(6).backgroundColor('#FB8C00')
            Row().width(1).height(6).backgroundColor('#FDD835')
            Row().width(1).height(6).backgroundColor('#43A047')
            Row().width(1).height(6).backgroundColor('#1E88E5')
            Row().width(1).height(6).backgroundColor('#8E24AA')
          }
          .margin({ right: 3 })
        }
        .width('100%')
        .height(11)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_mint_film') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .padding({ bottom: 11 })
          .objectFit(ImageFit.Cover)
        Row() {
          Text('📷 MINT')
            .fontSize(5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1D453B')
            .margin({ left: 3 })
          Blank()
          Row()
            .width(10)
            .height(4)
            .borderRadius(2)
            .backgroundColor('rgba(255,255,255,0.85)')
            .margin({ right: 3 })
        }
        .width('100%')
        .height(11)
        .backgroundColor('#A3E4D7')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_slim_white') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
        Row() {
          Text('LEICA')
            .fontSize(5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')
            .margin({ left: 3 })
          Blank()
          Text('2026')
            .fontSize(5)
            .fontColor('#777777')
            .margin({ right: 3 })
        }
        .width('100%')
        .height(8)
        .backgroundColor('#FFFFFF')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_nordic_gallery') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 4, right: 4, top: 4, bottom: 12 })
        .backgroundColor('#FFFFFF')
        Row() {
          Row().width(3).height(3).borderRadius(1.5).backgroundColor('#FF6600').margin({ left: 4 })
          Text('HASSELBLAD')
            .fontSize(4)
            .fontColor('#222222')
            .margin({ left: 2 })
        }
        .width('100%')
        .height(10)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_editorial_mag') {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .padding({ bottom: 11 })
          .objectFit(ImageFit.Cover)
        Row() {
          Row().width(2).height(6).backgroundColor('#FFD700').margin({ left: 3 })
          Text('MAGAZINE')
            .fontSize(5)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ left: 2 })
          Blank()
          Text('GEO')
            .fontSize(4)
            .fontColor('#AAAAAA')
            .margin({ right: 3 })
        }
        .width('100%')
        .height(11)
        .backgroundColor('#1A1A1A')
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_cinematic') {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row().width('100%').height(7).backgroundColor('#000000')
          Image(this.normalizedSrc())
            .width('100%')
            .height(34)
            .objectFit(ImageFit.Cover)
          Row() {
            Text('CINEMA 2.39:1')
              .fontSize(4)
              .fontColor('#E0DCD3')
          }
          .width('100%').height(7).backgroundColor('#000000').justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_contact_sheet') {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row() {
            Text('KODAK 400')
              .fontSize(4)
              .fontColor('#D4A373')
              .margin({ left: 3 })
            Blank()
            Text('36A')
              .fontSize(4)
              .fontColor('#D4A373')
              .margin({ right: 3 })
          }
          .width('100%')
          .height(8)
          .backgroundColor('#1A1A1A')
          Image(this.normalizedSrc())
            .width('100%')
            .height(32)
            .objectFit(ImageFit.Cover)
          Row().width('100%').height(8).backgroundColor('#1A1A1A')
        }
        .width('100%')
        .height('100%')
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_oriental_seal') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .border({ width: 0.5, color: 'rgba(178, 59, 47, 0.7)' })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 3, right: 3, top: 3, bottom: 12 })
        .backgroundColor('#F7F4EB')
        Row() {
          Text('澄怀观道')
            .fontSize(5)
            .fontColor('#241918')
            .margin({ left: 3 })
          Blank()
          Row()
            .width(7)
            .height(7)
            .backgroundColor('#A32924')
            .borderRadius(1)
            .margin({ right: 3 })
        }
        .width('100%')
        .height(12)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_retro_film') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 3, right: 3, top: 3, bottom: 12 })
        .backgroundColor('#F5F2E8')
        Row() {
          Text('Retro 1984')
            .fontSize(5)
            .fontColor('#555555')
            .margin({ left: 3 })
          Blank()
          Text('No.24')
            .fontSize(4)
            .fontColor('#888888')
            .margin({ right: 3 })
        }
        .width('100%')
        .height(12)
        .alignItems(VerticalAlign.Center)
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'watermark_overlay') {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(this.normalizedSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
        Row() {
          Text('✦ EXIF')
            .fontSize(5)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 3, right: 3, top: 1, bottom: 1 })
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(4)
        .margin({ left: 3, bottom: 3 })
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'paper_white') {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.normalizedSrc())
          .width(54)
          .height(38)
          .objectFit(ImageFit.Cover)
      }
      .width(64)
      .height(48)
      .backgroundColor('#FFFFFF')
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'ink_black') {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.normalizedSrc())
          .width(54)
          .height(38)
          .objectFit(ImageFit.Cover)
      }
      .width(64)
      .height(48)
      .backgroundColor('#1A1A1A')
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'floating_shadow') {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.normalizedSrc())
          .width(50)
          .height(34)
          .objectFit(ImageFit.Cover)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.45)' })
      }
      .width(64)
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'film_negative') {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row({ space: 2 }) {
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
          }
          .width('100%')
          .height(5)
          .backgroundColor('#1A1A1A')
          .justifyContent(FlexAlign.SpaceEvenly)
          Image(this.normalizedSrc())
            .width('100%')
            .height(38)
            .objectFit(ImageFit.Cover)
          Row({ space: 2 }) {
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
            Row().width(3).height(3).backgroundColor('#FFFFFF')
          }
          .width('100%')
          .height(5)
          .backgroundColor('#1A1A1A')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .height('100%')
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'polaroid') {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Image(this.normalizedSrc())
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 4, right: 4, top: 4, bottom: 14 })
        .backgroundColor('#F5F2E8')
      }
      .width(64)
      .height(48)
      .borderRadius(2)
      .clip(true)
    } else if (tpl.templateId === 'scroll_mount') {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Row().width('100%').height(3).backgroundColor('#5C4033')
          Image(this.normalizedSrc())
            .width(52)
            .height(42)
            .objectFit(ImageFit.Cover)
            .border({ width: 0.5, color: '#C49A5B' })
          Row().width('100%').height(3).backgroundColor('#5C4033')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width(64)
      .height(48)
      .backgroundColor('#EFEBD9')
      .borderRadius(2)
      .clip(true)
    } else {
      Image(this.normalizedSrc())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(2)
    }
  }

  /**
   * 单个色板方块。
   * 采用【双层隔离防吞没环】：
   * - 外层：朱砂红外框 (#B23B2F)
   * - 中层：纯白光环隔离带 (#FFFFFF)
   * - 内层：色块本身
   * 彻底解决在朱砂色、深朱砂色块上红红相撞看不清选中的问题。
   */
  @Builder
  colorSwatch(color: number) {
    Stack({ alignContent: Alignment.Center }) {
      // 外部双层聚焦指示环
      if (this.borderState.colorArgb === color) {
        // 外层朱砂环
        Column()
          .width(24)
          .height(24)
          .borderRadius(4)
          .border({ width: 1.5, color: Theme.SEAL_RED })

        // 中间白色隔离光圈
        Column()
          .width(21)
          .height(21)
          .borderRadius(3)
          .border({ width: 1.5, color: '#FFFFFF' })
      }

      // 色块本身
      Column()
        .width(16)
        .height(16)
        .backgroundColor(this.argbToHex(color))
        .borderRadius(2)
        .border({ width: 0.5, color: '#D0CDC4' })
    }
    .width(26)
    .height(26)
    .enabled(this.enabledColor())
    .opacity(this.enabledColor() ? 1 : 0.4)
    .onClick(() => {
      if (this.enabledColor()) {
        this.onColorChange(color);
      }
    })
  }

  /** 把 ARGB number 转为 #RRGGBB（Alpha 丢弃，用于 CSS backgroundColor）。 */
  private argbToHex(argb: number): string {
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    const hex = (n: number): string => {
      const s = n.toString(16);
      return s.length < 2 ? '0' + s : s;
    };
    return '#' + hex(r) + hex(g) + hex(b);
  }
}
