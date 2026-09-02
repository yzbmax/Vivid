import { BorderState, clampBorderShadow, clampBorderWidthRatio } from '../../models/SharedContracts';
import {
  BORDER_TEMPLATES,
  BorderTemplate,
  templateSupportsCapability
} from '../../features/editor/border/BorderCatalog';
import { Theme } from '../common/Theme';

/**
 * 边框面板（装裱 · 边式）。
 *
 * 遵循 Mask & Seal 语言：
 * - 标题使用衬线字体
 * - 参数标签使用等宽字体
 * - 选中态使用朱砂 #B23B2F，主要动作 #7B171B
 * - 滑块沿用朱砂方块滑块头
 * - 边框缩略图使用四角括号和浅朱砂内线（占位 SVG 已实现）
 *
 * 控件可用性按模板能力禁用：
 * - 不支持 color 时色板禁用
 * - 不支持 shadow 时投影滑块禁用
 * - `none` 模板时全部禁用
 */
@Component
export struct BorderPanel {
  @Prop border: BorderState = {
    templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0
  };
  onSelectTemplate: (templateId: string) => void = () => {};
  onWidthRatioChange: (value: number) => void = () => {};
  onColorChange: (colorArgb: number) => void = () => {};
  onShadowChange: (value: number) => void = () => {};

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
        Text(this.border.templateId === 'none' ? '无' : this.templateNameOf(this.border.templateId))
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(Theme.PRIMARY)
      }
      .width('100%')
      .height(24)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      // ── 边式横向选择列表 ──
      Scroll() {
        Row({ space: 8 }) {
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

      // ── 参数控件（边宽 / 色纸 / 投影）──
      Column({ space: 4 }) {
        // 边宽滑块（所有非 none 模板都可调）
        Row({ space: 10 }) {
          Text('边宽')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(this.enabledWidth() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
          Slider({
            value: this.border.widthRatio,
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
            .onChange((value: number) => this.onWidthRatioChange(clampBorderWidthRatio(value)))
          Text(`${Math.round(this.border.widthRatio * 100)}%`)
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO)
            .fontColor(Theme.PRIMARY)
            .width(40)
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
          Row({ space: 6 }) {
            ForEach(this.colorPalette, (color: number) => {
              this.colorSwatch(color)
            })
          }
        }
        .width('100%')
        .height(28)
        .alignItems(VerticalAlign.Center)

        // 投影滑块
        Row({ space: 10 }) {
          Text('投影')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(this.enabledShadow() ? Theme.ON_SURFACE_VARIANT : Theme.ON_SURFACE_VARIANT_70)
          Slider({
            value: this.border.shadowStrength,
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
          Text(`${Math.round(this.border.shadowStrength * 100)}`)
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
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 8, bottom: 10 })
  }

  /** 当前模板是否支持边宽调节（非 none 且 widthRatio 能力开启）。 */
  private enabledWidth(): boolean {
    return this.border.templateId !== 'none' &&
      templateSupportsCapability(this.border.templateId, 'width');
  }

  /** 当前模板是否支持色纸调节。 */
  private enabledColor(): boolean {
    return templateSupportsCapability(this.border.templateId, 'color');
  }

  /** 当前模板是否支持投影调节。 */
  private enabledShadow(): boolean {
    return templateSupportsCapability(this.border.templateId, 'shadow');
  }

  private templateNameOf(templateId: string): string {
    for (const tpl of BORDER_TEMPLATES) {
      if (tpl.templateId === templateId) {
        return tpl.name;
      }
    }
    return templateId;
  }

  /** 单个边式卡片（含四角括号装饰）。 */
  @Builder
  templateCard(tpl: BorderTemplate) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 预览区（64×48）：使用 SVG 或占位
        Stack() {
          Column()
            .width(64)
            .height(48)
            .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
            .borderRadius(2)
          // 四角括号 + 浅朱砂内线（Mask & Seal 边框缩略图语言）
          Column()
            .width(60)
            .height(44)
            .border({
              width: 0.5,
              color: Theme.PRIMARY_20
            })
        }
        .width(64)
        .height(48)

        // 选中态：朱砂 2px 边框
        if (this.border.templateId === tpl.templateId) {
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
        .fontColor(this.border.templateId === tpl.templateId ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
        .fontWeight(this.border.templateId === tpl.templateId ? FontWeight.Bold : FontWeight.Normal)
        .maxLines(1)
    }
    .width(72)
    .height(68)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onSelectTemplate(tpl.templateId))
  }

  /** 单个色板方块。选中时显示朱砂描边。 */
  @Builder
  colorSwatch(color: number) {
    Stack() {
      Column()
        .width(20)
        .height(20)
        .backgroundColor(this.argbToHex(color))
        .borderRadius(2)
        .border({ width: 0.5, color: Theme.OUTLINE_VARIANT })
      if (this.border.colorArgb === color) {
        Column()
          .width(20)
          .height(20)
          .border({ width: 1.5, color: Theme.SEAL_RED })
          .borderRadius(2)
      }
    }
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
