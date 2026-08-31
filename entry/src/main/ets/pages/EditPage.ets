import {
  EDITOR_TOOLS,
  ADJUST_TYPES,
  REGION_ADJUST_TYPES,
  STICKER_TEMPLATES,
  STICKER_MAX_COUNT,
  AdjustParams,
  EditEntrySource,
  EditRouteParams,
  EditorToolKey,
  RegionKey,
  RegionAdjustments,
  StickerItem,
  RawEditRouteParams,
  SaveMode,
  buildDraftIntent,
  buildSaveIntent,
  createDefaultAdjustments,
  createDefaultRegionAdjustments,
  createStickerInstance,
  cloneAdjustments,
  cloneRegionAdjustments,
  editRouteError,
  parseEditRouteParams,
  resolveDisplayImageSource
} from '../models/EditModels';
import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PreviewArea } from '../components/editor/PreviewArea';
import { AdjustPanel } from '../components/editor/AdjustPanel';
import { StickerPanel } from '../components/editor/StickerPanel';
import { FilterPanel } from '../components/editor/FilterPanel';
import { EditorToolBar } from '../components/editor/EditorToolBar';
import { RegionTabs } from '../components/editor/RegionTabs';
import { common } from '@kit.AbilityKit';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { toExportProfile } from '../models/AppSettingsModels';
import { ImageRenderService } from '../services/ImageRenderService';
import { PhotoExportService } from '../services/PhotoExportService';
import { getSubjectSegmentationService } from '../services/SubjectSegmentationService';
import { WorkRecord } from '../models/WorkRecord';
import { mockWorkStore } from '../models/MockWorkStore';
import { WorkUiState } from '../models/WorkUiState';
import { generateWorkTitle } from '../models/WorkTitleGenerator';
import { generateWorkDescription } from '../models/WorkDescriptionGenerator';
import { decodeImageFromUri } from '../utils/ImageDecodeUtils';
import {
  AI_WORK_MAX_EDGE, SegmentationOutput,
  SegmentationStatus, segErrorToMessage
} from '../models/SegmentationModels';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buildAdjustmentFilter } from '../utils/ColorMatrixUtils';
import { PREVIEW_STACK_ID } from '../components/editor/PreviewArea';
import { EditState, createDefaultEditState } from '../features/editor/filter/FilterState';
import { FilterPreset } from '../features/editor/filter/FilterModels';
import { FILTER_PRESETS } from '../features/editor/filter/FilterCatalog';
import { FilterNativeBridge } from '../features/editor/filter/FilterNativeBridge';
import { FilterController } from '../features/editor/filter/FilterController';
import { OwnedRenderResult, PreviewPipeline } from '../services/PreviewPipeline';
import { ThumbnailItem, ThumbnailPipeline } from '../services/ThumbnailPipeline';

/**
 * 独立调色编辑页。
 *
 * 布局（自上而下）：
 *  1. 顶部导航区（~8-10%）：返回（左）| 标题 | 保存（右）。
 *  2. 中部预览区（~65-70%）：Contain 原比例不裁切，占满导航与面板之间。
 *  3. 中下部参数面板（~12-15%）：调节工具两行（重置/滑块/对比 + 调整类型选择）。
 *  4. 底部工具导航（~8-10%）：滤镜/主体/背景/调节/贴纸/文字/模板，高亮「调节」。
 *
 * 路由参数：source（picker/work）、imageUri（picker 时）、workId（work 时）、
 * initialTool（可选，快捷入口传入）。
 *
 * 保存当前为占位（仅按钮不保存）；B 的 WorkSaveService 交付后接入异步保存/草稿链路。
 * 编辑页为独立 @Entry 路由，不进入 Index 底部 Tab。
 */
