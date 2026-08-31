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
import { componentSnapshot } from '@kit.ArkUI';
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
  /** 底层原图 PixelMap（背景层）。 */
  @State baseImage: image.PixelMap | undefined = undefined;
  /** 上层前景图 PixelMap（透明背景，主体层）。 */
  @State foregroundImage: image.PixelMap | undefined = undefined;
  // ── 贴纸状态 ──
  @State stickers: StickerItem[] = [];
  @State selectedStickerId: string = '';
  /** 预览区实际显示尺寸（vp），由 PreviewArea.onDisplaySizeChange 回传，用于贴纸定位。 */
  @State previewDisplayW: number = 0;
  @State previewDisplayH: number = 0;
  /** 贴纸数据版本计数器：每次修改贴纸数据时递增，触发 StickerLayer @Watch 同步。 */
  @State stickerVersion: number = 0;
  // ── @Provide：选中贴纸的目标值（跨层级响应式，供 StickerLayer @Consume）──
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
        // V2: 恢复区域参数
        if (work.regionAdjustments !== undefined) {
          this.regionAdjustments = cloneRegionAdjustments(work.regionAdjustments);
        }
      } else {
        this.errorText = '作品不存在';
      }
    }
    // 快捷入口传入 initialTool 时直接选中对应工具；无值时保持默认 adjust。
    if (route?.initialTool !== undefined) {
      this.activeTool = route.initialTool;
    }
    // V2：如果初始工具是 subject/background，延迟触发分割
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
    // 释放前景图（由 Core Vision Kit 创建）
    if (this.foregroundImage !== undefined) {
      try {
        this.foregroundImage.release();
      } catch (_e) {
      }
      this.foregroundImage = undefined;
    }
    // 释放背景图（解码后的原图）
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

  private handleToolSelection(key: EditorToolKey): void {
    this.activeTool = key;
    if (key === 'filter') {
      this.loadFilterThumbnails();
    }
    // V2：切换到 subject/background 时触发分割
    if (key === 'subject' || key === 'background') {
      this.activeRegion = key;
      this.selectedType = REGION_ADJUST_TYPES[0].key;
      this.triggerSegmentation();
    }
  }

  private async loadFilterThumbnails(): Promise<void> {
    if (this.imageSrc === '' || this.thumbnailItems.length === FILTER_PRESETS.length ||
        this.loadingThumbnails) {
      return;
    }
    this.loadingThumbnails = true;
    try {
      const source = this.previewSourcePixelMap;
      if (source === undefined) {
        this.loadingThumbnails = false;
        return;
      }
      const items = await this.thumbnailPipeline.buildThumbnails(source, FILTER_PRESETS);
      if (this.disposed) {
        this.loadingThumbnails = false;
        return;
      }
      this.thumbnailItems = items;
    } catch (err) {
      console.error(`Failed to build filter thumbnails: ${JSON.stringify(err)}`);
    } finally {
      this.loadingThumbnails = false;
    }
  }

  private async renderPreview(): Promise<void> {
    const source = this.previewSourcePixelMap;
    if (source === undefined) {
      return;
    }
    try {
      const result = await this.previewPipeline.render({
        source: source,
        adjustments: this.params,
        filterState: this.editState
      });
      if (this.disposed) {
        result.release();
        return;
      }
      this.renderedPreviewOwner.replace(result);
      this.previewPixelMap = result.value;
    } catch (err) {
      console.error(`Failed to render preview: ${JSON.stringify(err)}`);
    }
  }

  private releaseRenderedPreview(): void {
    this.renderedPreviewOwner.release();
    this.previewPixelMap = undefined;
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
          .fontSize(Theme.FONT_SIZE_TITLE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ON_SURFACE)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  errorState() {
    Column() {
      Text(this.errorText)
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  editorBody() {
    Column() {
      // 预览区
      Column() {
        PreviewArea({
          imageSrc: this.displaySrc !== '' ? this.displaySrc : this.imageSrc,
          previewPixelMap: $previewPixelMap,
          previewLoading: this.previewLoading,
          params: this.params,
          isComparing: this.isComparing,
          baseImage: this.baseImage,
          foregroundImage: this.foregroundImage,
          subjectFilter: this.activeRegion === 'subject'
            ? buildAdjustmentFilter(this.regionAdjustments.subject)
            : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
          baseFilter: this.activeRegion === 'background'
            ? buildAdjustmentFilter(this.regionAdjustments.background)
            : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
          stickers: this.stickers,
          stickerMode: this.activeTool === 'sticker',
          selectedStickerId: this.selectedStickerId,
          stickerVersion: this.stickerVersion,
          onCompareChange: (down: boolean) => {
            this.isComparing = down;
          },
          onImageSizeChange: (w: number, h: number) => {
            this.imageWidth = w;
            this.imageHeight = h;
          },
          onStickerSelect: (instanceId: string) => {
            this.selectedStickerId = instanceId;
          },
          onStickerUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => {
            const idx = this.stickers.findIndex((s: StickerItem) => s.instanceId === instanceId);
            if (idx >= 0) {
              const next = this.stickers.slice();
              next[idx] = {
                ...next[idx],
                posX: posX,
                posY: posY,
                size: size,
                rotation: rotation
              };
              this.stickers = next;
              this.dirty = true;
            }
          },
          onDisplaySizeChange: (displayW: number, displayH: number) => {
            this.previewDisplayW = displayW;
            this.previewDisplayH = displayH;
          }
        })
      }
      .layoutWeight(65)
      .width('100%')

      // 参数面板区
      Column() {
        if (this.activeTool === 'adjust') {
          AdjustPanel({
            params: this.params,
            selectedType: this.selectedType,
            onChange: (key: string, value: number) => {
              this.updateParam(key, value);
            },
            onTypeChange: (key: string) => {
              this.selectedType = key;
            }
          })
        } else if (this.activeTool === 'filter') {
          FilterPanel({
            presets: FILTER_PRESETS,
            thumbnails: this.thumbnailItems,
            selectedId: this.editState.filterId,
            onSelect: (id: string) => this.applyFilterSelection(id)
          })
        } else if (this.activeTool === 'sticker') {
          StickerPanel({
            templates: STICKER_TEMPLATES,
            currentCount: this.stickers.length,
            maxCount: STICKER_MAX_COUNT,
            selectedSticker: this.getSelectedSticker(),
            onAdd: (templateId: string) => this.addSticker(templateId),
            onRemove: (instanceId: string) => this.removeSticker(instanceId),
            onUpdate: (instanceId: string, key: string, value: number) =>
              this.updateStickerParam(instanceId, key, value)
          })
        } else if (this.activeTool === 'subject' || this.activeTool === 'background') {
          Column() {
            RegionTabs({
              activeRegion: this.activeRegion,
              onChange: (key: RegionKey) => {
                this.activeRegion = key;
                this.selectedType = REGION_ADJUST_TYPES[0].key;
              }
            })
            AdjustPanel({
              params: this.activeRegion === 'subject'
                ? this.regionAdjustments.subject
                : this.regionAdjustments.background,
              selectedType: this.selectedType,
              onChange: (key: string, value: number) => {
                this.updateRegionParam(key, value);
              },
              onTypeChange: (key: string) => {
                this.selectedType = key;
              }
            })
          }
          .width('100%')
        }
      }
      .layoutWeight(25)
      .width('100%')

      // 底部工具栏
      Column() {
        EditorToolBar({
          tools: EDITOR_TOOLS,
          activeTool: this.activeTool,
          onSelect: (key: EditorToolKey) => this.handleToolSelection(key)
        })
      }
      .layoutWeight(10)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

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
    this.renderPreview();
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

  private getSelectedSticker(): StickerItem | null {
    if (this.selectedStickerId === '') {
      return null;
    }
    return this.stickers.find((s: StickerItem) => s.instanceId === this.selectedStickerId) ?? null;
  }

  private addSticker(templateId: string): void {
    if (this.stickers.length >= STICKER_MAX_COUNT) {
      this.toast(`最多只能添加 ${STICKER_MAX_COUNT} 个贴纸`);
      return;
    }
    const instance = createStickerInstance(templateId, this.previewDisplayW, this.previewDisplayH);
    this.stickers = [...this.stickers, instance];
    this.selectedStickerId = instance.instanceId;
    this.stickerVersion += 1;
    this.dirty = true;
  }

  private removeSticker(instanceId: string): void {
    this.stickers = this.stickers.filter((s: StickerItem) => s.instanceId !== instanceId);
    if (this.selectedStickerId === instanceId) {
      this.selectedStickerId = '';
    }
    this.stickerVersion += 1;
    this.dirty = true;
  }

  private updateStickerParam(instanceId: string, key: string, value: number): void {
    const idx = this.stickers.findIndex((s: StickerItem) => s.instanceId === instanceId);
    if (idx < 0) {
      return;
    }
    const next = this.stickers.slice();
    const current = next[idx];
    if (key === 'size') {
      next[idx] = { ...current, size: value };
      this.stickerTargetSize = value;
    } else if (key === 'rotation') {
      next[idx] = { ...current, rotation: value };
      this.stickerTargetRotation = value;
    } else if (key === 'opacity') {
      next[idx] = { ...current, opacity: value };
      this.stickerTargetOpacity = value;
    }
    this.stickers = next;
    this.stickerVersion += 1;
    this.dirty = true;
  }

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

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    this.saving = true;
    try {
      const settings = AppSettingsStore.getSettings();
      const profile = toExportProfile(settings);
      const intent = buildDraftIntent(this.imageSrc, this.params, profile);
      const title = generateWorkTitle(this.params, this.activeTool);
      const description = generateWorkDescription(this.params, this.activeTool);
      hilog.info(0x0000, 'EditPage', `Saving work: ${title}`);
      hilog.debug(0x0000, 'EditPage', `Description: ${description}`);
      this.toast('已保存（占位）');
    } catch (_err) {
      this.toast('保存失败，请重试');
    } finally {
      this.saving = false;
    }
  }

  private async tryBack(): Promise<void> {
    if (this.dirty && !this.saving) {
      this.getUIContext().showAlertDialog({
        title: '放弃修改？',
        message: '当前编辑尚未保存，返回将丢失所有修改。',
        primaryButton: {
          value: '继续编辑',
          action: () => {}
        },
        secondaryButton: {
          value: '放弃',
          action: () => this.goBack()
        }
      });
    } else {
      this.goBack();
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2000 });
  }
}
