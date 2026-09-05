
import { Theme } from './Theme';

/**
 * 全局宣纸背景：宣纸灰底（Theme.PAPER_BASE）+ Canvas 细网格（横纵各 gridSize 一条，色取 Theme.GRID_LINE）+ 顶部朱砂柔光。
 * 作为一级页面与独立编辑页的根容器，子内容通过 @BuilderParam children 注入。
 * 参考：docs/公共组件预留文档.md A1。
 */
@Component
export struct PaperBackground {
  /** 子内容（页面主体，位于背景之上） */
  @BuilderParam
  children: () => void = this.defaultSlot;

  @Builder
  defaultSlot() {
  }

  private settings: RenderingContextSettings =
    new RenderingContextSettings(true);

  private context: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.settings);

  // 网格间距（vp）
  private readonly gridSize: number = 32;

  /** 绘制横纵细网格（颜色取 Theme.GRID_LINE，不写死） */
  private drawGrid(): void {
    const width: number = this.context.width;
    const height: number = this.context.height;

    if (width <= 0 || height <= 0) {
      return;
    }

    // 防止重复绘制叠加
    this.context.clearRect(0, 0, width, height);

    // 网格视觉参数
    this.context.strokeStyle = Theme.GRID_LINE;
    this.context.lineWidth = 1;

    this.context.beginPath();

    // 横线：每隔 gridSize(vp) 自动绘制到页面底部
    for (let y: number = this.gridSize; y <= height; y += this.gridSize) {
      this.context.moveTo(0, y);
      this.context.lineTo(width, y);
    }

    // 竖线：每隔 gridSize(vp) 自动绘制到页面右侧
    for (let x: number = this.gridSize; x <= width; x += this.gridSize) {
      this.context.moveTo(x, 0);
      this.context.lineTo(x, height);
    }

    // 一次性提交所有网格线
    this.context.stroke();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1) 网格层：透明 Canvas 仅画线（底色由根 Stack 提供；扩展进安全区）
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [
            SafeAreaEdge.TOP,
            SafeAreaEdge.BOTTOM,
            SafeAreaEdge.START,
            SafeAreaEdge.END
          ]
        )
        .onReady(() => {
          this.drawGrid();
        })

      // 2) 顶部柔光（装饰层，不拦截点击）
      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: [0.5, 0.0],
          radius: 1.0,
          // 本 SDK 中 colors 元组顺序为 [颜色, 偏移]（ResourceColor, number）
          colors: [['#0D9B2F2F', 0.0], ['#009B2F2F', 0.7]]
        })
        .hitTestBehavior(HitTestMode.None)

      // 3) 子内容（顶部避让由页面内的统一 PageHeader 负责，背景网格/柔光铺满全屏）
      Column() {
        this.children()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.PAPER_BASE)
  }
}
