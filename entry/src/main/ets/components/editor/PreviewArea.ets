import {
  AdjustParams,
  StickerItem, StickerTemplate, findStickerTemplate
} from '../../models/EditModels';
import { Theme } from '../common/Theme';
import { image } from '@kit.ImageKit';
import { StickerLayer } from './StickerLayer';
import { hasRenderablePreview } from '../../services/PreviewPipeline';
import { BorderState, defaultBorderState, TextLayer as TextLayerModel } from '../../models/SharedContracts';
import { EditorPreviewLayout, resolveEditorPreviewLayout } from '../../features/editor/preview/EditorPreviewLayout';
import { BorderPreviewLayer } from './BorderPreviewLayer';
// ===== A: Text Layer =====
import { TextLayer as TextLayerOverlay } from './TextLayer';
// ===== End A =====
import { buildAdjustmentFilter } from '../../utils/ColorMatrixUtils';

/**
 * 预览区：双图叠放 + colorFilter 调色。
 *
 * 架构迁移（2026-08-26）：从 Worker 渲染管线迁移到双图 colorFilter 方案。
 * 底层 Image 显示原图（背景），上层 Image 显示透明背景前景图（主体）。
 * 各自独立应用 .colorFilter() 实现主体/背景独立调色。
 *
 * 模式：
 * - 分割完成（foregroundImage 存在）：双图 colorFilter 模式
 * - 未分割但有 imageSrc：CSS 效果模式（全局调色）
 * - 无图片：占位
 *
 * 原图对比（isComparing=true）时隐藏全部效果，显示原图。
 *
 * 导出用 id：PREVIEW_STACK_ID，供 componentSnapshot 捕获。
 */

/** componentSnapshot 捕获用的组件 id。 */
export const PREVIEW_STACK_ID: string = 'previewStack';

@Component
export struct PreviewArea {
  /** 原图 URI（CSS 效果模式 / 未分割时使用）。 */
  @Prop imageSrc: string = '';
  @Link previewPixelMap: image.PixelMap | undefined;
  @Prop previewLoading: boolean = false;
  @Prop originalPixelMap: image.PixelMap | undefined = undefined;
  @Prop @Watch('notifyDisplaySize') photoWidth: number = 0;
  @Prop @Watch('notifyDisplaySize') photoHeight: number = 0;
  @Prop @Watch('notifyDisplaySize') borderState: BorderState = defaultBorderState();
  // ===== A: Text Layer =====
  @Prop textLayers: TextLayerModel[] = [];
  @Prop selectedTextLayerId: string = '';
  @Prop textMode: boolean = false;
  @Prop unavailableFontKeys: string[] = [];
  onTextSelect: (id: string) => void = () => {};
  onTextMove: (id: string, x: number, y: number) => void = () => {};
  // ===== End A =====
  /** 全局调色参数（CSS 效果模式使用）。 */
  @Prop params: AdjustParams = { exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 0 };
  /** 原图对比模式：true 时隐藏所有效果。 */
  @Prop isComparing: boolean = false;

  /** 底层原图 PixelMap（双图模式）。 */
  @Prop baseImage: image.PixelMap | undefined = undefined;
  /** 上层前景图 PixelMap（透明背景，双图模式）。 */
  @Prop foregroundImage: image.PixelMap | undefined = undefined;
  /** 主体颜色矩阵（4x5 = 20 个数字）。 */
  @Prop subjectFilter: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  /** 背景颜色矩阵（4x5 = 20 个数字）。 */
  @Prop baseFilter: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  /** 贴纸列表。 */
  @Prop stickers: StickerItem[] = [];
  /** 贴纸模式（禁用按住对比）。 */
  @Prop stickerMode: boolean = false;
  /** 当前选中的贴纸 id。 */
  @Prop selectedStickerId: string = '';
  /** 贴纸数据版本号（每次贴纸数据变化时递增，触发 StickerLayer @Watch）。 */
  @Prop stickerVersion: number = 0;

  onCompareChange: (down: boolean) => void = () => {};
  /** 图片加载完成后回传原始像素尺寸。 */
  onImageSizeChange: (w: number, h: number) => void = () => {};
  /** 选中贴纸。 */
  onStickerSelect: (instanceId: string) => void = () => {};
  /** 更新贴纸参数。 */
  onStickerUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => void = () => {};
  /** 回传预览区实际显示尺寸（vp），供贴纸定位使用。 */
  onDisplaySizeChange: (displayW: number, displayH: number) => void = () => {};

