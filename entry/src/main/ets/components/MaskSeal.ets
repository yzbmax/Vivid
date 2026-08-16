export class MaskSealPalette {
  static readonly paperBase: string = '#deddd7';
  static readonly paperSurface: string = '#f2f1ed';
  static readonly ink: string = '#241918';
  static readonly inkMuted: string = '#574140';
  static readonly primary: string = '#7b171b';
  static readonly sealRed: string = '#b23b2f';
  static readonly outline: string = '#8b716f';
  static readonly outlineLight: string = '#debfbd';
  static readonly surface: string = '#fff8f7';
  static readonly surfaceContainer: string = '#ffe9e7';
  static readonly error: string = '#ba1a1a';
  static readonly tertiary: string = '#004645';
}

export class MASK_SEAL extends MaskSealPalette {}

@Component
export struct SealPaperBackground {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private readonly gridSize: number = 32;
  private readonly horizontalLineCount: number = 20;
  private readonly verticalLineCount: number = 12;

  private drawGrid(): void {
    const width: number = this.context.width;
    const height: number = this.context.height;

    if (width <= 0 || height <= 0) {
      return;
    }

    // 清空画布，避免重复绘制时叠加
    this.context.clearRect(0, 0, width, height);

    // 保持原来的网格视觉参数
    this.context.strokeStyle = 'rgba(209, 191, 187, 0.34)';
    this.context.lineWidth = 1;

    // 所有网格线放进同一个 Path，一次 stroke 完成
    this.context.beginPath();

    // 原来 Column 中的 20 条横线
    for (let index: number = 1; index <= this.horizontalLineCount; index++) {
      const y: number = index * this.gridSize;

      this.context.moveTo(0, y);
      this.context.lineTo(width, y);
    }

    // 原来 Row 中的 12 条竖线
    for (let index: number = 1; index <= this.verticalLineCount; index++) {
      const x: number = index * this.gridSize;

      this.context.moveTo(x, 0);
      this.context.lineTo(x, height);
    }

    this.context.stroke();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 网格背景：
      // 原来的 32 个 Blank 收敛为一个 Canvas
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.drawGrid();
        });

      // 四角装饰保持原样
      Column() {
        Row() {
          Image($r('app.media.L'))
            .width(24)
            .height(24)
            .rotate({ angle: 90 });

          Blank()
            .layoutWeight(1);

          Image($r('app.media.L'))
            .width(24)
            .height(24)
            .rotate({ angle: 180 });
        }
        .width('100%');

        Blank()
          .layoutWeight(1);

        Row() {
          Image($r('app.media.L'))
            .width(24)
            .height(24);

          Blank()
            .layoutWeight(1);

          Image($r('app.media.L'))
            .width(24)
            .height(24)
            .rotate({ angle: 270 });
        }
        .width('100%');
      }
      .width('100%')
      .height('100%')
      .padding({
        left: 10,
        right: 10,
        top: 80,
        bottom: 10
      });
    }
    .width('100%')
    .height('100%')
    .expandSafeArea(
      [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
      [
        SafeAreaEdge.TOP,
        SafeAreaEdge.BOTTOM,
        SafeAreaEdge.START,
        SafeAreaEdge.END
      ]
    )
    .backgroundColor(MaskSealPalette.paperBase);
  }
}

export class SealButtonParams {
  text: string = '';
  secondary: boolean = false;
  onTap: () => void = () => {};
}

@Builder
export function SealButton($$: SealButtonParams) {
  Button($$.text)
    .width('100%')
    .height(52)
    .fontFamily('Noto Serif SC')
    .fontWeight(FontWeight.Bold)
    .fontSize(18)
    .fontColor($$.secondary ? MaskSealPalette.primary : Color.White)
    .backgroundColor($$.secondary ? Color.Transparent : MaskSealPalette.primary)
    .border({ width: 1, color: $$.secondary ? '#c8a4a0' : MaskSealPalette.primary })
    .borderRadius(4)
    .onClick(() => $$.onTap());
}

export class FloatingInputParams {
  value: string = '';
  label: string = '';
  error: string = '';
  layoutWeight: number = 0;
  onChange: (value: string) => void = (_value: string) => {};
}

@Builder
export function FloatingInput($$: FloatingInputParams) {
  Column({ space: 5 }) {
    Stack({ alignContent: Alignment.TopStart }) {
      Text($$.label)
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor(MaskSealPalette.primary)
        .padding({ left: 5, right: 5 })
        .backgroundColor(MaskSealPalette.paperSurface)
        .margin({ left: 12, top: -8 })
        .zIndex(1);
      TextInput({ text: $$.value, placeholder: $$.label })
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontColor(MaskSealPalette.ink)
        .placeholderColor('#957d7a')
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $$.error ? MaskSealPalette.error : MaskSealPalette.outlineLight })
        .borderRadius(4)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => $$.onChange(value));
    }
    if ($$.error.length > 0) {
      Text($$.error)
        .fontSize(12)
        .fontColor(MaskSealPalette.error)
        .padding({ left: 4 });
    }
  }
  .width('100%')
  .layoutWeight($$.layoutWeight);
}

export class SettingRowParams {
  title: string = '';
  detail: string = '';
  interactive: boolean = true;
  onTap: () => void = () => {};
}

@Builder
export function SettingRow($$: SettingRowParams) {
  Row() {
    Column({ space: 3 }) {
      Text($$.title)
        .fontSize(16)
        .fontColor(MaskSealPalette.ink);
      if ($$.detail.length > 0) {
        Text($$.detail)
          .fontFamily('monospace')
          .fontSize(11)
          .fontColor(MaskSealPalette.inkMuted);
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start);
    Text($$.interactive ? '›' : '')
      .fontSize(24)
      .fontColor(MaskSealPalette.primary);
  }
  .width('100%')
  .padding({ left: 18, right: 16, top: 15, bottom: 15 })
  .backgroundColor(MaskSealPalette.paperSurface)
  .border({ width: { bottom: 1 }, color: '#eadbd7' })
  .onClick(() => $$.onTap());
}
