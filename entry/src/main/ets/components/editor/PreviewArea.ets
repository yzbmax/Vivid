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
import { HapticService } from '../../services/HapticService';

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
  @Link originalPixelMap: image.PixelMap | undefined;
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

  /** 底层原图 PixelMap（双图模式，使用 @Link 直传原生句柄）。 */
  @Link baseImage: image.PixelMap | undefined;
  /** 上层前景图 PixelMap（透明背景，双图模式，使用 @Link 直传原生句柄）。 */
  @Link foregroundImage: image.PixelMap | undefined;
  /** 主体颜色矩阵（4x5 = 20 个数字）。 */
  @Prop subjectFilter: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  /** 背景颜色矩阵（4x5 = 20 个数字）。 */
  @Prop baseFilter: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  /** 是否处于主体/背景区域调色模式。 */
  @Prop isRegionMode: boolean = false;
  /** 纯净去底抠图预览模式。 */
  @Prop isolateSubject: boolean = false;

  /** 贴纸列表。 */
  @Prop stickers: StickerItem[] = [];
  /** 自定义贴纸模板列表。 */
  @Prop customTemplates: StickerTemplate[] = [];
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
  /** 删除贴纸。 */
  onStickerDelete: (instanceId: string) => void = () => {};
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
      if (this.previewLoading && this.foregroundImage === undefined && this.baseImage === undefined && this.previewPixelMap === undefined) {
        Text('正在显影…')
          .fontFamily(Theme.FONT_SERIF)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .align(Alignment.Center)
      } else if (hasRenderablePreview(this.imageSrc, this.previewPixelMap !== undefined || this.baseImage !== undefined)) {
        Stack({ alignContent: Alignment.TopStart }) {
          if (!this.isComparing && this.borderState.templateId === 'watermark_blur_pip') {
            this.blurredBackgroundLayer()
          }
          if (!this.isComparing && this.borderState.templateId === 'watermark_harmonic_editorial') {
            this.harmonicBackgroundLayer()
          }
          if (!this.isComparing) {
            BorderPreviewLayer({ borderState: this.borderState, geometry: this.layout().geometry })
          }
          Stack({ alignContent: Alignment.Center }) {
            this.photoLayers()
            if (!this.isComparing) {
              ForEach(this.stickers, (item: StickerItem, index: number) => {
                // 从响应式数组读取最新值，不让 Builder 闭包停留在首次创建的图层对象
                StickerLayer({
                  item: this.stickerAt(index, item),
                  template: this.findTpl(this.stickerAt(index, item).templateId),
                  isSelected: this.stickerMode && this.selectedStickerId === this.stickerAt(index, item).instanceId,
                  active: this.stickerMode,
                  onUpdate: this.onStickerUpdate,
                  onSelect: this.onStickerSelect,
                  onDelete: this.onStickerDelete
                })
                  .zIndex(index + 10)
              }, (item: StickerItem): string => `${item.instanceId}_${item.posX}_${item.posY}_${item.size}_${item.rotation}_${item.opacity}`)
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
              Row() {
                Text('原图')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ON_PRIMARY)
                  .letterSpacing(1.5)
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(Theme.SEAL_RED)
              .borderRadius(Theme.RADIUS_DEFAULT)
              .border({ width: 1, color: Theme.ON_PRIMARY })
              .shadow({ radius: 6, color: 'rgba(123, 23, 27, 0.4)', offsetY: 2 })
              .hitTestBehavior(HitTestMode.None)
            }
          }
          .width(this.layout().photoRect.width)
          .height(this.layout().photoRect.height)
          .position({ x: this.layout().photoRect.x - this.layout().outputRect.x,
            y: this.layout().photoRect.y - this.layout().outputRect.y })
          .borderRadius(this.photoCornerRadius())
          .clip(true)

          if (!this.isComparing && (
            this.borderState.templateId === 'watermark_centered_specs' ||
            this.borderState.templateId === 'watermark_minimal_keyvalue' ||
            this.borderState.templateId === 'watermark_overlay'
          )) {
            BorderPreviewLayer({ borderState: this.borderState, geometry: this.layout().geometry })
          }
        }
        .width(this.layout().outputRect.width)
        .height(this.layout().outputRect.height)
        .position({ x: this.layout().outputRect.x, y: this.layout().outputRect.y })
        .clip(true)
        .shadow({ radius: 10, color: 'rgba(36, 25, 24, 0.12)', offsetY: 3 })
        .id(PREVIEW_STACK_ID)
        .onClick((): void => {
          if (this.selectedStickerId !== '') {
            this.onStickerSelect('');
          }
          if (this.selectedTextLayerId !== '') {
            this.onTextSelect('');
          }
        })

        // 浮动对比按钮（长按即显原图，移至右下角大拇指黄金触控区）
        this.compareFloatingButton()
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
  }

  @Builder
  private compareFloatingButton() {
    Row({ space: 5 }) {
      Image($r('app.media.icon_compare'))
        .width(14)
        .height(14)
        .objectFit(ImageFit.Contain)
        .fillColor(this.isComparing ? Theme.ON_PRIMARY : Theme.PRIMARY)
      Text('对比')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isComparing ? Theme.ON_PRIMARY : Theme.PRIMARY)
    }
    .padding({ left: 12, right: 14, top: 7, bottom: 7 })
    .backgroundColor(this.isComparing ? Theme.PRIMARY : Theme.PAPER_SURFACE_80)
    .borderRadius(16)
    .border({ width: 1, color: this.isComparing ? Theme.PRIMARY : Theme.OUTLINE_VARIANT })
    .shadow({ radius: 8, color: 'rgba(36, 25, 24, 0.15)', offsetY: 2 })
    .position({ x: '100%', y: '100%' })
    .markAnchor({ x: '100%', y: '100%' })
    .offset({ x: -16, y: -16 })
    .responseRegion({ x: -20, y: -20, width: '180%', height: '180%' })
    .hitTestBehavior(HitTestMode.Block)
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        HapticService.triggerTick();
        this.onCompareChange(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onCompareChange(false);
      }
    })
  }

  @Builder
  private photoLayers() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 底层：原始图像（常驻底层，支持三级兜底：originalPixelMap > baseImage > imageSrc） ──
      // 即使在切换模式或手指长按瞬间，底层原图也始终在内存渲染管线中准备就绪，杜绝切换白屏与黑屏
      if (this.isComparing || !(this.isRegionMode && this.isolateSubject)) {
        if (this.originalPixelMap !== undefined) {
          Image(this.originalPixelMap)
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        } else if (this.baseImage !== undefined) {
          Image(this.baseImage)
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        } else {
          Image(this.resolvedImageSrc())
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        }
      }

      // ── 顶层：调色/滤镜结果层（非对比状态覆盖显示；长按对比时隐藏露出底层原图） ──
      if (!this.isComparing) {
        if (this.isRegionMode) {
          if (this.baseImage !== undefined && this.foregroundImage !== undefined) {
            if (!this.isolateSubject) {
              Image(this.baseImage)
                .width('100%').height('100%').objectFit(ImageFit.Contain)
                .colorFilter(this.baseFilter)
                .syncLoad(true)
                .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
            } else {
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
            }
            Image(this.foregroundImage)
              .width('100%').height('100%').objectFit(ImageFit.Contain)
              .colorFilter(this.subjectFilter)
              .syncLoad(true)
          } else if (this.baseImage !== undefined) {
            // 区域调色模式下，前景图尚未生成或无主体时展示 baseImage 并应用 baseFilter 杜绝白屏
            Image(this.baseImage)
              .width('100%').height('100%').objectFit(ImageFit.Contain)
              .colorFilter(this.baseFilter)
              .syncLoad(true)
              .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
          } else if (this.previewPixelMap !== undefined) {
            Image(this.previewPixelMap)
              .width('100%').height('100%').objectFit(ImageFit.Contain)
              .colorFilter(this.baseFilter)
              .syncLoad(true)
              .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
          } else {
            Image(this.resolvedImageSrc())
              .width('100%').height('100%').objectFit(ImageFit.Contain)
              .colorFilter(this.baseFilter)
              .syncLoad(true)
              .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
          }
        } else if (this.previewPixelMap !== undefined) {
          Image(this.previewPixelMap)
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .colorFilter(this.effects())
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        } else if (this.baseImage !== undefined) {
          Image(this.baseImage)
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .colorFilter(this.effects())
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        } else {
          Image(this.resolvedImageSrc())
            .width('100%').height('100%').objectFit(ImageFit.Contain)
            .colorFilter(this.effects())
            .syncLoad(true)
            .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
        }
      }
    }
    .width('100%')
    .height('100%')
    .onClick((): void => {
      if (this.selectedStickerId !== '') {
        this.onStickerSelect('');
      }
      if (this.selectedTextLayerId !== '') {
        this.onTextSelect('');
      }
    })
  }

  @Builder
  private blurredBackgroundLayer() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.previewPixelMap !== undefined) {
        Image(this.previewPixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(32)
          .colorFilter(this.effects())
          .syncLoad(true)
      } else if (this.baseImage !== undefined) {
        Image(this.baseImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(32)
          .colorFilter(this.isRegionMode ? this.baseFilter : this.effects())
          .syncLoad(true)
      } else if (this.imageSrc) {
        Image(this.resolvedImageSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(32)
          .colorFilter(this.isRegionMode ? this.baseFilter : this.effects())
          .syncLoad(true)
      }
      // 适度半透明暗化罩层，保证白字铭牌与中心主图有清晰对比，同时与原图色调完全一致
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.28)')
    }
    .width(this.layout().outputRect.width)
    .height(this.layout().outputRect.height)
    .position({ x: 0, y: 0 })
    .clip(true)
  }

  @Builder
  private harmonicBackgroundLayer() {
    Stack() {
      if (this.previewPixelMap) {
        Image(this.previewPixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(64)
          .colorFilter(this.effects())
          .syncLoad(true)
      } else if (this.baseImage !== undefined) {
        Image(this.baseImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(64)
          .colorFilter(this.isRegionMode ? this.baseFilter : this.effects())
          .syncLoad(true)
      } else if (this.imageSrc) {
        Image(this.resolvedImageSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(64)
          .colorFilter(this.isRegionMode ? this.baseFilter : this.effects())
          .syncLoad(true)
      }
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.18)')
    }
    .width(this.layout().outputRect.width)
    .height(this.layout().outputRect.height)
    .position({ x: 0, y: 0 })
    .clip(true)
  }

  private cachedLayout: EditorPreviewLayout | null = null;
  private cachedContainerW: number = -1;
  private cachedContainerH: number = -1;
  private cachedPhotoW: number = -1;
  private cachedPhotoH: number = -1;
  private cachedBorderTemplateId: string = '';
  private cachedBorderWidthRatio: number = -1;
  private cachedBorderRadiusRatio: number = -1;

  private photoCornerRadius(): number {
    const currentLayout = this.layout();
    const geom = currentLayout.geometry;
    if (!geom || geom.cornerRadius <= 0 || geom.photoRect.width <= 0) {
      return 0;
    }
    const scale = currentLayout.photoRect.width / geom.photoRect.width;
    return Math.round(geom.cornerRadius * scale);
  }

  private layout(): EditorPreviewLayout {
    const effectiveW = this.photoWidth > 0 ? this.photoWidth : this.imageNaturalW;
    const effectiveH = this.photoHeight > 0 ? this.photoHeight : this.imageNaturalH;
    const radiusRatio = this.borderState.radiusRatio ?? 0;

    if (
      this.cachedLayout !== null &&
      this.cachedContainerW === this.containerW &&
      this.cachedContainerH === this.containerH &&
      this.cachedPhotoW === effectiveW &&
      this.cachedPhotoH === effectiveH &&
      this.cachedBorderTemplateId === this.borderState.templateId &&
      this.cachedBorderWidthRatio === this.borderState.widthRatio &&
      this.cachedBorderRadiusRatio === radiusRatio
    ) {
      return this.cachedLayout;
    }

    this.cachedContainerW = this.containerW;
    this.cachedContainerH = this.containerH;
    this.cachedPhotoW = effectiveW;
    this.cachedPhotoH = effectiveH;
    this.cachedBorderTemplateId = this.borderState.templateId;
    this.cachedBorderWidthRatio = this.borderState.widthRatio;
    this.cachedBorderRadiusRatio = radiusRatio;

    this.cachedLayout = resolveEditorPreviewLayout(
      this.containerW,
      this.containerH,
      effectiveW,
      effectiveH,
      this.borderState
    );
    return this.cachedLayout;
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
      this.params.temperature,
      this.params.brightness
    );
  }

  /** 安全读取响应式贴纸数组中的最新项，防止 Builder 闭包持有初始创建时的陈旧对象。 */
  private stickerAt(index: number, fallback: StickerItem): StickerItem {
    if (index >= 0 && index < this.stickers.length) {
      return this.stickers[index];
    }
    return fallback;
  }

  /** 根据 templateId 查找贴纸模板。 */
  private findTpl(templateId: string): StickerTemplate | null {
    for (let i = 0; i < this.customTemplates.length; i++) {
      if (this.customTemplates[i].id === templateId) {
        return this.customTemplates[i];
      }
    }
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

  private resolvedImageSrc(): string {
    if (this.imageSrc.startsWith('/') && !this.imageSrc.startsWith('file://')) {
      return `file://${this.imageSrc}`;
    }
    return this.imageSrc;
  }
}
