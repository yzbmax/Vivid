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
  StickerTemplate,
  StickerRenderType,
  RawEditRouteParams,
  SaveMode,
  buildDraftIntent,
  buildSaveIntent,
  createDefaultAdjustments,
  createDefaultRegionAdjustments,
  createStickerInstance,
  createCustomStickerInstance,
  cloneAdjustments,
  cloneRegionAdjustments,
  editRouteError,
  normalizeEditorToolKey,
  parseEditRouteParams,
  resolveDisplayImageSource
} from '../models/EditModels';
import { fileIo as fs } from '@kit.CoreFileKit';
import { PhotoPickerService } from '../services/PhotoPickerService';
import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PreviewArea } from '../components/editor/PreviewArea';
import { AdjustPanel } from '../components/editor/AdjustPanel';
import { StickerPanel } from '../components/editor/StickerPanel';
import { FilterPanel } from '../components/editor/FilterPanel';
import { BorderPanel } from '../components/editor/BorderPanel';
import { BorderTemplatePickerModal } from '../components/editor/BorderTemplatePickerModal';
import { isWatermarkTemplate } from '../features/editor/border/BorderCatalog';
import { sanitizeBorderState, switchBorderTemplate } from '../features/editor/border/BorderState';
import { EditorCompositionService } from '../services/EditorCompositionService';
import {
  BorderState,
  defaultBorderState,
  cloneBorderState,
  WatermarkConfig,
  defaultWatermarkConfig,
  cloneWatermarkConfig,
  EditorSnapshot,
  defaultEditorSnapshot,
  cloneEditorSnapshot,
  cloneFilterSnapshot,
  TextLayer as TextLayerModel,
  cloneTextLayers,
  StickerSnapshotItem
} from '../models/SharedContracts';
import { ExifReaderService } from '../services/ExifReaderService';
import { draftStore } from '../models/DraftStore';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { TextPanel } from '../components/editor/TextPanel';
import { registerTextFonts } from '../components/editor/TextFontRegistrar';
import { fixAndNormalizePath } from '../utils/WorkImageUtils';
import { WorkFileService } from '../services/WorkFileService';
// ===== End A =====
import { EditorToolBar } from '../components/editor/EditorToolBar';
import { RegionTabs } from '../components/editor/RegionTabs';
import { common } from '@kit.AbilityKit';
import { AppSettingsStore } from '../models/AppSettingsStore';
import { toExportProfile, ExportProfile, AppExportSettings } from '../models/AppSettingsModels';
import { ExportSettingsDialog } from '../components/common/ExportSettingsDialog';
import { PhotoExportService } from '../services/PhotoExportService';
import { SubjectSegmentationService, getSubjectSegmentationService } from '../services/SubjectSegmentationService';
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
import { EditState, createDefaultEditState } from '../features/editor/filter/FilterState';
import { FilterPreset, FilterEditState } from '../features/editor/filter/FilterModels';
import { FILTER_PRESETS } from '../features/editor/filter/FilterCatalog';
import { FilterNativeBridge } from '../features/editor/filter/FilterNativeBridge';
import { FilterController } from '../features/editor/filter/FilterController';
import { OwnedRenderResult, PreviewPipeline } from '../services/PreviewPipeline';
import { ThumbnailItem, ThumbnailPipeline } from '../services/ThumbnailPipeline';
import { renderThumbnailBatch } from '../features/editor/filter/ThumbnailBatch';
// ===== A: Text Layer =====
import {
  applyTextInput,
  deleteTextLayer,
  TextLayerPatch,
  updateTextLayer
} from '../features/editor/text/TextLayerState';
// ===== End A =====

