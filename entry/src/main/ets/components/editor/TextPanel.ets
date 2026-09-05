import { TextLayer } from '../../models/SharedContracts';
import { TEXT_COLOR_PALETTE, FONT_CATALOG, FontCatalogEntry, findFontEntry, resolveFontKey } from '../../features/editor/text/FontCatalog';
import { validateTextContent } from '../../features/editor/text/TextLayerState';
import { Theme } from '../common/Theme';

@Component
export struct TextPanel {
  @Prop layers: TextLayer[] = [];
  @Prop selectedId: string = '';
  @Prop inputContent: string = '';
  @Prop validationMessage: string = '';
  @Prop saved: boolean = false;
  @Prop unavailableFontKeys: string[] = [];
  @Prop maxPanelHeight: number = 320;
  onInputChange: (value: string) => void = () => {};
  onConfirm: () => boolean = () => false;
  onDelete: () => void = () => {};
  onSelect: (id: string) => void = () => {};
  onFontChange: (fontKey: string) => void = () => {};
  onColorChange: (colorArgb: number) => void = () => {};
  onFontSizeChange: (value: number) => void = () => {};
  onRotationChange: (value: number) => void = () => {};
  onOpacityChange: (value: number) => void = () => {};
  private inputController: TextAreaController = new TextAreaController();

