import { image } from '@kit.ImageKit';
import { FILTER_PRESETS } from '../../features/editor/filter/FilterCatalog';
import { EditState } from '../../features/editor/filter/FilterState';
import { FilterPreset } from '../../features/editor/filter/FilterModels';
import { Theme } from '../common/Theme';
import {
  ThumbnailItem,
  canUseSourceThumbnailFallback
} from '../../services/ThumbnailPipeline';
import { HapticService } from '../../services/HapticService';

/** Filter selection strip and non-destructive strength control. */
@Component
export struct FilterPanel {
  @Prop editState: EditState = { filter: { filterId: 'original', strength: 0 } };
  @Link previewPixelMap: image.PixelMap | undefined;
  @Link thumbnails: ThumbnailItem[];
  @Prop unavailableFilterIds: string[] = [];
  onSelectFilter: (filterId: string) => void = () => {};
  onStrengthChange: (value: number) => void = () => {};
  onSlidingComplete: () => void = () => {};

  private resetStrength(): void {
    HapticService.triggerImpact();
    this.onStrengthChange(1.0);
    this.onSlidingComplete();
  }

  build() {
    Column({ space: 4 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.visiblePresets(), (preset: FilterPreset, index: number) => {
            this.filterCard(preset, index);
          }, (preset: FilterPreset) => preset.id)
        }
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .width('100%')
      .height(120)

      Row({ space: 8 }) {
        Row({ space: 4 }) {
          Text('浓度')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
          Text('[STR]')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(9)
            .fontColor(Theme.OUTLINE)
        }
        .gesture(
          TapGesture({ count: 2 })
            .onAction((): void => this.resetStrength())
        )

        Slider({
          value: this.editState.filter.strength,
          min: 0,
          max: 1,
          step: 0.01,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .blockColor(Theme.SEAL_RED)
          .selectedColor(Theme.SEAL_RED)
          .trackColor(Theme.OUTLINE_VARIANT)
          .onChange((value: number, mode: SliderChangeMode): void => {
            if (mode !== SliderChangeMode.Begin) {
              this.onStrengthChange(value);
            }
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
              this.onSlidingComplete();
            }
          })

        Text(`${Math.round(this.editState.filter.strength * 100)}%`)
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.PRIMARY)
          .width(42)
          .textAlign(TextAlign.End)
          .gesture(
            TapGesture({ count: 2 })
              .onAction((): void => this.resetStrength())
          )
      }
      .width('100%')
      .height(32)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .visibility(this.editState.filter.filterId === 'original' ? Visibility.Hidden : Visibility.Visible)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  filterCard(preset: FilterPreset, index: number) {
    Column({ space: 3 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.thumbnailFor(preset.id) !== undefined) {
          Image(this.thumbnailFor(preset.id))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else if (canUseSourceThumbnailFallback(preset.id) && this.previewPixelMap !== undefined) {
          Image(this.previewPixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          Text('显影中')
            .fontFamily(Theme.FONT_MONO)
            .fontSize(10)
            .fontColor(Theme.ON_SURFACE_VARIANT)
        }

        // 微缩印章：右上角阳文方印，未选态为淡墨细框，选中态为朱砂实心底+白字
        Text(preset.name.length > 0 ? preset.name.charAt(0) : '印')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.editState.filter.filterId === preset.id ? Theme.ON_PRIMARY : Theme.OUTLINE)
          .width(16)
          .height(16)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.editState.filter.filterId === preset.id ? Theme.SEAL_RED : Theme.PAPER_SURFACE_80)
          .borderRadius(2)
          .border({
            width: 1,
            color: this.editState.filter.filterId === preset.id ? Theme.SEAL_RED : 'rgba(139, 113, 111, 0.35)'
          })
          .position({ x: '100%', y: 3 })
          .markAnchor({ x: '100%', y: 0 })
          .margin({ right: 3 })

        // 选中高亮内框
        if (this.editState.filter.filterId === preset.id) {
          Column()
            .width('100%')
            .height('100%')
            .border({ width: 1.5, color: Theme.SEAL_RED })
            .borderRadius(Theme.RADIUS_DEFAULT)
        }
      }
      .width(76)
      .height(60)
      .backgroundColor(Theme.SURFACE_CONTAINER_LOW)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .clip(true)

      // 预设名称（文书典藏感）
      Text(preset.name)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(12)
        .fontWeight(this.editState.filter.filterId === preset.id ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.editState.filter.filterId === preset.id ? Theme.PRIMARY : Theme.ON_SURFACE)
        .maxLines(1)

      // 文书等宽编号标注
      Text(this.formatIndex(index))
        .fontFamily(Theme.FONT_MONO)
        .fontSize(9)
        .fontColor(this.editState.filter.filterId === preset.id ? Theme.SEAL_RED : Theme.ON_SURFACE_VARIANT_70)
        .maxLines(1)
    }
    .width(84)
    .height(116)
    .backgroundColor(Theme.PAPER_SURFACE)
    .borderRadius(Theme.RADIUS_DEFAULT)
    .border({
      width: this.editState.filter.filterId === preset.id ? 1.5 : 1,
      color: this.editState.filter.filterId === preset.id ? Theme.SEAL_RED : Theme.OUTLINE_VARIANT
    })
    .shadow(this.editState.filter.filterId === preset.id ? {
      radius: 4,
      color: 'rgba(178, 59, 47, 0.22)',
      offsetY: 1
    } : {
      radius: 2,
      color: Theme.SHADOW_SM,
      offsetY: 1
    })
    .scale(this.editState.filter.filterId === preset.id ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .padding({ top: 4, bottom: 4, left: 3, right: 3 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick((): void => {
      if (this.editState.filter.filterId !== preset.id) {
        HapticService.triggerTick();
      }
      this.onSelectFilter(preset.id);
    })
  }

  private formatIndex(index: number): string {
    return `NO.${index < 10 ? '0' : ''}${index}`;
  }

  private thumbnailFor(filterId: string): image.PixelMap | undefined {
    for (let i = 0; i < this.thumbnails.length; i++) {
      if (this.thumbnails[i].filterId === filterId) {
        return this.thumbnails[i].pixelMap;
      }
    }
    return undefined;
  }

  private visiblePresets(): FilterPreset[] {
    return FILTER_PRESETS.filter((preset: FilterPreset) => !this.unavailableFilterIds.includes(preset.id));
  }
}
