import {
  ADJUST_MAX,
  ADJUST_MIN,
  ADJUST_TYPES,
  AdjustParams,
  AdjustTypeDef,
  formatAdjustValue
} from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 调节面板（「调节」工具内容）：上下两行。
 * 上：重置（当前滑块）| 滑块（绑定已选调整类型）| 对比（按住显示原图）。
 * 下：调整类型选择（曝光/亮度/对比度/饱和度），横向平铺、间距均匀，便于拇指点击。
 */
@Component
export struct AdjustPanel {
  @Prop params: AdjustParams = { exposure: 0, brightness: 0, contrast: 0, saturation: 0 };
  @Prop selectedType: string = 'exposure';
  onChange: (key: string, value: number) => void = () => {};
  onSelectType: (key: string) => void = () => {};
  onReset: () => void = () => {};
  onCompareChange: (down: boolean) => void = () => {};

  build() {
    Column() {
      // ── 上：重置 | 滑块块 | 对比 ──
      Row({ space: 12 }) {
        // 重置（重置当前滑块数值）
        Row() {
          Image($r('app.media.icon_reset'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .fillColor(Theme.ON_SURFACE_VARIANT)
        }
        .width(44)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onClick(() => this.onReset())

        // 滑块块：类型标签 + 数值 + 滑块
        Column({ space: 4 }) {
          Row() {
            Text(this.selectedLabel())
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.ON_SURFACE)
            Text(`[${this.selectedUnit()}]`)
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT_70)
              .margin({ left: 6 })
            Blank()
            Text(formatAdjustValue(this.selectedValue()))
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
              .textAlign(TextAlign.End)
          }
          .width('100%')

          Slider({
            value: this.selectedValue(),
            min: ADJUST_MIN,
            max: ADJUST_MAX,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockStyle({
              type: SliderBlockType.SHAPE,
              shape: new Rect({ width: 16, height: 16, radius: 2 }).fill(Theme.SEAL_RED)
            })
            .blockSize({ width: 16, height: 16 })
            .blockColor(Theme.SEAL_RED)
            .selectedColor(Theme.SEAL_RED)
            .trackColor(Theme.OUTLINE_VARIANT)
            .trackThickness(2)
            .width('100%')
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode !== SliderChangeMode.Begin) {
                this.onChange(this.selectedType, value);
              }
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 对比（按住显示原图，松开恢复）
        Row() {
          Image($r('app.media.icon_compare'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .fillColor(Theme.ON_SURFACE_VARIANT)
        }
        .width(44)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.onCompareChange(true);
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.onCompareChange(false);
          }
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      // ── 下：调整类型选择 ──
      Row() {
        ForEach(ADJUST_TYPES, (t: AdjustTypeDef) => {
          this.typeChip(t)
        }, (t: AdjustTypeDef) => t.key)
      }
      .width('100%')
      .height(48)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  typeChip(t: AdjustTypeDef) {
    Column({ space: 2 }) {
      Text(t.unit)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(this.selectedType === t.key ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT_70)
      Text(t.label)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontWeight(this.selectedType === t.key ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedType === t.key ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .border({ width: { bottom: this.selectedType === t.key ? 3 : 0 }, color: Theme.SEAL_RED })
    .onClick(() => this.onSelectType(t.key))
  }

  private selectedDef(): AdjustTypeDef {
    const hit = ADJUST_TYPES.find((t: AdjustTypeDef) => t.key === this.selectedType);
    return hit != null ? hit : ADJUST_TYPES[0];
  }

  private selectedLabel(): string {
    return this.selectedDef().label;
  }

  private selectedUnit(): string {
    return this.selectedDef().unit;
  }

  private selectedValue(): number {
    if (this.selectedType === 'exposure') {
      return this.params.exposure;
    }
    if (this.selectedType === 'brightness') {
      return this.params.brightness;
    }
    if (this.selectedType === 'contrast') {
      return this.params.contrast;
    }
    if (this.selectedType === 'saturation') {
      return this.params.saturation;
    }
    return 0;
  }
}
