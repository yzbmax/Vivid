import {
  AdjustEffects, AdjustParams, mapParamsToEffects,
  StickerItem, StickerTemplate, findStickerTemplate
} from '../../models/EditModels';
import { Theme } from '../common/Theme';
import { image } from '@kit.ImageKit';
import { StickerLayer } from './StickerLayer';

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
    // 外层 Column：负责上下居中 + 裁剪溢出
    Column() {
      if (this.baseImage !== undefined && this.foregroundImage !== undefined && !this.isComparing) {
        // ── 双图 colorFilter 模式（主体分割完成后）──
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            // 底层：原图 + 背景调色
            Image(this.baseImage)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .colorFilter(this.baseFilter)
              .accessibilityDescription('原图（背景调色）')

            // 上层：前景图 + 主体调色（叠放在底层之上）
            Image(this.foregroundImage)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .colorFilter(this.subjectFilter)
              .accessibilityDescription('前景（主体调色）')

            // 贴纸层
            ForEach(this.stickers, (item: StickerItem) => {
              StickerLayer({
                item: item,
                template: this.findTpl(item.templateId),
                isSelected: this.selectedStickerId === item.instanceId,
                onUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => {
                  this.onStickerUpdate(instanceId, posX, posY, size, rotation);
                },
                onSelect: (instanceId: string) => {
                  this.onStickerSelect(instanceId);
                }
              })
            }, (item: StickerItem) => item.instanceId)

            // 装裱边框
            Column() {
              Column()
                .width('100%')
                .height('100%')
                .border({ width: 1, color: Theme.PRIMARY_20 })
            }
            .width('100%')
            .height('100%')
            .border({ width: 1, color: Theme.OUTLINE_VARIANT })
            .padding(8)
            .hitTestBehavior(HitTestMode.None)
          }
          .width('100%')
          .height(this.displayH())
          .clip(true)
          .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
          .id(PREVIEW_STACK_ID)
        }
      } else if (this.baseImage !== undefined && this.isComparing) {
        // ── 原图对比模式（双图模式下按对比按钮）──
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Image(this.baseImage)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)

            // 装裱边框
            Column() {
              Column()
                .width('100%')
                .height('100%')
                .border({ width: 1, color: Theme.PRIMARY_20 })
            }
            .width('100%')
            .height('100%')
            .border({ width: 1, color: Theme.OUTLINE_VARIANT })
            .padding(8)
            .hitTestBehavior(HitTestMode.None)

            // 原图对比提示胶囊
            Text('原图')
              .fontFamily(Theme.FONT_MONO)
              .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
              .fontColor(Theme.ON_PRIMARY)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(Theme.PRIMARY)
              .borderRadius(Theme.RADIUS_FULL)
          }
          .width('100%')
          .height(this.displayH())
          .clip(true)
          .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
        }
      } else if (this.imageSrc !== '') {
        // ── CSS 效果模式（未分割时的全局调色 / 对比模式）──
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Image(this.imageSrc)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .contrast(this.isComparing ? 1 : this.effects().contrast)
              .saturate(this.isComparing ? 1 : this.effects().saturate)
              .onComplete((event) => {
                const w = event?.width ?? 0;
                const h = event?.height ?? 0;
                if (w > 0 && h > 0 && (w !== this.imageNaturalW || h !== this.imageNaturalH)) {
                  this.imageNaturalW = w;
                  this.imageNaturalH = h;
                  this.onImageSizeChange(w, h);
                  this.onDisplaySizeChange(this.containerW, this.displayH());
                }
              })

            // 明暗覆盖层（曝光/亮度）
            if (!this.isComparing && this.effects().luminanceAlpha > 0) {
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(this.effects().luminanceLight ? '#FFFFFF' : '#000000')
                .opacity(this.effects().luminanceAlpha)
                .hitTestBehavior(HitTestMode.None)
            }

            // 贴纸层（非对比模式时显示）
            if (!this.isComparing) {
              ForEach(this.stickers, (item: StickerItem) => {
                StickerLayer({
                  item: item,
                  template: this.findTpl(item.templateId),
                  isSelected: this.selectedStickerId === item.instanceId,
                  onUpdate: (instanceId: string, posX: number, posY: number, size: number, rotation: number) => {
                    this.onStickerUpdate(instanceId, posX, posY, size, rotation);
                  },
                  onSelect: (instanceId: string) => {
                    this.onStickerSelect(instanceId);
                  }
                })
              }, (item: StickerItem) => item.instanceId)
            }

            // 装裱边框
            Column() {
              Column()
                .width('100%')
                .height('100%')
                .border({ width: 1, color: Theme.PRIMARY_20 })
            }
            .width('100%')
            .height('100%')
            .border({ width: 1, color: Theme.OUTLINE_VARIANT })
            .padding(8)
            .hitTestBehavior(HitTestMode.None)

            // 原图对比提示胶囊
            if (this.isComparing) {
              Text('原图')
                .fontFamily(Theme.FONT_MONO)
                .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
                .fontColor(Theme.ON_PRIMARY)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(Theme.PRIMARY)
                .borderRadius(Theme.RADIUS_FULL)
            }
          }
          .width('100%')
          .height(this.displayH())
          .clip(true)
          .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
          .id(PREVIEW_STACK_ID)
        }
      } else {
        // 无图片：占位
        Column({ space: 8 }) {
          Text('预览区占位')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
            .fontWeight(600)
            .fontColor(Theme.ON_SURFACE)
          Text('请选择图片或加载作品')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.ON_SURFACE_VARIANT_70)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(24)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .clip(true)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const w = newValue.width as number;
      const h = newValue.height as number;
      if (w > 0 && h > 0 && (w !== this.containerW || h !== this.containerH)) {
        this.containerW = w;
        this.containerH = h;
        this.onDisplaySizeChange(this.containerW, this.displayH());
      }
    })
    .onTouch((event: TouchEvent) => {
      // 贴纸模式下禁用按住对比，避免与贴纸手势冲突
      if (this.stickerMode) {
        return;
      }
      if (this.imageSrc === '' && this.baseImage === undefined) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.onCompareChange(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onCompareChange(false);
      }
    })
  }

  /**
   * 卡片显示高度：宽度撑满（100%），高度按图片原始比例计算。
   * 图片原始尺寸未就绪时回退到容器高度。
   */
  private displayH(): number {
    if (this.containerW <= 0 || this.containerH <= 0) {
      return 0;
    }
    const nw = this.imageNaturalW;
    const nh = this.imageNaturalH;
    if (nw <= 0 || nh <= 0) {
      return this.containerH;
    }
    // 宽度撑满，按图片比例算高度
    const ratio = nh / nw;
    return Math.floor(this.containerW * ratio);
  }

  private effects(): AdjustEffects {
    return mapParamsToEffects(this.params);
  }

  /** 根据 templateId 查找贴纸模板。 */
  private findTpl(templateId: string): StickerTemplate | null {
    return findStickerTemplate(templateId);
  }
}