  build() {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Text('题签')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ON_SURFACE)
        Blank()
        Text(this.layers.length + '/8')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(Theme.ON_SURFACE_VARIANT)
        Text('＋新题签')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(12)
          .fontColor(Theme.PRIMARY)
          .height(32)
          .enabled(this.layers.length < 8)
          .opacity(this.layers.length < 8 ? 1 : 0.4)
          .onClick(() => this.onSelect(''))
        Text('保存')
          .fontFamily(Theme.FONT_MONO)
          .fontSize(13)
          .fontColor(Theme.ON_PRIMARY)
          .backgroundColor(Theme.SEAL_RED)
          .width(56)
          .height(32)
          .textAlign(TextAlign.Center)
          .borderRadius(2)
          .enabled(this.canConfirm())
          .opacity(this.canConfirm() ? 1 : 0.45)
          .onClick(() => {
            if (this.canConfirm() && this.onConfirm()) {
              this.inputController.stopEditing();
            }
          })
      }
      .width('100%')
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      Scroll() {
        Column({ space: 8 }) {
          if (this.layers.length > 0) {
            Scroll() {
              Row({ space: 6 }) {
                ForEach(this.layers, (_layer: TextLayer, index: number) => {
                  Text(this.layers[index].content)
                    .maxLines(1)
                    .fontFamily(Theme.FONT_SANS)
                    .fontSize(13)
                    .fontColor(this.layers[index].id === this.selectedId ? Theme.ON_PRIMARY : Theme.ON_SURFACE_VARIANT)
                    .backgroundColor(this.layers[index].id === this.selectedId ? Theme.SEAL_RED : Theme.SURFACE_CONTAINER_HIGHEST)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(2)
                    .onClick(() => this.onSelect(this.layers[index].id))
                }, (layer: TextLayer) => layer.id)
              }
              .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .height(36)
          }

          Row({ space: 8 }) {
            TextArea({ text: this.inputContent, placeholder: '输入即预览，最多 80 字 / 3 行', controller: this.inputController })
              .layoutWeight(1)
              .height(64)
              .fontFamily(Theme.FONT_SANS)
              .fontSize(16)
              .enterKeyType(EnterKeyType.NEW_LINE)
              .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
              .borderRadius(4)
              .border({ width: 1, color: Theme.OUTLINE_VARIANT })
              .padding(10)
              .onChange((value: string) => this.onInputChange(value))
          }
          .width('100%')
          .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

          if (this.inputValidationMessage() !== '') {
            Text(this.inputValidationMessage())
              .fontFamily(Theme.FONT_MONO)
              .fontSize(12)
              .fontColor(Theme.ERROR)
              .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
          } else {
            Text(this.saved ? '文字已保存 · 可继续修改' : '实时预览 · 保存仅确认当前题签')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(11)
              .fontColor(Theme.ON_SURFACE_VARIANT)
              .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
          }

          if (this.selectedLayer() !== null) {
            this.parameters()
          }
        }
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxHeight: Math.max(40, this.maxPanelHeight - 58) })
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 8, bottom: 10 })
  }

  @Builder
  private parameters() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        ForEach(FONT_CATALOG, (entry: FontCatalogEntry) => {
          Column({ space: 3 }) {
            Text('字 Aa')
              .fontFamily(this.fontFamily(entry.fontKey))
              .fontSize(17)
              .maxLines(1)
              .fontColor(this.selectedLayer()?.fontKey === entry.fontKey ? Theme.ON_PRIMARY : Theme.ON_SURFACE)
            Text(entry.label)
              .fontFamily(Theme.FONT_SANS)
              .fontSize(10)
              .maxLines(1)
              .fontColor(this.selectedLayer()?.fontKey === entry.fontKey ? Theme.ON_PRIMARY : Theme.ON_SURFACE_VARIANT)
          }
          .layoutWeight(1)
          .height(54)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.selectedLayer()?.fontKey === entry.fontKey ? Theme.SEAL_RED : Theme.PAPER_SURFACE)
          .border({ width: 1, color: this.selectedLayer()?.fontKey === entry.fontKey ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT })
          .borderRadius(2)
          .onClick(() => this.onFontChange(entry.fontKey))
        }, (entry: FontCatalogEntry) => entry.fontKey)
      }
      .width('100%')
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      Row({ space: 5 }) {
        Text('颜色').fontFamily(Theme.FONT_MONO).fontSize(12).fontColor(Theme.ON_SURFACE_VARIANT)
        ForEach(TEXT_COLOR_PALETTE, (color: number) => {
          Stack() {
            Column()
              .width(20)
              .height(20)
              .backgroundColor(this.argbToHex(color))
              .borderRadius(2)
              .border({ width: this.selectedLayer()?.colorArgb === color ? 2 : 0.5,
                color: this.selectedLayer()?.colorArgb === color ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT })
          }
          .onClick(() => this.onColorChange(color))
        }, (color: number) => color.toString())
      }
      .width('100%')
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      this.sliderRow('字号', this.selectedLayer()?.fontSizeRatio ?? 0.06, 0.02, 0.20, 0.01,
        (value: number) => this.onFontSizeChange(value), Math.round((this.selectedLayer()?.fontSizeRatio ?? 0.06) * 100) + '%')
      this.sliderRow('旋转', this.selectedLayer()?.rotationDeg ?? 0, -180, 180, 1,
        (value: number) => this.onRotationChange(value), Math.round(this.selectedLayer()?.rotationDeg ?? 0) + '°')
      this.sliderRow('透明', this.selectedLayer()?.opacity ?? 1, 0.30, 1, 0.01,
        (value: number) => this.onOpacityChange(value), Math.round((this.selectedLayer()?.opacity ?? 1) * 100) + '%')

      Text('删除题签')
        .fontFamily(Theme.FONT_MONO)
        .fontSize(12)
        .fontColor(Theme.PRIMARY)
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 4, bottom: 4 })
        .onClick(() => this.onDelete())
    }
    .width('100%')
  }

  @Builder
  private sliderRow(label: string, value: number, min: number, max: number, step: number,
    callback: (value: number) => void, displayValue: string) {
    Row({ space: 8 }) {
      Text(label).fontFamily(Theme.FONT_MONO).fontSize(12).fontColor(Theme.ON_SURFACE_VARIANT).width(38)
      Slider({ value: value, min: min, max: max, step: step, style: SliderStyle.OutSet })
        .layoutWeight(1)
        .blockStyle({ type: SliderBlockType.SHAPE,
          shape: new Rect({ width: 16, height: 16, radius: 2 }).fill(Theme.SEAL_RED) })
        .blockSize({ width: 16, height: 16 })
        .blockColor(Theme.SEAL_RED)
        .selectedColor(Theme.SEAL_RED)
        .trackColor(Theme.OUTLINE_VARIANT)
        .trackThickness(2)
        .onChange((next: number, mode: SliderChangeMode) => {
          if (mode !== SliderChangeMode.Begin) {
            callback(next);
          }
        })
      Text(displayValue).fontFamily(Theme.FONT_MONO).fontSize(12).fontColor(Theme.PRIMARY).width(48)
    }
    .width('100%')
    .height(28)
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
  }

  private selectedLayer(): TextLayer | null {
    for (let i = 0; i < this.layers.length; i++) {
      if (this.layers[i].id === this.selectedId) {
        return this.layers[i];
      }
    }
    return null;
  }

  private canConfirm(): boolean {
    return validateTextContent(this.inputContent).valid && (this.layers.length < 8 || this.selectedId !== '');
  }

  private inputValidationMessage(): string {
    if (this.validationMessage !== '') {
      return this.validationMessage;
    }
    if (this.layers.length >= 8 && this.selectedId === '') {
      return '最多添加 8 个题签，请选择已有题签编辑或删除';
    }
    if (this.inputContent.length === 0) {
      return '';
    }
    const validation = validateTextContent(this.inputContent);
    return validation.valid ? '' : validation.error;
  }

  private argbToHex(argb: number): string {
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    const hex = (value: number): string => {
      const text = value.toString(16);
      return text.length < 2 ? '0' + text : text;
    };
    return '#' + hex(r) + hex(g) + hex(b);
  }

  private fontFamily(fontKey: string): string {
    const entry = findFontEntry(resolveFontKey(fontKey, this.unavailableFontKeys));
    return entry === null ? Theme.FONT_SANS : entry.family;
  }
}
