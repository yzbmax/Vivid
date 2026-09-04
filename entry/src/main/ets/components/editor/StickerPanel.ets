import {
  StickerCategory,
  StickerCategoryDef,
  StickerItem,
  StickerTemplate,
  StickerRenderType,
  STICKER_CATEGORIES,
  STICKER_MAX_COUNT,
  filterTemplatesByCategory,
  findStickerTemplate
} from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 贴纸面板（「贴纸」工具内容）：
 * - 分类 Tab（闲章/角花/签条/吉祥）
 * - 贴纸网格（横向滚动）
 * - 选中贴纸的参数控制（大小/旋转/透明度 + 删除）
 */
@Component
export struct StickerPanel {
  @Prop stickers: StickerItem[] = [];
  @Prop selectedId: string = '';
  @Prop allTemplates: StickerTemplate[] = [];
  @Prop customTemplates: StickerTemplate[] = [];

  onAddSticker: (templateId: string, customUri?: string) => void = () => {};
  onUploadCustomSticker: () => void = () => {};
  onSelectSticker: (instanceId: string) => void = () => {};
  onUpdateSticker: (instanceId: string, size: number, rotation: number, opacity: number) => void = () => {};
  onRemoveSticker: (instanceId: string) => void = () => {};
  /** 滑块直接回调（立即更新 @Provide 值，驱动 StickerLayer @Consume）。 */
  notifySizeChange: (value: number) => void = () => {};
  notifyRotationChange: (value: number) => void = () => {};
  notifyOpacityChange: (value: number) => void = () => {};

  /** 当前选中的分类 Tab。 */
  @State activeCategory: StickerCategory = 'seal';