/**
 * 独立调色编辑页。
 *
 * 布局（自上而下）：
 *  1. 顶部导航区（~8-10%）：返回（左）| 标题 | 保存（右）。
 *  2. 中部预览区（~65-70%）：Contain 原比例不裁切，占满导航与面板之间。
 *  3. 中下部参数面板（~12-15%）：调节工具两行（重置/滑块/对比 + 调整类型选择）。
 *  4. 底部工具导航（~8-10%）：滤镜/主体/背景/调节/贴纸/文字/边框，高亮「调节」。
 *
 * 路由参数：source（picker/work）、imageUri（picker 时）、workId（work 时）、
 * initialTool（可选，快捷入口传入）。
 *
 * 文字区“保存”确认当前题签；顶部“导出”执行滤镜、调色、文字、边框合成及相册保存。
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
  // ── Vivid 0.1.9 边框状态（C 独占）──
  @State borderState: BorderState = defaultBorderState();
  @State showBorderPickerModal: boolean = false;
  @State showExportDialog: boolean = false;
  // ===== A: Text Layer =====
  @State textLayers: TextLayerModel[] = [];
  @State selectedTextLayerId: string = '';
  @State textInputContent: string = '';
  @State textValidationMessage: string = '';
  @State textSaved: boolean = false;
  @State textPhotoWidth: number = 0;
  @State textPhotoHeight: number = 0;
  @State textEditorViewportH: number = 600;
  @State unavailableTextFontKeys: string[] = [];
  private previousTextKeyboardMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private textLayerSequence: number = 1;
  // ===== End A =====
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
  @State customStickerTemplates: StickerTemplate[] = [];
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
  @State unavailableFilterIds: string[] = [];
  private thumbnailsComplete: boolean = false;
  @State previewSourcePixelMap: image.PixelMap | undefined = undefined;
  private strengthDebounceTimer: number = -1;
  private filterPrewarmTimer: number = -1;
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
    // ===== A: Text Layer =====
    const textContext = this.getUIContext();
    this.previousTextKeyboardMode = textContext.getKeyboardAvoidMode();
    const fontReport = registerTextFonts(textContext);
    this.unavailableTextFontKeys = fontReport.failed;
    if (fontReport.failed.length > 0) {
      console.warn('Text font registration fallback count: ' + fontReport.failed.length);
    }
    // ===== End A =====
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
        if (work.editorSnapshot !== undefined) {
          this.textLayers = cloneTextLayers(work.editorSnapshot.textLayers);
          this.textLayerSequence = this.nextTextLayerSequence(this.textLayers);
          if (work.editorSnapshot.border) {
            this.borderState = cloneBorderState(work.editorSnapshot.border);
          }
          if (work.editorSnapshot.filter) {
            const nextFilter: FilterEditState = {
              filterId: work.editorSnapshot.filter.filterId,
              strength: work.editorSnapshot.filter.strength
            };
            const nextEditState: EditState = {
              filter: nextFilter
            };
            this.editState = nextEditState;
          }
          if (work.editorSnapshot.stickers) {
            this.stickers = work.editorSnapshot.stickers.map((s: StickerSnapshotItem): StickerItem => {
              const item: StickerItem = {
                instanceId: s.instanceId,
                templateId: s.templateId,
                posX: s.posX,
                posY: s.posY,
                size: s.size,
                rotation: s.rotation,
                opacity: s.opacity,
                zIndex: s.zIndex,
                customUri: s.customUri
              };
              return item;
            });
            for (const s of this.stickers) {
              if (s.customUri && !this.customStickerTemplates.some((t: StickerTemplate) => t.customUri === s.customUri)) {
                const customTpl: StickerTemplate = {
                  id: s.templateId,
                  name: '自定',
                  category: 'custom',
                  renderType: StickerRenderType.CustomImage,
                  resource: null,
                  textContent: '',
                  defaultSize: 64,
                  customUri: s.customUri
                };
                this.customStickerTemplates.push(customTpl);
              }
            }
          }
        }
      } else {
        this.errorText = '作品不存在';
      }
    } else if (route != null && route.source === EditEntrySource.Draft) {
      const draft = draftStore.get();
      if (draft !== null && draft.imageUri.length > 0) {
        this.imageSrc = draft.imageUri;
        this.displaySrc = draft.displayUri ?? this.imageSrc;
        this.params = {
          exposure: draft.adjustments.exposure,
          brightness: draft.adjustments.brightness,
          contrast: draft.adjustments.contrast,
          saturation: draft.adjustments.saturation,
          temperature: draft.adjustments.temperature
        };
        if (draft.regionAdjustments !== undefined) {
          this.regionAdjustments = cloneRegionAdjustments(draft.regionAdjustments);
        }
        if (draft.editorSnapshot !== undefined) {
          this.textLayers = cloneTextLayers(draft.editorSnapshot.textLayers);
          this.textLayerSequence = this.nextTextLayerSequence(this.textLayers);
          if (draft.editorSnapshot.border) {
            this.borderState = cloneBorderState(draft.editorSnapshot.border);
          }
          if (draft.editorSnapshot.filter) {
            const nextFilter: FilterEditState = {
              filterId: draft.editorSnapshot.filter.filterId,
              strength: draft.editorSnapshot.filter.strength
            };
            const nextEditState: EditState = {
              filter: nextFilter
            };
            this.editState = nextEditState;
          }
          if (draft.editorSnapshot.stickers) {
            this.stickers = draft.editorSnapshot.stickers.map((s: StickerSnapshotItem): StickerItem => {
              const item: StickerItem = {
                instanceId: s.instanceId,
                templateId: s.templateId,
                posX: s.posX,
                posY: s.posY,
                size: s.size,
                rotation: s.rotation,
                opacity: s.opacity,
                zIndex: s.zIndex,
                customUri: s.customUri
              };
              return item;
            });
            for (const s of this.stickers) {
              if (s.customUri && !this.customStickerTemplates.some((t: StickerTemplate) => t.customUri === s.customUri)) {
                const customTpl: StickerTemplate = {
                  id: s.templateId,
                  name: '自定',
                  category: 'custom',
                  renderType: StickerRenderType.CustomImage,
                  resource: null,
                  textContent: '',
                  defaultSize: 64,
                  customUri: s.customUri
                };
                this.customStickerTemplates.push(customTpl);
              }
            }
          }
        }
        if (draft.activeTool !== undefined) {
          this.activeTool = draft.activeTool;
        }
        this.dirty = true;
      } else {
        this.errorText = '草稿不存在或已被清理';
      }
    }
    if (route?.initialTool !== undefined) {
      this.activeTool = route.initialTool;
    }
    // ===== A: Text Layer =====
    if (this.activeTool === 'text') {
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
    }
    // ===== End A =====
    if (this.activeTool === 'subject' || this.activeTool === 'background') {
      this.activeRegion = this.activeTool;
      this.selectedType = REGION_ADJUST_TYPES[0].key;
      if (this.baseImage === undefined) {
        this.baseImage = this.previewSourcePixelMap ?? this.previewPixelMap;
      }
      setTimeout(() => {
        this.triggerSegmentation();
      }, 100);
    }
    this.loadPreviewSource();
  }

  onPageHide(): void {
    this.persistDraftQuietly();
  }

  aboutToDisappear(): void {
    if (this.strengthDebounceTimer !== -1) {
      clearTimeout(this.strengthDebounceTimer);
      this.strengthDebounceTimer = -1;
    }
    if (this.filterPrewarmTimer !== -1) {
      clearTimeout(this.filterPrewarmTimer);
      this.filterPrewarmTimer = -1;
    }
    // ===== A: Text Layer =====
    this.getUIContext().setKeyboardAvoidMode(this.previousTextKeyboardMode);
    // ===== End A =====
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
      if (this.baseImage === undefined) {
        this.baseImage = source;
      }
      // ===== A: Text Layer =====
      // PixelMap 预览不会触发 URI Image 尺寸回调；供照片、文字和装裱统一布局使用。
      try {
        const textImageInfo = source.getImageInfoSync();
        this.textPhotoWidth = textImageInfo.size.width;
        this.textPhotoHeight = textImageInfo.size.height;
      } catch (_err) {
        console.warn('Editor preview dimensions unavailable');
      }
      // ===== End A =====
      this.previewLoading = false;
      console.info('Editor preview source decoded');
      if (this.activeTool === 'filter') {
        this.loadFilterThumbnails();
      } else {
        // 空闲预热：主预览图就绪后，利用空闲时间在后台静默预热滤镜缩略图，用户点击“滤镜”时秒开
        if (this.filterPrewarmTimer !== -1) {
          clearTimeout(this.filterPrewarmTimer);
        }
        this.filterPrewarmTimer = setTimeout(() => {
          this.filterPrewarmTimer = -1;
          if (!this.disposed && !this.thumbnailsComplete && !this.loadingThumbnails) {
            this.loadFilterThumbnails();
          }
        }, 300);
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
          if (result !== source) {
            result.release();
          }
          return;
        }
        this.renderedPreviewOwner.replace(result, source);
        this.previewPixelMap = result;
      }
    } catch (err) {
      console.error(`Failed to render preview: ${JSON.stringify(err)}`);
    }
  }

  private schedulePreviewRender(): void {
    if (this.strengthDebounceTimer !== -1) {
      clearTimeout(this.strengthDebounceTimer);
    }
    this.strengthDebounceTimer = setTimeout(() => {
      this.strengthDebounceTimer = -1;
      this.renderPreview();
    }, 32);
  }

  private releaseRenderedPreview(): void {
    this.renderedPreviewOwner.clear();
    this.previewPixelMap = undefined;
  }

  private async loadFilterThumbnails(): Promise<void> {
    if (this.imageSrc === '' || this.loadingThumbnails) {
      return;
    }
    if (this.thumbnailsComplete) {
      return;
    }
    this.loadingThumbnails = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const sessionId = `session_${Date.now()}`;
      await this.thumbnailPipeline.loadSource(this.imageSrc, sessionId, context);
      const items: ThumbnailItem[] = [];
      await renderThumbnailBatch<image.PixelMap>(FILTER_PRESETS,
        (preset: FilterPreset) => this.thumbnailPipeline.renderPreset(context, preset),
        (preset: FilterPreset, pm: image.PixelMap) => {
          items.push({ filterId: preset.id, pixelMap: pm });
          this.thumbnailItems = items.slice();
        },
        (preset: FilterPreset) => {
          this.unavailableFilterIds = this.unavailableFilterIds.concat([preset.id]);
          console.warn('Filter thumbnail unavailable: ' + preset.id);
        }, () => !this.disposed);
      if (!this.disposed) {
        this.thumbnailsComplete = true;
      }
    } catch (err) {
      console.error(`Failed to build filter thumbnails: ${JSON.stringify(err)}`);
    } finally {
      this.loadingThumbnails = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
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

      if (this.showBorderPickerModal) {
        BorderTemplatePickerModal({
          currentTemplateId: this.borderState.templateId,
          imageSrc: this.displaySrc !== '' ? this.displaySrc : this.imageSrc,
          onSelectTemplate: (templateId: string) => {
            this.borderState = switchBorderTemplate(this.borderState, templateId);
            this.dirty = true;
            if (isWatermarkTemplate(templateId)) {
              this.loadExifForWatermark();
            }
            this.showBorderPickerModal = false;
          },
          onClose: () => {
            this.showBorderPickerModal = false;
          }
        })
      }

      if (this.showExportDialog) {
        ExportSettingsDialog({
          isVisible: this.showExportDialog,
          imageWidth: this.imageWidth,
          imageHeight: this.imageHeight,
          sourceUri: this.imageSrc,
          onConfirm: (settings: AppExportSettings) => {
            this.executeSave(settings);
          },
          onCancel: () => {
            this.showExportDialog = false;
          }
        })
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

        Text('影像调色')
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
      // ===== A: Text Layer =====
      Column() {
        PreviewArea({
          imageSrc: this.displaySrc !== '' ? this.displaySrc : this.imageSrc,
          previewPixelMap: $previewPixelMap,
          previewLoading: this.previewLoading,
          originalPixelMap: $previewSourcePixelMap,
          photoWidth: this.textPhotoWidth,
          photoHeight: this.textPhotoHeight,
          borderState: this.borderState,
          textLayers: this.textLayers,
          selectedTextLayerId: this.textSaved ? '' : this.selectedTextLayerId,
          textMode: this.activeTool === 'text',
          unavailableFontKeys: this.unavailableTextFontKeys,
          onTextSelect: (id: string) => this.selectTextLayer(id),
          onTextMove: (id: string, x: number, y: number) => this.updateTextLayer(id, { centerX: x, centerY: y }),
          params: this.params,
          isComparing: this.isComparing,
          baseImage: $baseImage,
          foregroundImage: $foregroundImage,
          subjectFilter: buildAdjustmentFilter(
            this.regionAdjustments.subject.exposure,
            this.regionAdjustments.subject.contrast,
            this.regionAdjustments.subject.saturation,
            this.regionAdjustments.subject.temperature,
            this.regionAdjustments.subject.brightness
          ),
          baseFilter: buildAdjustmentFilter(
            this.regionAdjustments.background.exposure,
            this.regionAdjustments.background.contrast,
            this.regionAdjustments.background.saturation,
            this.regionAdjustments.background.temperature,
            this.regionAdjustments.background.brightness
          ),
          isRegionMode: this.isRegionMode(),
          onCompareChange: (down: boolean) => {
            this.isComparing = this.activeTool === 'text' ? false : down;
          },
          onImageSizeChange: (w: number, h: number) => {
            this.imageWidth = w;
            this.imageHeight = h;
          },
          stickers: this.stickers,
          customTemplates: this.customStickerTemplates,
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
          .width('100%')
          .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(Theme.GUTTER)
      .clip(true)
      // ===== End A =====

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
        this.segStatus !== 'ready') {
        Column({ space: 12 }) {
          if (this.segStatus === 'preparing' || this.segStatus === 'segmenting') {
            LoadingProgress()
              .width(28)
              .height(28)
              .color(Theme.PRIMARY)
            Text('智能主体识别中…')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontColor(Theme.ON_SURFACE_VARIANT)
          } else {
            Text(this.segErrorMessage !== '' ? this.segErrorMessage : '未能识别到明显主体')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontColor(Theme.ON_SURFACE_VARIANT)
            Button('重新识别主体')
              .type(ButtonType.Capsule)
              .fontSize(13)
              .backgroundColor(Theme.PRIMARY)
              .fontColor(Theme.ON_PRIMARY)
              .height(32)
              .onClick(() => {
                this.segStatus = 'idle';
                this.triggerSegmentation();
              })
          }
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
      } else if (this.activeTool === 'filter') {
        FilterPanel({
          editState: this.editState,
          previewPixelMap: $previewPixelMap,
          thumbnails: $thumbnailItems,
          unavailableFilterIds: this.unavailableFilterIds,
          onSelectFilter: (filterId: string) => {
            this.applyFilterSelection(filterId);
          },
          onStrengthChange: (value: number) => {
            this.editState = this.filterController.setStrength(value);
            this.dirty = true;
            this.schedulePreviewRender();
          }
        })
      } else if (this.activeTool === 'sticker') {
        StickerPanel({
          stickers: this.stickers,
          selectedId: this.selectedStickerId,
          allTemplates: STICKER_TEMPLATES,
          customTemplates: this.customStickerTemplates,
          onAddSticker: (templateId: string, customUri?: string) => {
            this.addSticker(templateId, customUri);
          },
          onUploadCustomSticker: () => {
            this.uploadCustomSticker();
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
      } else if (this.activeTool === 'text') {
        // ===== A: Text Layer =====
        TextPanel({
          layers: this.textLayers,
          selectedId: this.selectedTextLayerId,
          inputContent: this.textInputContent,
          validationMessage: this.textValidationMessage,
          saved: this.textSaved,
          unavailableFontKeys: this.unavailableTextFontKeys,
          maxPanelHeight: Math.max(80, Math.min(320, this.textEditorViewportH * 0.55)),
          onInputChange: (value: string) => this.onTextInput(value),
          onConfirm: () => this.confirmTextLayer(),
          onDelete: () => this.deleteSelectedTextLayer(),
          onSelect: (id: string) => this.selectTextLayer(id),
          onFontChange: (fontKey: string) => this.updateTextLayer(this.selectedTextLayerId, { fontKey: fontKey }),
          onColorChange: (colorArgb: number) => this.updateTextLayer(this.selectedTextLayerId, { colorArgb: colorArgb }),
          onFontSizeChange: (value: number) => this.updateTextLayer(this.selectedTextLayerId, { fontSizeRatio: value }),
          onRotationChange: (value: number) => this.updateTextLayer(this.selectedTextLayerId, { rotationDeg: value }),
          onOpacityChange: (value: number) => this.updateTextLayer(this.selectedTextLayerId, { opacity: value })
        })
        // ===== End A =====
      } else if (this.activeTool === 'border') {
        // ===== C: Filter & Border =====
        BorderPanel({
          borderState: this.borderState,
          imageSrc: this.displaySrc !== '' ? this.displaySrc : this.imageSrc,
          onSelectTemplate: (templateId: string) => {
            this.borderState = switchBorderTemplate(this.borderState, templateId);
            this.dirty = true;
            if (isWatermarkTemplate(templateId)) {
              this.loadExifForWatermark();
            }
          },
          onWidthRatioChange: (value: number) => {
            const next = cloneBorderState(this.borderState);
            next.widthRatio = value;
            this.borderState = sanitizeBorderState(next);
            this.dirty = true;
          },
          onRadiusChange: (value: number) => {
            const next = cloneBorderState(this.borderState);
            next.radiusRatio = value;
            this.borderState = sanitizeBorderState(next);
            this.dirty = true;
          },
          onColorChange: (colorArgb: number) => {
            const next = cloneBorderState(this.borderState);
            next.colorArgb = colorArgb;
            this.borderState = sanitizeBorderState(next);
            this.dirty = true;
          },
          onShadowChange: (value: number) => {
            const next = cloneBorderState(this.borderState);
            next.shadowStrength = value;
            this.borderState = sanitizeBorderState(next);
            this.dirty = true;
          },
          onWatermarkChange: (watermark: WatermarkConfig) => {
            const next = cloneBorderState(this.borderState);
            next.watermark = watermark;
            this.borderState = sanitizeBorderState(next);
            this.dirty = true;
          },
          onExtractExif: () => {
            this.loadExifForWatermark();
          },
          onOpenFullPicker: () => {
            this.showBorderPickerModal = true;
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
    // ===== A: Text Layer =====
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.textEditorViewportH = Number(newValue.height);
    })
    // ===== End A =====
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
    // ===== A: Text Layer =====
    this.getUIContext().setKeyboardAvoidMode(key === 'text'
      ? KeyboardAvoidMode.RESIZE_WITH_CARET : this.previousTextKeyboardMode);
    this.isComparing = false;
    // ===== End A =====
    if (key === 'subject' || key === 'background') {
      this.activeRegion = key;
      this.selectedType = REGION_ADJUST_TYPES[0].key;
      if (this.baseImage === undefined) {
        this.baseImage = this.decodedPixelMap ?? this.previewSourcePixelMap ?? this.previewPixelMap;
      }
      this.triggerSegmentation();
    }
    if (key === 'adjust') {
      this.selectedType = ADJUST_TYPES[0].key;
    }
    if (key === 'filter') {
      if (this.filterPrewarmTimer !== -1) {
        clearTimeout(this.filterPrewarmTimer);
        this.filterPrewarmTimer = -1;
      }
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

  // ===== A: Text Layer =====
  private selectTextLayer(id: string): void {
    if (id !== '' && id === this.selectedTextLayerId) {
      this.textSaved = false;
      return;
    }
    this.textValidationMessage = '';
    this.textSaved = false;
    for (let i = 0; i < this.textLayers.length; i++) {
      if (this.textLayers[i].id === id) {
        this.selectedTextLayerId = id;
        this.textInputContent = this.textLayers[i].content;
        this.textValidationMessage = '';
        return;
      }
    }
    this.selectedTextLayerId = '';
    this.textInputContent = '';
  }

  private onTextInput(value: string): void {
    if (this.textInputContent === value) {
      return;
    }
    this.textInputContent = value;
    this.textSaved = false;
    this.syncTextInput();
  }

  private syncTextInput(): boolean {
    const id = 'text-' + this.textLayerSequence;
    const isNew = this.selectedTextLayerId === '';
    const result = applyTextInput(this.textLayers, this.selectedTextLayerId, this.textInputContent, id);
    if (result.error !== '') {
      this.textValidationMessage = result.error;
      return false;
    }
    if (isNew) {
      this.textLayerSequence++;
    }
    this.textLayers = result.layers;
    this.selectedTextLayerId = result.selectedId ?? '';
    this.textValidationMessage = '';
    this.dirty = true;
    return true;
  }

  private confirmTextLayer(): boolean {
    if (!this.syncTextInput()) {
      return false;
    }
    // 保存当前题签，不导出、不退出编辑页，也不清空整张作品的 dirty 状态。
    this.textSaved = true;
    this.toast('文字已保存');
    return true;
  }

  private updateTextLayer(id: string, patch: TextLayerPatch): void {
    if (id === '') {
      return;
    }
    const result = updateTextLayer(this.textLayers, id, patch);
    if (result.error !== '') {
      this.textValidationMessage = result.error;
      return;
    }
    this.textLayers = result.layers;
    this.textSaved = false;
    // 参数变化不能抹掉尚未修正的内容校验错误。
    if (patch.content !== undefined) {
      this.textInputContent = patch.content;
    }
    this.dirty = true;
  }

  private deleteSelectedTextLayer(): void {
    if (this.selectedTextLayerId === '') {
      return;
    }
    const result = deleteTextLayer(this.textLayers, this.selectedTextLayerId, this.selectedTextLayerId);
    this.textLayers = result.layers;
    this.selectedTextLayerId = result.selectedId ?? '';
    this.textInputContent = '';
    if (this.selectedTextLayerId !== '') {
      for (let i = 0; i < this.textLayers.length; i++) {
        if (this.textLayers[i].id === this.selectedTextLayerId) {
          this.textInputContent = this.textLayers[i].content;
          break;
        }
      }
    }
    this.textValidationMessage = '';
    this.textSaved = false;
    this.dirty = true;
  }

  private nextTextLayerSequence(layers: TextLayerModel[]): number {
    let next = 1;
    for (let i = 0; i < layers.length; i++) {
      const prefix = 'text-';
      if (!layers[i].id.startsWith(prefix)) {
        continue;
      }
      const numeric = Number(layers[i].id.substring(prefix.length));
      if (Number.isFinite(numeric) && numeric >= next) {
        next = Math.floor(numeric) + 1;
      }
    }
    return next;
  }
  // ===== End A =====

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

  private addSticker(templateId: string, customUri?: string): void {
    if (this.stickers.length >= STICKER_MAX_COUNT) {
      this.toast('贴纸数量已达上限（最多 12 枚）');
      return;
    }
    const centerX = this.previewDisplayW > 0 ? this.previewDisplayW / 2 : 150;
    const centerY = this.previewDisplayH > 0 ? this.previewDisplayH / 2 : 200;
    const newItem = (customUri !== undefined && customUri !== '')
      ? createCustomStickerInstance(customUri, centerX, centerY)
      : createStickerInstance(templateId, centerX, centerY);
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

  private async uploadCustomSticker(): Promise<void> {
    if (this.stickers.length >= STICKER_MAX_COUNT) {
      this.toast('贴纸数量已达上限（最多 12 枚）');
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const pickResult = await PhotoPickerService.pickSingleImage(context);
      if (pickResult.status === 'cancelled') {
        return;
      }
      if (pickResult.status === 'failed' || !pickResult.sourcePath) {
        this.toast('选择图片失败，请重试');
        return;
      }
      const dir = `${context.filesDir}/stickers`;
      try {
        if (!fs.accessSync(dir)) {
          fs.mkdirSync(dir);
        }
      } catch (_e) {
        try {
          fs.mkdirSync(dir);
        } catch (_e2) {}
      }
      const filename = `custom_${Date.now()}.png`;
      const destPath = `${dir}/${filename}`;
      fs.copyFileSync(pickResult.sourcePath, destPath);

      const tplId = `custom-${Date.now()}`;
      const customTpl: StickerTemplate = {
        id: tplId,
        name: '自定',
        category: 'custom',
        renderType: StickerRenderType.CustomImage,
        resource: null,
        textContent: '',
        defaultSize: 64,
        customUri: destPath
      };
      this.customStickerTemplates.push(customTpl);
      this.addSticker(tplId, destPath);
      this.toast('贴纸已添加');
    } catch (err) {
      console.error(`Upload custom sticker failed: ${JSON.stringify(err)}`);
      this.toast('导入贴纸失败');
    }
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
          zIndex: s.zIndex,
          customUri: s.customUri
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
          zIndex: s.zIndex,
          customUri: s.customUri
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

  private async loadExifForWatermark(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const info = await ExifReaderService.extractWatermarkInfo(this.imageSrc, context);
      const current = this.borderState.watermark ? cloneWatermarkConfig(this.borderState.watermark) : defaultWatermarkConfig();
      if (info.deviceModel && info.deviceModel.trim().length > 0) {
        current.deviceModel = info.deviceModel;
      }
      if (info.logo) {
        current.logo = info.logo;
      }
      if (info.paramsText && info.paramsText.trim().length > 0) {
        current.paramsText = info.paramsText;
      }
      if (info.timeText && info.timeText.trim().length > 0) {
        current.timeText = info.timeText;
      }
      const next = cloneBorderState(this.borderState);
      next.watermark = current;
      this.borderState = sanitizeBorderState(next);
      this.dirty = true;
    } catch (err) {
      console.warn(`Failed to auto-load EXIF for watermark: ${JSON.stringify(err)}`);
    }
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
    this.baseImage = this.decodedPixelMap ?? this.previewSourcePixelMap ?? this.previewPixelMap;

    let fg = output.foregroundImage;
    if (fg === undefined || fg === null) {
      try {
        if (this.baseImage !== undefined) {
          fg = await SubjectSegmentationService.extractForegroundFromMask(
            this.baseImage, output.rawMask.weights, output.rawMask.width, output.rawMask.height);
        }
      } catch (synthErr) {
        hilog.error(0x0000, 'EditPage', 'synthesize foreground image failed: %{public}s', String(synthErr));
      }
    }

    if (fg !== undefined && fg !== null) {
      this.foregroundImage = fg;
      hilog.info(0x0000, 'EditPage', 'foreground image stored');
    } else {
      hilog.warn(0x0000, 'EditPage', 'foreground image not available from segmentation');
      this.foregroundImage = undefined;
    }

    this.dirty = true;
  }

  // ── 保存与导出 ──

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    if (this.textValidationMessage !== '') {
      this.onToolSelect('text');
      this.toast('请先修正题签内容再导出');
      return;
    }

    const shouldPrompt = await AppSettingsStore.isPromptOnExport();
    if (shouldPrompt) {
      this.showExportDialog = true;
      return;
    }

    const defaultSettings = await AppSettingsStore.getExportSettings();
    await this.executeSave(defaultSettings);
  }

  private async executeSave(exportSettings: AppExportSettings): Promise<void> {
    this.showExportDialog = false;
    const snapshot: EditorSnapshot = defaultEditorSnapshot();
    snapshot.filter = { filterId: this.editState.filter.filterId, strength: this.editState.filter.strength };
    snapshot.textLayers = cloneTextLayers(this.textLayers);
    snapshot.border = cloneBorderState(this.borderState);
    snapshot.stickers = this.stickers.map((s: StickerItem): StickerSnapshotItem => {
      const item: StickerSnapshotItem = {
        instanceId: s.instanceId,
        templateId: s.templateId,
        posX: s.posX,
        posY: s.posY,
        size: s.size,
        rotation: s.rotation,
        opacity: s.opacity,
        zIndex: s.zIndex,
        customUri: s.customUri
      };
      return item;
    });
    const adjustments = cloneAdjustments(this.params);
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

      const exportProfile = toExportProfile(exportSettings, sourceUri);

      // 确保滤镜资源已加载
      const filterId = snapshot.filter.filterId;
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
      const composition = await EditorCompositionService.render(
        sourceUri,
        adjustments,
        snapshot,
        exportProfile,
        true,
        context,
        this.unavailableTextFontKeys
      );

      // 编码到 cacheDir
      let cacheFilePath: string;
      try {
        cacheFilePath = await PhotoExportService.encodeToCacheFile(context, composition.pixelMap, exportProfile);
      } finally {
        composition.pixelMap.release();
      }

      if (!cacheFilePath) {
        this.toast('图片编码失败');
        this.saving = false;
        return;
      }

      // 保存作品记录意图初始化
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

      // 若源图不在沙箱持久化目录中，复制到沙箱持久化目录
      let savedUri = fixAndNormalizePath(intent.draft.sourceImageUri);
      try {
        if (savedUri.startsWith('file://') || savedUri.startsWith('/')) {
          const cleanSrc = savedUri.startsWith('file://') ? savedUri.substring(7) : savedUri;
          if (fs.accessSync(cleanSrc) && !cleanSrc.includes(`/works/${record.id}/`)) {
            const sandboxed = await WorkFileService.copySourceToSandbox(context, record.id, cleanSrc);
            savedUri = fixAndNormalizePath(sandboxed);
          }
        }
      } catch (e) {
        hilog.warn(0x0000, 'EditPage', 'copySourceToSandbox warning: %{public}s', String(e));
      }
      record.sourceImageUri = savedUri;

      // 【关键修复】：必须在 PhotoExportService.saveViaDialog 之前将预览图持久化到沙箱！
      // 因为 saveViaDialog 在写入相册或用户取消后都会调用 safeUnlink(cacheFilePath)
      let previewUri = savedUri;
      try {
        previewUri = WorkFileService.savePreviewToSandbox(context, record.id, cacheFilePath);
      } catch (e) {
        hilog.error(0x0000, 'EditPage', 'savePreviewToSandbox error: %{public}s', String(e));
        previewUri = savedUri;
      }
      record.previewImageUri = previewUri;

      // 写入系统相册（内部在完成或取消时会 safeUnlink cacheFilePath）
      const fileName = `Vivid_${Date.now()}`;
      const ext = exportProfile.extension.replace('.', '');
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

      if (exportResult.success && exportResult.mediaUri) {
        record.exportedAssetUri = exportResult.mediaUri;
      }

      record.width = this.imageWidth;
      record.height = this.imageHeight;
      record.adjustments = intent.draft.adjustments;
      record.regionAdjustments = cloneRegionAdjustments(this.regionAdjustments);
      record.editorSnapshot = cloneEditorSnapshot(snapshot);
      record.status = intent.draft.status;
      record.createdAt = now;
      record.updatedAt = now;
      if (intent.mode === SaveMode.Update) {
        mockWorkStore.update(intent.id ?? '', record);
      } else {
        mockWorkStore.create(record);
      }
      draftStore.clear();
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
        message: '当前调整尚未保存，返回将自动存为草稿。',
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
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let savedUri = fixAndNormalizePath(intent.draft.sourceImageUri);
      try {
        if (savedUri.startsWith('file://') || savedUri.startsWith('/')) {
          const cleanSrc = savedUri.startsWith('file://') ? savedUri.substring(7) : savedUri;
          if (fs.accessSync(cleanSrc) && !cleanSrc.includes(`/works/${record.id}/`)) {
            const sandboxed = await WorkFileService.copySourceToSandbox(context, record.id, cleanSrc);
            savedUri = fixAndNormalizePath(sandboxed);
          }
        }
      } catch (e) {
        hilog.warn(0x0000, 'EditPage', 'copySourceToSandbox draft warning: %{public}s', String(e));
      }
      record.sourceImageUri = savedUri;

      const snapshot: EditorSnapshot = defaultEditorSnapshot();
      snapshot.filter = { filterId: this.editState.filter.filterId, strength: this.editState.filter.strength };
      snapshot.textLayers = cloneTextLayers(this.textLayers);
      snapshot.border = cloneBorderState(this.borderState);
      snapshot.stickers = this.stickers.map((s: StickerItem): StickerSnapshotItem => {
        const item: StickerSnapshotItem = {
          instanceId: s.instanceId,
          templateId: s.templateId,
          posX: s.posX,
          posY: s.posY,
          size: s.size,
          rotation: s.rotation,
          opacity: s.opacity,
          zIndex: s.zIndex,
          customUri: s.customUri
        };
        return item;
      });

      // 尝试为草稿渲染生成当前调整效果的预览图，使作品列表展示调整后的草稿
      let previewUri = savedUri;
      try {
        const draftProfile: ExportProfile = {
          mimeType: 'image/jpeg',
          extension: '.jpg',
          maxLongEdge: 1080,
          encoderQuality: 80
        };
        const composition = await EditorCompositionService.render(
          this.imageSrc,
          this.params,
          snapshot,
          draftProfile,
          false,
          context,
          this.unavailableTextFontKeys
        );
        try {
          const cachePath = await PhotoExportService.encodeToCacheFile(context, composition.pixelMap, draftProfile);
          if (cachePath) {
            previewUri = WorkFileService.savePreviewToSandbox(context, record.id, cachePath);
            try {
              if (fs.accessSync(cachePath)) {
                fs.unlinkSync(cachePath);
              }
            } catch (_) {
            }
          }
        } finally {
          composition.pixelMap.release();
        }
      } catch (e) {
        console.warn('Draft preview generation fallback to source:', e);
      }
      record.previewImageUri = previewUri;
      record.editorSnapshot = cloneEditorSnapshot(snapshot);
      record.status = intent.draft.status;
      record.createdAt = now;
      record.updatedAt = now;
      if (intent.mode === SaveMode.Update) {
        mockWorkStore.update(intent.id ?? '', record);
      } else {
        mockWorkStore.create(record);
      }
      draftStore.save({
        imageUri: this.imageSrc,
        displayUri: this.displaySrc,
        adjustments: cloneAdjustments(this.params),
        regionAdjustments: cloneRegionAdjustments(this.regionAdjustments),
        editorSnapshot: cloneEditorSnapshot(snapshot),
        workId: record.id,
        savedAt: now,
        title: `未保存草稿 · ${this.formatDraftTime(now)}`,
        activeTool: this.activeTool,
        previewUri: previewUri
      });
      WorkUiState.bumpRevision();
      this.toast('已存为草稿');
    } catch (_err) {
      // 草稿保存失败不阻断返回
    }

    this.dirty = false;
    this.getUIContext().getRouter().back();
  }

  private persistDraftQuietly(): void {
    if (!this.dirty || !this.imageSrc || this.errorText !== '' || this.disposed) {
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let persistentImageUri = this.imageSrc;

      // 确保正在编辑的源图已固化存储在持久沙箱 filesDir 中（防低内存清理或跨版本更新丢失）
      try {
        if (persistentImageUri.startsWith('file://') || persistentImageUri.startsWith('/')) {
          const rawPath = persistentImageUri.startsWith('file://') ? persistentImageUri.substring(7) : persistentImageUri;
          if (rawPath.includes(context.cacheDir) && fs.accessSync(rawPath)) {
            const draftsDir = `${context.filesDir}/drafts`;
            if (!fs.accessSync(draftsDir)) {
              fs.mkdirSync(draftsDir, true);
            }
            let ext = '.jpg';
            const lower = rawPath.toLowerCase();
            if (lower.endsWith('.png')) {
              ext = '.png';
            } else if (lower.endsWith('.webp')) {
              ext = '.webp';
            }
            const destPath = `${draftsDir}/current_draft_source${ext}`;
            fs.copyFileSync(rawPath, destPath);
            persistentImageUri = `file://${destPath}`;
            this.imageSrc = persistentImageUri;
          }
        }
      } catch (e) {
        hilog.warn(0x0000, 'EditPage', 'persistDraftQuietly copy to sandbox failed: %{public}s', String(e));
      }

      const now = Date.now();
      const snapshot: EditorSnapshot = defaultEditorSnapshot();
      snapshot.filter = { filterId: this.editState.filter.filterId, strength: this.editState.filter.strength };
      snapshot.textLayers = cloneTextLayers(this.textLayers);
      snapshot.border = cloneBorderState(this.borderState);
      snapshot.stickers = this.stickers.map((s: StickerItem): StickerSnapshotItem => {
        const item: StickerSnapshotItem = {
          instanceId: s.instanceId,
          templateId: s.templateId,
          posX: s.posX,
          posY: s.posY,
          size: s.size,
          rotation: s.rotation,
          opacity: s.opacity,
          zIndex: s.zIndex,
          customUri: s.customUri
        };
        return item;
      });

      draftStore.save({
        imageUri: persistentImageUri,
        displayUri: this.displaySrc,
        adjustments: cloneAdjustments(this.params),
        regionAdjustments: cloneRegionAdjustments(this.regionAdjustments),
        editorSnapshot: cloneEditorSnapshot(snapshot),
        workId: this.route?.workId,
        savedAt: now,
        title: `未保存草稿 · ${this.formatDraftTime(now)}`,
        activeTool: this.activeTool,
        previewUri: persistentImageUri
      });
      WorkUiState.bumpRevision();
      hilog.info(0x0000, 'EditPage', 'Auto-saved draft on page hide: %{public}s', persistentImageUri);
    } catch (err) {
      hilog.warn(0x0000, 'EditPage', 'persistDraftQuietly failed: %{public}s', String(err));
    }
  }

  private formatDraftTime(ts: number): string {
    const d = new Date(ts);
    const h = String(d.getHours()).padStart(2, '0');
    const m = String(d.getMinutes()).padStart(2, '0');
    return `${h}:${m}`;
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