  /** 预览区域可用尺寸（由外层 Column onAreaChange 更新）。 */
  @State containerW: number = 0;
  @State containerH: number = 0;
  /** 图片原始像素尺寸（由 Image onComplete 回写）。 */
  @State imageNaturalW: number = 0;
  @State imageNaturalH: number = 0;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.previewLoading && this.foregroundImage === undefined) {
        Text('正在显影…')
          .fontFamily(Theme.FONT_SERIF)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .align(Alignment.Center)
      } else if (hasRenderablePreview(this.imageSrc, this.previewPixelMap !== undefined)) {
        Stack({ alignContent: Alignment.TopStart }) {
          if (!this.isComparing) {
            BorderPreviewLayer({ borderState: this.borderState, geometry: this.layout().geometry })
          }
          Stack({ alignContent: Alignment.Center }) {
            this.photoLayers()
            if (!this.isComparing) {
              ForEach(this.stickers, (item: StickerItem) => {
                StickerLayer({
                  item: item,
                  template: this.findTpl(item.templateId),
                  isSelected: this.selectedStickerId === item.instanceId,
                  onUpdate: this.onStickerUpdate,
                  onSelect: this.onStickerSelect
                })
              }, (item: StickerItem) => item.instanceId)
            }
            // ===== A: Text Layer =====
            TextLayerOverlay({
              layers: this.textLayers,
              selectedId: this.selectedTextLayerId,
              active: this.textMode,
              isComparing: this.isComparing,
              contentRect: { x: 0, y: 0, width: this.layout().photoRect.width, height: this.layout().photoRect.height },
              unavailableFontKeys: this.unavailableFontKeys,
              onSelect: this.onTextSelect,
              onMove: this.onTextMove
            })
            // ===== End A =====
            if (this.isComparing) {
              Text('原图')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(12)
                .fontColor(Theme.ON_PRIMARY)
                .backgroundColor(Theme.PRIMARY)
                .padding(6)
                .hitTestBehavior(HitTestMode.None)
            }
          }
          .width(this.layout().photoRect.width)
          .height(this.layout().photoRect.height)
          .position({ x: this.layout().photoRect.x - this.layout().outputRect.x,
            y: this.layout().photoRect.y - this.layout().outputRect.y })
          .clip(true)
        }
        .width(this.layout().outputRect.width)
        .height(this.layout().outputRect.height)
        .position({ x: this.layout().outputRect.x, y: this.layout().outputRect.y })
        .clip(true)
        .id(PREVIEW_STACK_ID)
      } else {
        Text('请选择图片或加载作品')
          .fontFamily(Theme.FONT_SERIF)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .align(Alignment.Center)
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.containerW = Number(newValue.width);
      this.containerH = Number(newValue.height);
      this.notifyDisplaySize();
    })
    .onTouch((event: TouchEvent) => {
      if (this.stickerMode || this.textMode || !hasRenderablePreview(this.imageSrc, this.previewPixelMap !== undefined)) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.onCompareChange(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onCompareChange(false);
      }
    })
  }

  @Builder
  private photoLayers() {
    if (this.baseImage !== undefined && this.foregroundImage !== undefined && !this.isComparing) {
      Image(this.baseImage)
        .width('100%').height('100%').objectFit(ImageFit.Contain)
        .colorFilter(this.baseFilter)
      Image(this.foregroundImage)
        .width('100%').height('100%').objectFit(ImageFit.Contain)
        .colorFilter(this.subjectFilter)
    } else if (this.isComparing && this.originalPixelMap !== undefined) {
      Image(this.originalPixelMap)
        .width('100%').height('100%').objectFit(ImageFit.Contain)
    } else if (this.previewPixelMap !== undefined) {
      Image(this.previewPixelMap)
        .width('100%').height('100%').objectFit(ImageFit.Contain)
        .colorFilter(this.effects())
    } else {
      Image(this.imageSrc)
        .width('100%').height('100%').objectFit(ImageFit.Contain)
        .colorFilter(this.effects())
        .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
    }
  }

  private layout(): EditorPreviewLayout {
    return resolveEditorPreviewLayout(this.containerW, this.containerH,
      this.photoWidth > 0 ? this.photoWidth : this.imageNaturalW,
      this.photoHeight > 0 ? this.photoHeight : this.imageNaturalH, this.borderState);
  }

  private notifyDisplaySize(): void {
    const photo = this.layout().photoRect;
    this.onDisplaySizeChange(photo.width, photo.height);
  }

  private effects(): number[] {
    if (this.isComparing) {
      return [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
    }
    return buildAdjustmentFilter(
      this.params.exposure,
      this.params.contrast,
      this.params.saturation,
      this.params.temperature
    );
  }

  /** 根据 templateId 查找贴纸模板。 */
  private findTpl(templateId: string): StickerTemplate | null {
    return findStickerTemplate(templateId);
  }

  private updateNaturalSize(width: number, height: number): void {
    if (width > 0 && height > 0 && (width !== this.imageNaturalW || height !== this.imageNaturalH)) {
      this.imageNaturalW = width;
      this.imageNaturalH = height;
      console.info(`Editor preview image ready: ${width}x${height}`);
      this.onImageSizeChange(width, height);
      this.notifyDisplaySize();
    }
  }
}