  build() {
    Column() {
      // ── 上行：分类 Tab ──
      Row() {
        ForEach(STICKER_CATEGORIES, (cat: StickerCategoryDef) => {
          this.categoryChip(cat)
        }, (cat: StickerCategoryDef) => cat.key)
      }
      .width('100%')
      .height(48)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .alignItems(VerticalAlign.Center)

      // ── 中行：贴纸网格（横向滚动，固定高度）──
      Scroll() {
        Row({ space: 12 }) {
          if (this.activeCategory === 'custom') {
            this.uploadCustomCard()
          }
          ForEach(this.filteredTemplates(), (tpl: StickerTemplate) => {
            this.stickerPreview(tpl)
          }, (tpl: StickerTemplate) => tpl.id)
        }
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 4, bottom: 4 })
      }
      .width('100%')
      .height(72)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // ── 下行：选中贴纸参数（无选中时显示贴纸计数提示）──
      if (this.selectedId !== '' && this.selectedSticker() !== null) {
        this.selectedParams()
      } else {
        this.emptyHint()
      }
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
  }

  /** 分类 chip。 */
  @Builder
  categoryChip(cat: StickerCategoryDef) {
    Column({ space: 2 }) {
      Text(cat.label)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontWeight(this.activeCategory === cat.key ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeCategory === cat.key ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .border({ width: { bottom: this.activeCategory === cat.key ? 3 : 0 }, color: Theme.SEAL_RED })
    .onClick(() => {
      this.activeCategory = cat.key;
    })
  }

  /** 上传自定义贴纸卡片。 */
  @Builder
  uploadCustomCard() {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text('＋')
          .fontSize(22)
          .fontColor(Theme.SEAL_RED)
          .fontWeight(FontWeight.Bold)
      }
      .width(44)
      .height(44)
      .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
      .border({ width: 1, color: Theme.SEAL_RED, style: BorderStyle.Dashed })
      .borderRadius(Theme.RADIUS_LG)

      Text('上传')
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(Theme.SEAL_RED)
        .maxLines(1)
    }
    .width(52)
    .onClick(() => {
      this.onUploadCustomSticker();
    })
  }

  /** 单个贴纸预览（可点击添加）。 */
  @Builder
  stickerPreview(tpl: StickerTemplate) {
    Column({ space: 2 }) {
      // 预览区
      Stack({ alignContent: Alignment.Center }) {
        if (tpl.renderType === StickerRenderType.SealStamp) {
          Stack({ alignContent: Alignment.Center }) {
            Text(tpl.textContent)
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ON_PRIMARY)
          }
          .width(32)
          .height(32)
          .backgroundColor(Theme.SEAL_RED)
          .borderRadius(2)
          .shadow({ radius: 3, color: Theme.SHADOW_SM, offsetY: 1 })
        } else if (tpl.renderType === StickerRenderType.LabelStrip) {
          Column() {
            Text(tpl.textContent)
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.ON_SURFACE)
              .letterSpacing(1)
          }
          .width(36)
          .height(18)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Theme.PAPER_SURFACE)
          .border({ width: 1, color: Theme.OUTLINE_VARIANT })
          .shadow({ radius: 2, color: Theme.SHADOW_SM, offsetY: 1 })
        } else if (tpl.renderType === StickerRenderType.CustomImage || (tpl.customUri !== undefined && tpl.customUri !== '')) {
          if (tpl.customUri !== undefined && tpl.customUri !== '') {
            Image(tpl.customUri)
              .width(34)
              .height(34)
              .objectFit(ImageFit.Contain)
          }
        } else {
          if (tpl.resource !== null) {
            Image(tpl.resource)
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
          }
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
      .border({ width: 1, color: Theme.OUTLINE_VARIANT })
      .borderRadius(Theme.RADIUS_LG)

      // 名称
      Text(tpl.name)
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(52)
    .onClick(() => {
      if (this.stickers.length >= STICKER_MAX_COUNT) {
        return;
      }
      this.onAddSticker(tpl.id, tpl.customUri);
    })
  }

  /** 选中贴纸的参数控制区。 */
  @Builder
  selectedParams() {
    Column({ space: 4 }) {
      // 参数行
      Row({ space: 12 }) {
        // 大小滑块
        Column({ space: 2 }) {
          Row() {
            Text('大小')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Blank()
            Text(this.selectedSizeText())
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
          }
          .width('100%')

          Slider({
            value: this.selectedStickerSize(),
            min: 20,
            max: 300,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockStyle({
              type: SliderBlockType.SHAPE,
              shape: new Rect({ width: 14, height: 14, radius: 2 }).fill(Theme.SEAL_RED)
            })
            .blockSize({ width: 14, height: 14 })
            .blockColor(Theme.SEAL_RED)
            .selectedColor(Theme.SEAL_RED)
            .trackColor(Theme.OUTLINE_VARIANT)
            .trackThickness(2)
            .width('100%')
            .onChange((value: number) => {
              this.notifySizeChange(value);
            })
        }
        .layoutWeight(1)

        // 旋转滑块
        Column({ space: 2 }) {
          Row() {
            Text('旋转')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Blank()
            Text(this.selectedRotationText())
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
          }
          .width('100%')

          Slider({
            value: this.selectedStickerRotation(),
            min: -180,
            max: 180,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockStyle({
              type: SliderBlockType.SHAPE,
              shape: new Rect({ width: 14, height: 14, radius: 2 }).fill(Theme.SEAL_RED)
            })
            .blockSize({ width: 14, height: 14 })
            .blockColor(Theme.SEAL_RED)
            .selectedColor(Theme.SEAL_RED)
            .trackColor(Theme.OUTLINE_VARIANT)
            .trackThickness(2)
            .width('100%')
            .onChange((value: number) => {
              this.notifyRotationChange(value);
            })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 透明度 + 操作按钮行
      Row({ space: 12 }) {
        // 透明度滑块
        Column({ space: 2 }) {
          Row() {
            Text('透明')
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Blank()
            Text(this.selectedOpacityText())
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
          }
          .width('100%')

          Slider({
            value: this.selectedStickerOpacity() * 100,
            min: 30,
            max: 100,
            step: 1,
            style: SliderStyle.OutSet
          })
            .blockStyle({
              type: SliderBlockType.SHAPE,
              shape: new Rect({ width: 14, height: 14, radius: 2 }).fill(Theme.SEAL_RED)
            })
            .blockSize({ width: 14, height: 14 })
            .blockColor(Theme.SEAL_RED)
            .selectedColor(Theme.SEAL_RED)
            .trackColor(Theme.OUTLINE_VARIANT)
            .trackThickness(2)
            .width('100%')
            .onChange((value: number) => {
              this.notifyOpacityChange(value / 100);
            })
        }
        .layoutWeight(1)

        // 删除按钮
        Row() {
          Text('删除')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.ERROR)
        }
        .width(44)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .border({ width: 1, color: Theme.ERROR_CONTAINER })
        .borderRadius(Theme.RADIUS_DEFAULT)
        .onClick(() => {
          if (this.selectedId !== '') {
            this.onRemoveSticker(this.selectedId);
          }
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 4, bottom: 4 })
  }

  /** 空状态提示。 */
  @Builder
  emptyHint() {
    Row() {
      Text(this.stickers.length >= STICKER_MAX_COUNT ? '贴纸已满（上限 12 枚）' : '点击上方贴纸添加到画面')
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(Theme.ON_SURFACE_VARIANT_70)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
  }

  // ── 辅助方法 ──

  private filteredTemplates(): StickerTemplate[] {
    if (this.activeCategory === 'custom') {
      return this.customTemplates;
    }
    return filterTemplatesByCategory(this.activeCategory);
  }

  private selectedSticker(): StickerItem | null {
    if (this.selectedId === '') {
      return null;
    }
    for (let i = 0; i < this.stickers.length; i++) {
      if (this.stickers[i].instanceId === this.selectedId) {
        return this.stickers[i];
      }
    }
    return null;
  }

  private selectedStickerSize(): number {
    const sel = this.selectedSticker();
    return sel !== null ? sel.size : 48;
  }

  private selectedStickerRotation(): number {
    const sel = this.selectedSticker();
    return sel !== null ? sel.rotation : 0;
  }

  private selectedStickerOpacity(): number {
    const sel = this.selectedSticker();
    return sel !== null ? sel.opacity : 1.0;
  }

  private selectedSizeText(): string {
    const v = this.selectedStickerSize();
    return v < 10 ? '0' + v.toString() + 'vp' : v.toString() + 'vp';
  }

  private selectedRotationText(): string {
    const v = this.selectedStickerRotation();
    const prefix = v >= 0 ? '+' : '';
    return prefix + v.toString() + 'deg';
  }

  private selectedOpacityText(): string {
    const v = Math.round(this.selectedStickerOpacity() * 100);
    return v.toString() + '%';
  }
}
