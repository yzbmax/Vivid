import { BorderState, defaultBorderState } from '../../models/SharedContracts';
import { BorderGeometry, resolveBorderGeometry } from '../../features/editor/border/BorderLayoutResolver';
import { paintBorder } from '../../features/editor/border/BorderPainter';
import { LogoAssetManager } from '../../features/editor/border/LogoAssetManager';
import { LengthMetricsUnit } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/** 仅画装裱，照片和交互图层由 PreviewArea 放在其上，避免遮住调色效果。 */
@Component
export struct BorderPreviewLayer {
  @Prop @Watch('ensureLogoAndRedraw') borderState: BorderState = defaultBorderState();
  @Prop @Watch('redraw') geometry: BorderGeometry = resolveBorderGeometry({
    photoWidth: 1, photoHeight: 1, border: defaultBorderState()
  });
  // 与导出一致：context.width/height、阴影和字体全部使用实际像素。
  private context: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true), LengthMetricsUnit.PX);
  private ready: boolean = false;

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .onReady(() => {
        this.ready = true;
        this.ensureLogoAndRedraw();
      })
      .onAreaChange(() => this.redraw())
  }

  private async ensureLogoAndRedraw(): Promise<void> {
    const logo = this.borderState.watermark?.logo;
    if (this.borderState.watermark?.showLogo && logo && logo !== 'none' && !LogoAssetManager.getPixelMapSync(logo)) {
      try {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        await LogoAssetManager.loadLogoPixelMap(logo, ctx);
      } catch (_) {}
    }
    this.redraw();
  }

  private redraw(): void {
    if (!this.ready || this.context.width <= 0 || this.context.height <= 0) {
      return;
    }
    this.context.clearRect(0, 0, this.context.width, this.context.height);
    const scale = Math.min(this.context.width / this.geometry.outputWidth, this.context.height / this.geometry.outputHeight);
    paintBorder(this.context, this.geometry, this.borderState, scale);
  }
}
