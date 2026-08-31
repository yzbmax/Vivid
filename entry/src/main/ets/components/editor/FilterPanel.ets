import { image } from '@kit.ImageKit';
import { FILTER_PRESETS } from '../../features/editor/filter/FilterCatalog';
import { EditState } from '../../features/editor/filter/FilterState';
import { FilterPreset } from '../../features/editor/filter/FilterModels';
import { Theme } from '../common/Theme';
import {
  ThumbnailItem,
  canUseSourceThumbnailFallback
} from '../../services/ThumbnailPipeline';

/** Filter selection strip and non-destructive strength control. */
@Component
export struct FilterPanel {
  @Prop editState: EditState = { filter: { filterId: 'original', strength: 0 } };
  @Link previewPixelMap: image.PixelMap | undefined;
  @Link thumbnails: ThumbnailItem[];
  onSelectFilter: (filterId: string) => void = () => {};
  onStrengthChange: (value: number) => void = () => {};

  build() {
    Column({ space: 8 }) {
      Scroll() {
        Row({ space: 10 }) {
          ForEach(FILTER_PRESETS, (preset: FilterPreset) => {
            this.filterCard(preset)
          }, (preset: FilterPreset) => preset.id)
        }
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(108)

      Row({ space: 10 }) {
        Text('强度')
          .fontFamily(Theme.FONT_SANS)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(Theme.ON_SURFACE_VARIANT)
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
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode !== SliderChangeMode.Begin) {
              this.onStrengthChange(value);
            }
          })
        Text(`${Math.round(this.editState.filter.strength * 100)}`)
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO)
          .fontColor(Theme.PRIMARY)
          .width(32)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(40)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      .visibility(this.editState.filter.filterId === 'original' ? Visibility.Hidden : Visibility.Visible)
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  filterCard(preset: FilterPreset) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.thumbnailFor(preset.id) !== undefined) {
          Image(this.thumbnailFor(preset.id))
            .width(64)
            .height(64)
            .objectFit(ImageFit.Cover)
        } else if (canUseSourceThumbnailFallback(preset.id) && this.previewPixelMap !== undefined) {
          Image(this.previewPixelMap)
            .width(64)
            .height(64)
            .objectFit(ImageFit.Cover)
        } else {
          Column()
            .width(64)
            .height(64)
            .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
        }
        if (this.editState.filter.filterId === preset.id) {
          Column()
            .width(64)
            .height(64)
            .border({ width: 2, color: Theme.SEAL_RED })
        }
      }
      Text(preset.name)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(this.editState.filter.filterId === preset.id ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
        .fontWeight(this.editState.filter.filterId === preset.id ? FontWeight.Bold : FontWeight.Normal)
        .maxLines(1)
    }
    .width(72)
    .height(92)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onSelectFilter(preset.id))
  }

  private thumbnailFor(filterId: string): image.PixelMap | undefined {
    for (let i = 0; i < this.thumbnails.length; i++) {
      if (this.thumbnails[i].filterId === filterId) {
        return this.thumbnails[i].pixelMap;
      }
    }
    return undefined;
  }
}
