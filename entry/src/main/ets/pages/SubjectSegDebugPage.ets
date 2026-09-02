import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../components/common/Theme';
import { SegmentTabs, SegmentItem } from '../components/common/SegmentTabs';
import { PhotoPickerService, PhotoPickResult } from '../services/PhotoPickerService';
import { getSubjectSegmentationService, SegmentOutcome } from '../services/SubjectSegmentationService';
import { decodeImageFromUri, DecodedImage } from '../utils/ImageDecodeUtils';
import { weightsToGrayRgba, weightsToOverlayRgba } from '../utils/MaskDataUtils';
import { AI_WORK_MAX_EDGE, SegmentationStatus,
  SegErrorCode, segErrorToMessage } from '../models/SegmentationModels';

const TAG = 'SubjectSegDebugPage';



const aa:ESObject=1
/**
 * Debug Mask Viewer（V2 §9 强制要求的四视图调试页，Phase 1 验收工具）。
 *
 * 每次识别必须能查看：
 *   A. Original        原始输入图
 *   B. Subject Rect    红色 Bounding Box（仅证明 AI 判定的大致位置）
 *   C. Raw Mask        mattingList 直读灰度（不经过 MaskProcessor）
 *   D. Mask Overlay    按真实权重混色的朱砂红/青绿叠加
 *
 * 本页仅用于开发期判断异常归属（矩形误用/读取错误/尺寸映射/方向/fullSubject 合并/
 * Core Vision 本身不准），不进正式路由入口；验收前从 main_pages.json 首位移除。
 */
@Entry
@Component
struct SubjectSegDebugPage {
  @State phase: SegmentationStatus = 'idle';
  @State viewKey: string = 'original';
  @State statusText: string = '选择图片后自动执行主体识别';
  @State infoText: string = '';
  @State sourcePixelMap: image.PixelMap | undefined = undefined;
  /** 灰度蒙版 / 叠加视图的 PixelMap（由权重缓冲生成） */
  @State grayPixelMap: image.PixelMap | undefined = undefined;
  @State overlayPixelMap: image.PixelMap | undefined = undefined;
  /** 视图 B 红框（相对显示图的归一化坐标 0~1） */
  @State boxLeftPct: number = 0;
  @State boxTopPct: number = 0;
  @State boxWPct: number = 0;
  @State boxHPct: number = 0;
  private decoded: DecodedImage | null = null;
  /** 显示图实际渲染尺寸（红框换算用） */
  @State displayW: number = 0;
  @State displayH: number = 0;

  private views: SegmentItem[] = [
    { key: 'original', label: '原图' },
    { key: 'rect', label: '红框' },
    { key: 'gray', label: '灰度蒙版' },
    { key: 'overlay', label: '叠加' }
  ];

  aboutToDisappear(): void {
    // V2 §30：离开页面释放会话与像素资源
    getSubjectSegmentationService().invalidate();
    this.releaseDecoded();
  }

