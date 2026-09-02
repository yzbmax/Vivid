import { BorderState } from '../../models/SharedContracts';
import { resolveBorderGeometry, BorderGeometry } from '../../features/editor/border/BorderLayoutResolver';
import { defaultColorForTemplate } from '../../features/editor/border/BorderState';
import { Theme } from '../common/Theme';
import { image } from '@kit.ImageKit';

/**
 * 边框预览层（实施计划 任务 6）。
 *
 * 在预览区最外层绘制「照片 + 边框」合成效果：
 * - 外层容器 = 输出画布（按 BorderGeometry 的 output 尺寸）
 * - 内层照片 = 按 photoRect 定位，完整保留，不裁切
 * - 装饰元素：sprocket / innerLine / cornerMark / filmNumber 按几何位置绘制
 *
 * 该组件本身不关心外部可用尺寸；由 EditPage 根据预览区可用尺寸等比缩放。
 *
 * 简化约定：
 * - 投影用半透明黑色外扩模拟（floating_shadow / scroll_mount）
 * - 胶片齿孔使用深色圆点代替真实渲染（Task 8 的高清合成用 PixelMap 绘制）
 */
@Component
export struct BorderPreviewLayer {
  /** 原图 URI（CSS 模式）或 PixelMap（已解码）。 */
  @Prop imageSrc: string = '';
  @Link previewPixelMap: image.PixelMap | undefined;
  /** 当前边框状态。 */
  @Prop border: BorderState = {
    templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0
  };
  /** 照片像素尺寸（由 PreviewArea 通过 onImageSizeChange 回传）。 */
  @Prop photoNaturalW: number = 0;
  @Prop photoNaturalH: number = 0;
  /** 原图对比模式：true 时隐藏边框。 */
  @Prop isComparing: boolean = false;

  build() {
    if (this.isComparing || this.border.templateId === 'none' || this.photoNaturalW === 0) {
      // 无装饰：直接显示原图
      this.photoContent()
    } else {
      // 解析几何
      Stack() {
        // 外层：输出画布（边框色）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.argbToHex(this.frameColor()))

        // 投影层（仅 floating_shadow / scroll_mount）
        if (this.hasShadow()) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(this.border.shadowStrength * 0.3)
        }

        // 内层：照片区域
        Stack() {
          this.photoContent()
        }
        .width(this.photoPercentWidth() + '%')
        .height(this.photoPercentHeight() + '%')
        .position({
          x: this.photoPercentX() + '%',
          y: this.photoPercentY() + '%'
        })

        // 装饰层
        this.decorationOverlay()
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  photoContent() {
    if (this.previewPixelMap !== undefined) {
      Image(this.previewPixelMap)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
    } else if (this.imageSrc !== '') {
      Image(this.imageSrc)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
    } else {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.SURFACE_CONTAINER_HIGHEST)
    }
  }

  @Builder
  decorationOverlay() {
    // 卷轴装裱：朱砂内线 + 四角标
    if (this.border.templateId === 'scroll_mount') {
      Column()
        .width('100%')
        .height('100%')
        .border({
          width: this.scrollLineThicknessVp(),
          color: Theme.SEAL_RED,
          style: BorderStyle.Solid
        })
        .margin({
          left: this.scrollInsetVp() + 'vp',
          top: this.scrollInsetVp() + 'vp',
          right: this.scrollInsetVp() + 'vp',
          bottom: this.scrollInsetVp() + 'vp'
        })
    }
    // 胶片：左右齿孔简化为两条深色虚线（预览效果；高清合成由 Task 8 处理）
    if (this.border.templateId === 'film_negative') {
      Row() {
        Column()
          .width(this.filmSprocketWidthVp() + 'vp')
          .height('100%')
          .backgroundColor('#1A1A1A')
          .opacity(0.6)
        Blank()
        Column()
          .width(this.filmSprocketWidthVp() + 'vp')
          .height('100%')
          .backgroundColor('#1A1A1A')
          .opacity(0.6)
      }
      .width('100%')
      .height('100%')
    }
  }

  // ───────────────── 几何计算（百分比，供 ArkUI 布局使用）─────────────────

  private geometry(): BorderGeometry {
    return resolveBorderGeometry({
      photoWidth: this.photoNaturalW,
      photoHeight: this.photoNaturalH,
      border: this.border
    });
  }

  private photoPercentWidth(): number {
    const g = this.geometry();
    return (g.photoRect.width / g.outputWidth) * 100;
  }

  private photoPercentHeight(): number {
    const g = this.geometry();
    return (g.photoRect.height / g.outputHeight) * 100;
  }

  private photoPercentX(): number {
    const g = this.geometry();
    return (g.photoRect.x / g.outputWidth) * 100;
  }

  private photoPercentY(): number {
    const g = this.geometry();
    return (g.photoRect.y / g.outputHeight) * 100;
  }

  private frameColor(): number {
    if (this.border.templateId === 'none') {
      return 0xFFFFFFFF;
    }
    // 如果模板不支持 color，使用 BorderState 的默认色
    if (this.border.colorArgb === 0) {
      return defaultColorForTemplate(this.border.templateId);
    }
    return this.border.colorArgb;
  }

  private hasShadow(): boolean {
    return this.border.shadowStrength > 0 &&
      (this.border.templateId === 'floating_shadow' || this.border.templateId === 'scroll_mount');
  }

  private scrollInsetVp(): number {
    // 近似：按照片短边的 widthRatio × 0.25 转换为 vp
    const shortEdgeVp = Math.min(this.photoNaturalW, this.photoNaturalH) / 4;
    return Math.max(2, shortEdgeVp * this.border.widthRatio * 0.25);
  }

  private scrollLineThicknessVp(): number {
    return Math.max(1, this.scrollInsetVp() * 0.08);
  }

  private filmSprocketWidthVp(): number {
    const shortEdgeVp = Math.min(this.photoNaturalW, this.photoNaturalH) / 4;
    return Math.max(2, shortEdgeVp * this.border.widthRatio * 0.4);
  }

  private argbToHex(argb: number): string {
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    const hex = (n: number): string => {
      const s = n.toString(16);
      return s.length < 2 ? '0' + s : s;
    };
    return '#' + hex(r) + hex(g) + hex(b);
  }
}