@Entry
@Component
struct EditPage {
  @State route: EditRouteParams | null = null;
  @State errorText: string = '';
  @State imageSrc: string = '';
  @State displaySrc: string = '';
  @State params: AdjustParams = createDefaultAdjustments();
  @State editState: EditState = createDefaultEditState();
  @State isComparing: boolean = false;
  @State selectedType: string = 'exposure';
  @State activeTool: EditorToolKey = 'adjust';
  @State saving: boolean = false;
  @State dirty: boolean = false;
  @State imageWidth: number = 0;
  @State imageHeight: number = 0;
  // ── V2 区域调色状态 ──
  @State segStatus: SegmentationStatus = 'idle';
  @State segErrorMessage: string = '';
  @State activeRegion: RegionKey = 'subject';
  @State regionAdjustments: RegionAdjustments = createDefaultRegionAdjustments();
  // ── 架构迁移（2026-08-26）：双图 colorFilter 方案 ──
  @State baseImage: image.PixelMap | undefined = undefined;
  @State foregroundImage: image.PixelMap | undefined = undefined;
  // ── 贴纸状态 ──
  @State stickers: StickerItem[] = [];
  @State selectedStickerId: string = '';
  @State previewDisplayW: number = 0;
  @State previewDisplayH: number = 0;
  @State stickerVersion: number = 0;
  @Provide stickerTargetSize: number = -1;
  @Provide stickerTargetRotation: number = -999;
  @Provide stickerTargetOpacity: number = -1;
  // ── 滤镜系统状态 ──
  @State previewPixelMap: image.PixelMap | undefined = undefined;
  @State previewLoading: boolean = true;
  @State thumbnailItems: ThumbnailItem[] = [];
  private previewSourcePixelMap: image.PixelMap | undefined = undefined;
  private renderedPreviewOwner: OwnedRenderResult<image.PixelMap> =
    new OwnedRenderResult<image.PixelMap>((value: image.PixelMap) => value.release());
  private previewPipeline: PreviewPipeline = new PreviewPipeline();
  private thumbnailPipeline: ThumbnailPipeline = new ThumbnailPipeline();
  private loadedFilterIds: string[] = [];
  private filterController: FilterController = new FilterController();
  private disposed: boolean = false;
  private loadingThumbnails: boolean = false;
  // ── 私有字段（非 @State）──
  private decodedPixelMap: image.PixelMap | undefined = undefined;

  aboutToAppear(): void {
    this.disposed = false;
    this.previewLoading = true;
    const raw = this.getUIContext().getRouter().getParams() as RawEditRouteParams;
    const route = parseEditRouteParams(raw ?? {});
    this.route = route;
    this.errorText = editRouteError(route);
    this.params = createDefaultAdjustments();
    this.editState = this.filterController.resetForPhoto();
    if (route != null && route.source === EditEntrySource.Picker) {
      this.imageSrc = route.imageUri ?? '';
      this.displaySrc = resolveDisplayImageSource(this.imageSrc, route.displayUri);
    } else if (route != null && route.source === EditEntrySource.Work) {
      mockWorkStore.init();
      const work = mockWorkStore.findById(route.workId ?? '');
      if (work !== null) {
        this.imageSrc = work.sourceImageUri;
        this.displaySrc = this.imageSrc;
        this.params = {
          exposure: work.adjustments.exposure,
          brightness: work.adjustments.brightness,
          contrast: work.adjustments.contrast,
          saturation: work.adjustments.saturation,
          temperature: work.adjustments.temperature
        };
        if (work.regionAdjustments !== undefined) {
          this.regionAdjustments = cloneRegionAdjustments(work.regionAdjustments);
        }
      } else {
        this.errorText = '作品不存在';
      }
    }
    if (route?.initialTool !== undefined) {
      this.activeTool = route.initialTool;
    }
    if (this.activeTool === 'subject' || this.activeTool === 'background') {
      this.activeRegion = this.activeTool;
      this.selectedType = REGION_ADJUST_TYPES[0].key;
      setTimeout(() => {
        this.triggerSegmentation();
      }, 100);
    }
    this.loadPreviewSource();
  }

  aboutToDisappear(): void {
    this.disposed = true;
    this.releaseRenderedPreview();
    this.previewPipeline.dispose();
    this.thumbnailPipeline.clear();
    this.loadingThumbnails = false;
    this.previewLoading = false;
    this.previewSourcePixelMap = undefined;
    this.previewPixelMap = undefined;
    if (this.foregroundImage !== undefined) {
      try {
        this.foregroundImage.release();
      } catch (_e) {
      }
      this.foregroundImage = undefined;
    }
    if (this.decodedPixelMap !== undefined) {
      try {
        this.decodedPixelMap.release();
      } catch (_e) {
      }
      this.decodedPixelMap = undefined;
    }
    this.baseImage = undefined;
    getSubjectSegmentationService().invalidate();
  }