  build() {
    Column() {
      Text('Debug · 主体分割四视图')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
        .margin({ top: Theme.SPACE_XL, bottom: Theme.SPACE_MD })

      // ── 视图区 ──
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.viewKey === 'gray' && this.grayPixelMap !== undefined) {
          Image(this.grayPixelMap)
            .width('100%')
            .objectFit(ImageFit.Contain)
            .onAreaChange((_o: Area, n: Area) => this.updateDisplaySize(n))
        } else if (this.viewKey === 'overlay' && this.overlayPixelMap !== undefined) {
          Image(this.overlayPixelMap)
            .width('100%')
            .objectFit(ImageFit.Contain)
            .onAreaChange((_o: Area, n: Area) => this.updateDisplaySize(n))
        } else if (this.sourcePixelMap !== undefined) {
          Image(this.sourcePixelMap)
            .width('100%')
            .objectFit(ImageFit.Contain)
            .onAreaChange((_o: Area, n: Area) => this.updateDisplaySize(n))

          // 视图 B：红色 Bounding Box（归一化坐标 × 实际显示尺寸）
          if (this.viewKey === 'rect' && this.boxWPct > 0) {
            Column()
              .position({
                x: this.boxLeftPct * this.displayW,
                y: this.boxTopPct * this.displayH
              })
              .width(this.boxWPct * this.displayW)
              .height(this.boxHPct * this.displayH)
              .border({ width: Theme.BORDER_WIDTH, color: '#E53935' })
              .hitTestBehavior(HitTestMode.None)
          }
        }

        if (this.phase === 'segmenting' || this.phase === 'preparing') {
          Column({ space: Theme.SPACE_MD }) {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(Theme.PRIMARY)
            Text(this.statusText)
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontColor(Theme.ON_SURFACE)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height('100%')
          .backgroundColor('66000000')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
      .borderRadius(Theme.RADIUS_LG)
      .clip(true)
      .margin({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })

      // ── 信息文本（subjectCount / bounds / mask 尺寸 / 耗时）──
      Scroll() {
        Text(this.infoText === '' ? this.statusText : `${this.statusText}\n${this.infoText}`)
          .fontFamily(Theme.FONT_MONO)
          .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
          .fontColor(Theme.ON_SURFACE_VARIANT)
          .copyOption(CopyOptions.LocalDevice)
          .width('100%')
      }
      .height(84)
      .align(Alignment.TopStart)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: Theme.SPACE_MD })

      // 错误重试按钮
      if (this.phase === 'error') {
        Button('重新识别')
          .type(ButtonType.Capsule)
          .width('60%')
          .backgroundColor(Theme.PRIMARY)
          .onClick(() => this.pickAndSegment())
          .margin({ bottom: Theme.SPACE_MD })
      }

      // ── 四视图切换 ──
      SegmentTabs({
        items: this.views,
        selected: this.viewKey,
        chipMode: true,
        onChange: (key: string) => {
          this.viewKey = key;
        }
      })
        .padding({ top: 0, bottom: Theme.SPACE_XS })

      // ── 选图按钮 ──
      Button(this.phase === 'idle' || this.phase === 'ready' ? '选择图片并识别' : '更换图片')
        .type(ButtonType.Capsule)
        .width('70%')
        .margin({ bottom: Theme.SPACE_3XL })
        .enabled(this.phase !== 'segmenting' && this.phase !== 'preparing')
        .backgroundColor(Theme.SEAL_RED)
        .onClick(() => this.pickAndSegment())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.PAPER_BASE)
  }

  private updateDisplaySize(area: Area): void {
    const w = area.width as number;
    const h = area.height as number;
    if (w > 0 && h > 0 && (w !== this.displayW || h !== this.displayH)) {
      this.displayW = w;
      this.displayH = h;
    }
  }

  private async pickAndSegment(): Promise<void> {
    const pick: PhotoPickResult = await PhotoPickerService.pickSingleImage();
    if (pick.status !== 'selected') {
      this.statusText = pick.status === 'cancelled' ? '已取消选择' : '选图失败，请重试';
      return;
    }

    const service = getSubjectSegmentationService();
    service.invalidate(); // 新图片：作废在途任务

    try {
      // 1. 解码为 RGBA_8888 工作图（最长边 ≤1920）
      this.phase = 'preparing';
      this.statusText = '正在解码图片…';
      this.releaseDecoded();
      this.decoded = await decodeImageFromUri(pick.imageUri, AI_WORK_MAX_EDGE);
      this.sourcePixelMap = this.decoded.pixelMap;
      this.viewKey = 'original';

      // 2. 分割
      this.phase = 'segmenting';
      this.statusText = '正在识别主体…';
      const startedAt = Date.now();
      const outcome: SegmentOutcome = await service.segment(this.decoded.pixelMap);

      if (outcome.status === 'noSubject') {
        this.phase = 'error';
        this.statusText = segErrorToMessage('NO_SUBJECT');
        this.infoText = `subjectCount=0\n耗时 ${Date.now() - startedAt}ms`;
        return;
      }
      if (outcome.status === 'error') {
        const code: SegErrorCode = outcome.code ?? 'SDK_ERROR';
        this.phase = 'error';
        this.statusText = segErrorToMessage(code);
        this.infoText = `errorCode=${code}\n耗时 ${Date.now() - startedAt}ms`;
        return;
      }

      // 3. 生成 Debug 视图缓冲（C/D）
      this.phase = 'processingMask';
      this.statusText = '正在生成调试视图…';
      const output = outcome.output!;
      const mask = output.rawMask;
      this.grayPixelMap = await this.bufferToPixelMap(
        weightsToGrayRgba(mask.weights), mask.width, mask.height);
      this.overlayPixelMap = await this.bufferToPixelMap(
        weightsToOverlayRgba(mask.weights, [178, 59, 47], [44, 98, 180], 165),
        mask.width, mask.height);

      // 4. 红框（B）：bounds 归一化到 0~1
      const b = output.subjectBounds;
      this.boxLeftPct = mask.width > 0 ? b.left / mask.width : 0;
      this.boxTopPct = mask.height > 0 ? b.top / mask.height : 0;
      this.boxWPct = mask.width > 0 ? b.width / mask.width : 0;
      this.boxHPct = mask.height > 0 ? b.height / mask.height : 0;

      this.phase = 'ready';
      const elapsed = Date.now() - startedAt;
      this.statusText = `主体已识别（耗时 ${elapsed}ms）`;
      this.infoText =
        `subjectCount=${outcome.output?.subjectCount}\n` +
        `mask=${mask.width}x${mask.height}\n` +
        `rect=(L${b.left}, T${b.top}, W${b.width}, H${b.height})`;
    } catch (err) {
      hilog.error(0x0000, TAG, 'debug flow failed: %{public}s', (err as Error).message);
      this.phase = 'error';
      this.statusText = (err as Error).message === 'DECODE_FAILED'
        ? '图片解码失败，请换一张图片'
        : '处理失败，请重试';
    }
  }

  /** RGBA 缓冲 → 可显示 PixelMap。 */
  private async bufferToPixelMap(
    rgba: Uint8Array,
    width: number,
    height: number
  ): Promise<image.PixelMap> {
    const size = width * height * 4;
    const buffer = new ArrayBuffer(size);
    new Uint8Array(buffer).set(rgba);
    const opts: image.InitializationOptions = {
      size: { width: width, height: height },
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: false
    };
    return image.createPixelMap(buffer, opts);
  }

  private releaseDecoded(): void {
    if (this.decoded !== null) {
      try {
        this.decoded.pixelMap.release();
      } catch (_e) {
        // 已释放时忽略
      }
      this.decoded = null;
    }
    this.sourcePixelMap = undefined;
    this.grayPixelMap = undefined;
    this.overlayPixelMap = undefined;
  }
}
