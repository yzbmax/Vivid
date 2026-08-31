import { AdjustEffects, AdjustParams, mapParamsToEffects } from '../../models/EditModels';
import { Theme } from '../common/Theme';
import { image } from '@kit.ImageKit';
import {
  fitPreviewCard,
  hasRenderablePreview,
  shouldRenderUriFallback
} from '../../services/PreviewPipeline';

/**
 * 预览区：照片 + 装裱边框 + 原图对比按压层。
 *
 * 效果：曝光/亮度 → 明暗覆盖层；对比度/饱和度 → 组件 contrast()/saturate()。
 * 原图对比（isComparing=true）时隐藏全部效果，显示原图。
 * imageSrc 为空时显示占位（如 source=work 待 B 的 WorkRecord 源图字段接入）。
 *
 * 卡片布局：Stack 宽度撑满预览区域，高度按图片原始比例计算；
 * 整块卡片在可用区域内上下居中；clip(true) 防止溢出遮挡其他元素。
 */
@Component
export struct PreviewArea {
  @Prop imageSrc: string = '';
  @Link previewPixelMap: image.PixelMap | undefined;
  @Prop previewLoading: boolean = false;
  @Prop params: AdjustParams = { exposure: 0, brightness: 0, contrast: 0, saturation: 0 };
  @Prop isComparing: boolean = false;
  onCompareChange: (down: boolean) => void = () => {};
  /** 图片加载完成后回传原始像素尺寸 */
  onImageSizeChange: (w: number, h: number) => void = () => {};

  /** 预览区域可用尺寸（由外层 Column onAreaChange 更新）。 */
  @State containerW: number = 0;
  @State containerH: number = 0;
  /** 图片原始像素尺寸（由 Image onComplete 回写）。 */
  @State imageNaturalW: number = 0;
  @State imageNaturalH: number = 0;

  build() {
    // 外层 Column：负责上下居中 + 裁剪溢出
    Column() {
      if (this.previewPixelMap !== undefined ||
          shouldRenderUriFallback(this.imageSrc, false, this.previewLoading)) {
        // 内层 Column：按内容自适应尺寸，由外层 justifyContent 居中
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            // 照片（优先使用最长边 <= 1440 的 PreviewSourcePixelMap）
            if (this.previewPixelMap !== undefined) {
              Image(this.previewPixelMap)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .contrast(this.isComparing ? 1 : this.effects().contrast)
                .saturate(this.isComparing ? 1 : this.effects().saturate)
                .onAppear(() => console.info('Editor preview PixelMap node mounted'))
                .onAreaChange((_oldValue: Area, newValue: Area) => {
                  console.info(`Editor preview PixelMap area: ${newValue.width}x${newValue.height}`);
                })
                .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
                .onError(() => console.error('Editor preview PixelMap image failed'))
            } else if (shouldRenderUriFallback(this.imageSrc, false, this.previewLoading)) {
              Image(this.imageSrc)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .contrast(this.isComparing ? 1 : this.effects().contrast)
                .saturate(this.isComparing ? 1 : this.effects().saturate)
                .onAppear(() => console.info('Editor preview URI node mounted'))
                .onAreaChange((_oldValue: Area, newValue: Area) => {
                  console.info(`Editor preview URI area: ${newValue.width}x${newValue.height}`);
                })
                .onComplete((event) => this.updateNaturalSize(event?.width ?? 0, event?.height ?? 0))
                .onError(() => console.error('Editor preview URI image failed'))
            }

            // 明暗覆盖层（曝光/亮度）
            if (!this.isComparing && this.effects().luminanceAlpha > 0) {
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(this.effects().luminanceLight ? '#FFFFFF' : '#000000')
                .opacity(this.effects().luminanceAlpha)
                .hitTestBehavior(HitTestMode.None)
            }

            // 装裱边框：外层细线 + 内衬留白 + 朱砂内线（直角偏方）
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
          .width(this.displayW())
          .height(this.displayH())
          .clip(true)
          .backgroundColor(Theme.SURFACE_CONTAINER_LOWEST)
        }
      } else if (this.previewLoading) {
        Column({ space: 8 }) {
          Text('正在显影…')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(Theme.FONT_SIZE_BODY_MD)
            .fontColor(Theme.ON_SURFACE_VARIANT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 无图片：占位（如 source=work 待 WorkRecord 源图字段接入）
        Column({ space: 8 }) {
          Text('预览区占位')
            .fontFamily(Theme.FONT_SERIF)
            .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
            .fontWeight(600)
            .fontColor(Theme.ON_SURFACE)
          Text('作品源图恢复待 WorkRecord 字段接入')
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
        console.info(`Editor preview area ready: ${w}x${h}`);
      }
    })
    .onTouch((event: TouchEvent) => {
      if (!hasRenderablePreview('', this.previewPixelMap !== undefined) &&
          !shouldRenderUriFallback(this.imageSrc, false, this.previewLoading)) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.onCompareChange(true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onCompareChange(false);
      }
    })
  }

  /** 图片尺寸未知时先使用容器尺寸，避免自适应父子形成百分比循环。 */
  private displayW(): number {
    return fitPreviewCard(
      this.containerW,
      this.containerH,
      this.imageNaturalW,
      this.imageNaturalH
    ).width;
  }

  private displayH(): number {
    return fitPreviewCard(
      this.containerW,
      this.containerH,
      this.imageNaturalW,
      this.imageNaturalH
    ).height;
  }

  private effects(): AdjustEffects {
    return mapParamsToEffects(this.params);
  }

  private updateNaturalSize(width: number, height: number): void {
    if (width > 0 && height > 0 && (width !== this.imageNaturalW || height !== this.imageNaturalH)) {
      this.imageNaturalW = width;
      this.imageNaturalH = height;
      console.info(`Editor preview image ready: ${width}x${height}`);
      this.onImageSizeChange(width, height);
    }
  }
}