  private async loadPreviewSource(): Promise<void> {
    if (this.imageSrc === '') {
      this.previewLoading = false;
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const source = await this.previewPipeline.loadSource(this.imageSrc, context);
      if (this.disposed) {
        source.release();
        return;
      }
      this.previewSourcePixelMap = source;
      this.previewPixelMap = source;
      this.previewLoading = false;
      console.info('Editor preview source decoded');
      if (this.activeTool === 'filter') {
        this.loadFilterThumbnails();
      }
    } catch (err) {
      console.error(`Failed to decode editor preview: ${JSON.stringify(err)}`);
      this.previewPixelMap = undefined;
      this.previewLoading = false;
      if (this.displaySrc === '') {
        this.errorText = '图片解码失败，请返回后重新导入';
      } else {
        this.toast('图片处理源解码失败，已显示所选原图');
      }
    }
  }

  private async applyFilterSelection(filterId: string): Promise<void> {
    const preset: FilterPreset | undefined = FILTER_PRESETS.find((item: FilterPreset) => item.id === filterId);
    if (preset === undefined) {
      return;
    }
    if (preset.lutPath !== undefined && !this.loadedFilterIds.includes(preset.id)) {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const loaded = await FilterNativeBridge.loadPreset(context, preset);
        if (!loaded) {
          this.toast('滤镜资源加载失败');
          return;
        }
        this.loadedFilterIds.push(preset.id);
      } catch (err) {
        console.error(`Failed to read LUT ${preset.id}: ${JSON.stringify(err)}`);
        this.toast('滤镜资源读取失败');
        return;
      }
    }
    this.editState = this.filterController.selectFilter(filterId);
    this.dirty = true;
    await this.renderPreview();
  }

  private async renderPreview(): Promise<void> {
    const source = this.previewSourcePixelMap;
    if (source === undefined) {
      return;
    }
    const filterId = this.editState.filter.filterId;
    const strength = this.editState.filter.strength;
    try {
      const result = await this.previewPipeline.render(
        async (src: image.PixelMap): Promise<image.PixelMap> => {
          if (filterId !== 'original' && strength > 0) {
            const filtered = await FilterNativeBridge.render(src, filterId, strength);
            return filtered;
          }
          return src;
        }
      );
      if (result !== undefined) {
        if (this.disposed) {
          result.release();
          return;
        }
        this.renderedPreviewOwner.replace(result);
        this.previewPixelMap = result;
      }
    } catch (err) {
      console.error(`Failed to render preview: ${JSON.stringify(err)}`);
    }
  }

  private releaseRenderedPreview(): void {
    this.renderedPreviewOwner.clear();
    this.previewPixelMap = undefined;
  }

  private async loadFilterThumbnails(): Promise<void> {
    if (this.imageSrc === '' || this.loadingThumbnails) {
      return;
    }
    if (this.thumbnailItems.length === FILTER_PRESETS.length) {
      return;
    }
    this.loadingThumbnails = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const sessionId = `session_${Date.now()}`;
      await this.thumbnailPipeline.loadSource(this.imageSrc, sessionId, context);
      const items: ThumbnailItem[] = [];
      for (let i = 0; i < FILTER_PRESETS.length; i++) {
        if (this.disposed) {
          break;
        }
        const preset = FILTER_PRESETS[i];
        const pm = await this.thumbnailPipeline.renderPreset(context, preset);
        if (pm !== undefined) {
          items.push({ filterId: preset.id, pixelMap: pm });
        }
      }
      if (!this.disposed) {
        this.thumbnailItems = items;
      }
    } catch (err) {
      console.error(`Failed to build filter thumbnails: ${JSON.stringify(err)}`);
    } finally {
      this.loadingThumbnails = false;
    }
  }

  build() {
    Column() {
      PaperBackground() {
        Column() {
          this.editorTopBar()
          if (this.errorText !== '') {
            this.errorState()
          } else {
            this.editorBody()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  editorTopBar() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Image($r('app.media.icon_back'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .fillColor(Theme.PRIMARY)
            .onClick(() => this.tryBack())

          Blank().layoutWeight(1)

          Text('导出')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_BODY_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ON_PRIMARY)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(Theme.SEAL_RED)
            .borderRadius(Theme.RADIUS_DEFAULT)
            .onClick(() => this.save())
        }
        .width('100%')
        .height(Theme.HEADER_HEIGHT)
        .padding({ left: 16, right: 16 })

        Text('调色复核')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
          .fontWeight(600)
          .fontColor(Theme.ON_SURFACE)
          .letterSpacing(2)
          .maxLines(1)
          .width('100%')
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height(Theme.HEADER_HEIGHT)
    }
    .width('100%')
    .padding({ top: AppStorage.get<number>('statusBarHeight') ?? 0 })
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: Theme.OUTLINE_VARIANT })
  }

  @Builder
  errorState() {
    Column({ space: 12 }) {
      Text('无法进入编辑页')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text(this.errorText)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .textAlign(TextAlign.Center)
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      Row() {
        Text('返回')
          .fontFamily(Theme.FONT_SANS)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ON_PRIMARY)
      }
      .width(160)
      .height(48)
      .margin({ top: 12 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Theme.PRIMARY)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .onClick(() => this.getUIContext().getRouter().back())
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 96, bottom: 96 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  editorBody() {
    Column() {
      // 中部预览区
      PreviewArea({
        imageSrc: this.displaySrc !== '' ? this.displaySrc : this.imageSrc,
        previewPixelMap: $previewPixelMap,
        previewLoading: this.previewLoading,
        params: this.params,
        isComparing: this.isComparing,
        baseImage: this.baseImage,
        foregroundImage: this.foregroundImage,
        subjectFilter: buildAdjustmentFilter(
          this.regionAdjustments.subject.exposure,
          this.regionAdjustments.subject.contrast,
          this.regionAdjustments.subject.saturation,
          this.regionAdjustments.subject.temperature
        ),
        baseFilter: buildAdjustmentFilter(
          this.regionAdjustments.background.exposure,
          this.regionAdjustments.background.contrast,
          this.regionAdjustments.background.saturation,
          this.regionAdjustments.background.temperature
        ),
        onCompareChange: (down: boolean) => {
          this.isComparing = down;
        },
        onImageSizeChange: (w: number, h: number) => {
          this.imageWidth = w;
          this.imageHeight = h;
        },
        stickers: this.stickers,
        stickerMode: this.activeTool === 'sticker',
        selectedStickerId: this.selectedStickerId,
        stickerVersion: this.stickerVersion,
        onStickerSelect: (instanceId: string) => {
          this.selectedStickerId = instanceId;
          this.updateTargetValues();
        },
        onStickerUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => {
          this.updateStickerPosition(instanceId, posX, posY, size, rotation);
        },
        onDisplaySizeChange: (displayW: number, displayH: number) => {
          this.previewDisplayW = displayW;
          this.previewDisplayH = displayH;
        }
      })
        .layoutWeight(1)
        .padding({ top: Theme.GUTTER, bottom: Theme.GUTTER })

      // 区域切换 Tab（主体/背景）
      if (this.isRegionMode()) {
        RegionTabs({
          selected: this.activeRegion,
          onChange: (region: RegionKey) => {
            this.activeRegion = region;
            this.selectedType = REGION_ADJUST_TYPES[0].key;
          }
        })
          .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      }

      // 分割错误提示
      if (this.segErrorMessage !== '' && !this.isRegionMode()) {
        Text(this.segErrorMessage)
          .fontFamily(Theme.FONT_SANS)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontColor(Theme.ERROR)
          .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: Theme.SPACE_MD })
      }

      // 中下部参数面板
      if (this.activeTool === 'adjust') {
        AdjustPanel({
          params: this.params,
          selectedType: this.selectedType,
          typeDefs: ADJUST_TYPES,
          onChange: (key: string, value: number) => {
            this.updateParam(key, value);
          },
          onSelectType: (key: string) => {
            this.selectedType = key;
          },
          onReset: () => this.showResetOptions(),
          onCompareChange: (down: boolean) => {
            this.isComparing = down;
          }
        })
      } else if (this.isRegionMode() && this.segStatus === 'ready') {
        AdjustPanel({
          params: this.activeRegionParams(),
          selectedType: this.selectedType,
          typeDefs: REGION_ADJUST_TYPES,
          onChange: (key: string, value: number) => {
            this.updateRegionParam(key, value);
          },
          onSelectType: (key: string) => {
            this.selectedType = key;
          },
          onReset: () => this.showRegionResetOptions(),
          onCompareChange: (down: boolean) => {
            this.isComparing = down;
          }
        })
      } else if ((this.activeTool === 'subject' || this.activeTool === 'background') &&
        this.segStatus !== 'ready' && this.segStatus !== 'idle') {
        Column({ space: 8 }) {
          Text('主体识别中…')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(Theme.FONT_SIZE_BODY_MD)
            .fontColor(Theme.ON_SURFACE_VARIANT)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
      } else if (this.activeTool === 'filter') {
        FilterPanel({
          editState: this.editState,
          previewPixelMap: $previewPixelMap,
          thumbnails: $thumbnailItems,
          onSelectFilter: (filterId: string) => {
            this.applyFilterSelection(filterId);
          },
          onStrengthChange: (value: number) => {
            // strength change handled by FilterPanel internally via editState
          }
        })
      } else if (this.activeTool === 'sticker') {
        StickerPanel({
          stickers: this.stickers,
          selectedId: this.selectedStickerId,
          allTemplates: STICKER_TEMPLATES,
          onAddSticker: (templateId: string) => {
            this.addSticker(templateId);
          },
          onSelectSticker: (instanceId: string) => {
            this.selectedStickerId = instanceId;
            this.updateTargetValues();
          },
          onUpdateSticker: (instanceId: string, size: number, rotation: number, opacity: number) => {
            this.updateStickerParams(instanceId, size, rotation, opacity);
          },
          onRemoveSticker: (instanceId: string) => {
            this.removeSticker(instanceId);
          },
          notifySizeChange: (value: number) => {
            this.onSliderSizeChange(value);
          },
          notifyRotationChange: (value: number) => {
            this.onSliderRotationChange(value);
          },
          notifyOpacityChange: (value: number) => {
            this.onSliderOpacityChange(value);
          }
        })
      } else {
        this.toolPlaceholder()
      }

      // 底部工具导航
      EditorToolBar({
        activeTool: this.activeTool,
        onSelectTool: (key: EditorToolKey) => {
          this.onToolSelect(key);
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  toolPlaceholder() {
    Column({ space: 8 }) {
      Text(this.activeToolLabel())
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text('功能待接入')
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
  }

  // ── 工具选择 ──

  private onToolSelect(key: EditorToolKey): void {
    this.activeTool = key;
    if (key === 'subject' || key === 'background') {
      this.activeRegion = key;
      this.selectedType = REGION_ADJUST_TYPES[0].key;
      this.triggerSegmentation();
    }
    if (key === 'adjust') {
      this.selectedType = ADJUST_TYPES[0].key;
    }
    if (key === 'filter') {
      this.loadFilterThumbnails();
    }
  }

  private isRegionMode(): boolean {
    return this.activeTool === 'subject' || this.activeTool === 'background';
  }

  private activeRegionParams(): AdjustParams {
    return this.activeRegion === 'subject'
      ? this.regionAdjustments.subject
      : this.regionAdjustments.background;
  }

  private activeToolLabel(): string {
    for (let i = 0; i < EDITOR_TOOLS.length; i++) {
      if (EDITOR_TOOLS[i].key === this.activeTool) {
        return EDITOR_TOOLS[i].label;
      }
    }
    return '';
  }

  // ── 参数更新 ──

  private updateParam(key: string, value: number): void {
    const next = cloneAdjustments(this.params);
    if (key === 'exposure') {
      next.exposure = value;
    } else if (key === 'brightness') {
      next.brightness = value;
    } else if (key === 'contrast') {
      next.contrast = value;
    } else if (key === 'saturation') {
      next.saturation = value;
    } else if (key === 'temperature') {
      next.temperature = value;
    }
    this.params = next;
    this.dirty = true;
  }

  private updateRegionParam(key: string, value: number): void {
    const next = cloneRegionAdjustments(this.regionAdjustments);
    const target = this.activeRegion === 'subject' ? next.subject : next.background;
    if (key === 'brightness') {
      target.brightness = value;
    } else if (key === 'contrast') {
      target.contrast = value;
    } else if (key === 'saturation') {
      target.saturation = value;
    } else if (key === 'temperature') {
      target.temperature = value;
    }
    this.regionAdjustments = next;
    this.dirty = true;
  }

  private resetCurrentSlider(): void {
    const next = cloneAdjustments(this.params);
    if (this.selectedType === 'exposure') {
      next.exposure = 0;
    } else if (this.selectedType === 'brightness') {
      next.brightness = 0;
    } else if (this.selectedType === 'contrast') {
      next.contrast = 0;
    } else if (this.selectedType === 'saturation') {
      next.saturation = 0;
    } else if (this.selectedType === 'temperature') {
      next.temperature = 0;
    }
    this.params = next;
    this.dirty = true;
  }

  private resetAllSliders(): void {
    this.params = createDefaultAdjustments();
    this.isComparing = false;
    this.dirty = false;
  }

  private showResetOptions(): void {
    this.getUIContext().showActionSheet({
      title: '重置',
      message: '选择重置范围',
      sheets: [
        { title: '重置当前区域', action: () => this.resetCurrentSlider() },
        { title: '全部重置', action: () => this.resetAllSliders() }
      ],
      cancel: () => {
      }
    });
  }

  private showRegionResetOptions(): void {
    this.getUIContext().showActionSheet({
      title: '重置',
      message: '选择重置范围',
      sheets: [
        { title: '重置当前滑块', action: () => this.resetCurrentRegionSlider() },
        { title: '重置双区域', action: () => this.resetAllRegionSliders() }
      ],
      cancel: () => {
      }
    });
  }

  private resetCurrentRegionSlider(): void {
    const next = cloneRegionAdjustments(this.regionAdjustments);
    const target = this.activeRegion === 'subject' ? next.subject : next.background;
    if (this.selectedType === 'brightness') {
      target.brightness = 0;
    } else if (this.selectedType === 'contrast') {
      target.contrast = 0;
    } else if (this.selectedType === 'saturation') {
      target.saturation = 0;
    } else if (this.selectedType === 'temperature') {
      target.temperature = 0;
    }
    this.regionAdjustments = next;
    this.dirty = true;
  }

  private resetAllRegionSliders(): void {
    this.regionAdjustments = createDefaultRegionAdjustments();
    this.dirty = true;
  }

  // ── 贴纸操作 ──

  private addSticker(templateId: string): void {
    if (this.stickers.length >= STICKER_MAX_COUNT) {
      return;
    }
    const centerX = this.previewDisplayW > 0 ? this.previewDisplayW / 2 : 150;
    const centerY = this.previewDisplayH > 0 ? this.previewDisplayH / 2 : 200;
    const newItem = createStickerInstance(templateId, centerX, centerY);
    const next: StickerItem[] = [];
    for (let i = 0; i < this.stickers.length; i++) {
      next.push(this.stickers[i]);
    }
    next.push(newItem);
    this.stickers = next;
    this.stickerVersion++;
    this.selectedStickerId = newItem.instanceId;
    this.dirty = true;
    this.updateTargetValues();
  }

  private removeSticker(instanceId: string): void {
    const next: StickerItem[] = [];
    for (let i = 0; i < this.stickers.length; i++) {
      if (this.stickers[i].instanceId !== instanceId) {
        next.push(this.stickers[i]);
      }
    }
    this.stickers = next;
    this.stickerVersion++;
    if (this.selectedStickerId === instanceId) {
      this.selectedStickerId = '';
    }
    this.dirty = true;
  }

  private updateStickerPosition(instanceId: string, posX: number, posY: number, size: number, rotation: number): void {
    const next: StickerItem[] = [];
    for (let i = 0; i < this.stickers.length; i++) {
      const s = this.stickers[i];
      if (s.instanceId === instanceId) {
        const updated: StickerItem = {
          instanceId: s.instanceId,
          templateId: s.templateId,
          posX: posX,
          posY: posY,
          size: size,
          rotation: rotation,
          opacity: s.opacity,
          zIndex: s.zIndex
        };
        next.push(updated);
      } else {
        next.push(s);
      }
    }
    this.stickers = next;
    this.stickerVersion++;
    this.dirty = true;
  }

  private updateStickerParams(instanceId: string, size: number, rotation: number, opacity: number): void {
    const next: StickerItem[] = [];
    for (let i = 0; i < this.stickers.length; i++) {
      const s = this.stickers[i];
      if (s.instanceId === instanceId) {
        const updated: StickerItem = {
          instanceId: s.instanceId,
          templateId: s.templateId,
          posX: s.posX,
          posY: s.posY,
          size: size,
          rotation: rotation,
          opacity: opacity,
          zIndex: s.zIndex
        };
        next.push(updated);
      } else {
        next.push(s);
      }
    }
    this.stickers = next;
    this.stickerVersion++;
    this.dirty = true;
    this.updateTargetValues();
  }

  private updateTargetValues(): void {
    if (this.selectedStickerId === '') {
      return;
    }
    for (let i = 0; i < this.stickers.length; i++) {
      const s = this.stickers[i];
      if (s.instanceId === this.selectedStickerId) {
        this.stickerTargetSize = s.size;
        this.stickerTargetRotation = s.rotation;
        this.stickerTargetOpacity = s.opacity;
        return;
      }
    }
  }

  private onSliderSizeChange(value: number): void {
    this.stickerTargetSize = value;
    if (this.selectedStickerId !== '') {
      this.updateStickerParams(this.selectedStickerId, value,
        this.getSelectedRotation(), this.getSelectedOpacity());
    }
  }

  private onSliderRotationChange(value: number): void {
    this.stickerTargetRotation = value;
    if (this.selectedStickerId !== '') {
      this.updateStickerParams(this.selectedStickerId,
        this.getSelectedSize(), value, this.getSelectedOpacity());
    }
  }

  private onSliderOpacityChange(value: number): void {
    this.stickerTargetOpacity = value;
    if (this.selectedStickerId !== '') {
      this.updateStickerParams(this.selectedStickerId,
        this.getSelectedSize(), this.getSelectedRotation(), value);
    }
  }

  private getSelectedSize(): number {
    for (let i = 0; i < this.stickers.length; i++) {
      if (this.stickers[i].instanceId === this.selectedStickerId) {
        return this.stickers[i].size;
      }
    }
    return 48;
  }

  private getSelectedRotation(): number {
    for (let i = 0; i < this.stickers.length; i++) {
      if (this.stickers[i].instanceId === this.selectedStickerId) {
        return this.stickers[i].rotation;
      }
    }
    return 0;
  }

  private getSelectedOpacity(): number {
    for (let i = 0; i < this.stickers.length; i++) {
      if (this.stickers[i].instanceId === this.selectedStickerId) {
        return this.stickers[i].opacity;
      }
    }
    return 1.0;
  }

  // ── AI 分割 ──

  private async triggerSegmentation(): Promise<void> {
    if (this.segStatus !== 'idle' && this.segStatus !== 'error') {
      return;
    }
    if (this.imageSrc === '') {
      this.segErrorMessage = '无可用图片';
      return;
    }
    this.segStatus = 'preparing';
    this.segErrorMessage = '';
    try {
      const decoded = await decodeImageFromUri(this.imageSrc, AI_WORK_MAX_EDGE);
      this.decodedPixelMap = decoded.pixelMap;
      this.segStatus = 'segmenting';

      const outcome = await getSubjectSegmentationService().segment(decoded.pixelMap);

      if (outcome.status === 'ready') {
        await this.onSegmentationSuccess(outcome.output!);
      } else if (outcome.status === 'noSubject') {
        this.toast('没有识别到明显主体');
        this.segStatus = 'idle';
      } else {
        const errMsg = segErrorToMessage(outcome.code!);
        this.toast(errMsg);
        this.segErrorMessage = errMsg;
        this.segStatus = 'error';
      }
    } catch (_err) {
      this.toast('图片加载失败，请重试');
      this.segStatus = 'error';
      this.segErrorMessage = '图片加载失败';
    }
  }

  private async onSegmentationSuccess(output: SegmentationOutput): Promise<void> {
    this.segStatus = 'ready';
    this.baseImage = this.decodedPixelMap;

    const fg = output.foregroundImage;
    if (fg !== undefined && fg !== null) {
      this.foregroundImage = fg;
      hilog.info(0x0000, 'EditPage', 'foreground image stored');
    } else {
      hilog.warn(0x0000, 'EditPage', 'foreground image not available from segmentation');
      this.foregroundImage = undefined;
    }

    this.dirty = true;
  }

  // ── 保存 ──

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    this.saving = true;

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const route = this.route;

    try {
      const sourceUri = this.imageSrc;
      if (!sourceUri) {
        this.toast('源图不可用，请返回重试');
        this.saving = false;
        return;
      }

      const exportSettings = await AppSettingsStore.getExportSettings();
      const exportProfile = toExportProfile(exportSettings);

      // 确保滤镜资源已加载
      const filterId = this.editState.filter.filterId;
      const filterStrength = this.editState.filter.strength;
      const preset = FILTER_PRESETS.find((item: FilterPreset) => item.id === filterId);
      if (preset !== undefined && preset.lutPath !== undefined && !this.loadedFilterIds.includes(filterId)) {
        const loaded = await FilterNativeBridge.loadPreset(context, preset);
        if (!loaded) {
          this.toast('滤镜资源加载失败');
          this.saving = false;
          return;
        }
        this.loadedFilterIds.push(filterId);
      }

      // 渲染调色后的图片
      const pixelMap = await ImageRenderService.render(
        sourceUri,
        this.params,
        exportProfile,
        filterId,
        filterStrength,
        true,
        context
      );

      // 编码到 cacheDir
      const cacheFilePath = await PhotoExportService.encodeToCacheFile(context, pixelMap, exportProfile);
      pixelMap.release();

      if (!cacheFilePath) {
        this.toast('图片编码失败');
        this.saving = false;
        return;
      }

      // 写入系统相册
      const fileName = `Vivid_${Date.now()}`;
      const ext = exportProfile.extension === '.png' ? 'png' : 'jpg';
      const exportResult = await PhotoExportService.saveViaDialog(context, cacheFilePath, fileName, ext);

      if (exportResult.success) {
        this.toast('已保存到系统相册「图片」');
      } else if (exportResult.errorCode === 'USER_CANCELLED') {
        this.saving = false;
        return;
      } else {
        this.toast(exportResult.errorMessage ?? '保存到相册失败');
        this.saving = false;
        return;
      }

      // 保存作品记录
      const intent = buildSaveIntent(
        route?.source ?? EditEntrySource.Picker,
        route?.workId ?? '',
        this.imageSrc,
        this.params,
        Date.now()
      );
      mockWorkStore.init();
      const now = Date.now();
      const record = new WorkRecord();
      record.id = intent.draft.id;
      record.title = generateWorkTitle(now, mockWorkStore.countToday());
      record.description = generateWorkDescription(this.params, this.imageWidth, this.imageHeight);
      record.sourceImageUri = intent.draft.sourceImageUri;
      record.previewImageUri = intent.draft.sourceImageUri;
      record.width = this.imageWidth;
      record.height = this.imageHeight;
      record.adjustments = intent.draft.adjustments;
      record.regionAdjustments = cloneRegionAdjustments(this.regionAdjustments);
      record.status = intent.draft.status;
      record.createdAt = now;
      record.updatedAt = now;
      if (intent.mode === SaveMode.Update) {
        mockWorkStore.update(intent.id ?? '', record);
      } else {
        mockWorkStore.create(record);
      }
      WorkUiState.bumpRevision();

      this.dirty = false;
      this.getUIContext().getRouter().back();
    } catch (_err) {
      this.toast('保存失败，请重试');
    } finally {
      this.saving = false;
    }
  }

  private tryBack(): void {
    if (this.dirty && this.errorText === '') {
      this.getUIContext().showAlertDialog({
        title: '放弃未保存的调整？',
        message: '当前调整尚未落印，返回将自动存为草稿。',
        primaryButton: {
          value: '继续编辑',
          action: () => {
          }
        },
        secondaryButton: {
          value: '放弃返回',
          action: () => this.saveDraft()
        },
        cancel: () => {
        }
      });
    } else {
      this.getUIContext().getRouter().back();
    }
  }

  private async saveDraft(): Promise<void> {
    const route = this.route;
    try {
      const intent = buildDraftIntent(
        route?.source ?? EditEntrySource.Picker,
        route?.workId ?? '',
        this.imageSrc,
        this.params,
        Date.now()
      );
      mockWorkStore.init();
      const now = Date.now();
      const record = new WorkRecord();
      record.id = intent.draft.id;
      record.title = generateWorkTitle(now, mockWorkStore.countToday());
      record.description = generateWorkDescription(this.params, this.imageWidth, this.imageHeight);
      record.sourceImageUri = intent.draft.sourceImageUri;
      record.previewImageUri = intent.draft.sourceImageUri;
      record.width = this.imageWidth;
      record.height = this.imageHeight;
      record.adjustments = intent.draft.adjustments;
      record.status = intent.draft.status;
      record.createdAt = now;
      record.updatedAt = now;
      if (intent.mode === SaveMode.Update) {
        mockWorkStore.update(intent.id ?? '', record);
      } else {
        mockWorkStore.create(record);
      }
      WorkUiState.bumpRevision();
      this.toast('已存为草稿');
    } catch (_err) {
      // 草稿保存失败不阻断返回
    }

    this.dirty = false;
    this.getUIContext().getRouter().back();
  }

  onBackPress(): boolean {
    this.tryBack();
    return true;
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
    }
  }
}
