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
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], () => {
          Blank()
            .width('100%')
            .height(32)
            .border({ width: { bottom: 1 }, color: '#d1bfbb' });
        });
      }
      .width('100%')
      .opacity(0.34);

      Row() {
        ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], () => {
          Blank()
            .width(32)
            .height('100%')
            .border({ width: { right: 1 }, color: '#d1bfbb' });
        });
      }
      .width('100%')
      .height('100%')
      .opacity(0.34);

      Column() {
        Row() {
          Blank().width(18).height(18).border({ width: { left: 2, top: 2 }, color: MaskSealPalette.primary });
          Blank().layoutWeight(1);
          Blank().width(18).height(18).border({ width: { right: 2, top: 2 }, color: MaskSealPalette.primary });
        }
        .width('100%');
        Blank().layoutWeight(1);
        Row() {
          Blank().width(18).height(18).border({ width: { left: 2, bottom: 2 }, color: MaskSealPalette.primary });
          Blank().layoutWeight(1);
          Blank().width(18).height(18).border({ width: { right: 2, bottom: 2 }, color: MaskSealPalette.primary });
        }
        .width('100%');
      }
      .width('100%')
      .height('100%')
      .padding(10);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MaskSealPalette.paperBase);
  }
}

@Component
export struct SealPageHeader {
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop onBack: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Text('‹')
          .fontSize(36)
          .fontColor(MaskSealPalette.ink)
          .width(40)
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onBack());
      } else {
        Blank().width(40);
      }
      Text(this.title)
        .fontFamily('Noto Serif SC')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(MaskSealPalette.ink)
        .layoutWeight(1)
        .textAlign(TextAlign.Center);
      Blank().width(40);
    }
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(MaskSealPalette.paperSurface)
    .border({ width: { bottom: 1 }, color: '#d8c8c4' });
  }
}

@Component
export struct SealButton {
  @Prop text: string = '';
  @Prop secondary: boolean = false;
  @Prop onTap: () => void = () => {};

  build() {
    Button(this.text)
      .width('100%')
      .height(52)
      .fontFamily('Noto Serif SC')
      .fontWeight(FontWeight.Bold)
      .fontSize(18)
      .fontColor(this.secondary ? MaskSealPalette.primary : Color.White)
      .backgroundColor(this.secondary ? Color.Transparent : MaskSealPalette.primary)
      .border({ width: 1, color: this.secondary ? '#c8a4a0' : MaskSealPalette.primary })
      .borderRadius(4)
      .onClick(() => this.onTap());
  }
}

@Component
export struct FloatingInput {
  @Prop value: string = '';
  @Prop label: string = '';
  @Prop error: string = '';
  @Prop onChange: (value: string) => void = (_value: string) => {};

  build() {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(this.label)
          .fontSize(12)
          .fontFamily('monospace')
          .fontColor(MaskSealPalette.primary)
          .padding({ left: 5, right: 5 })
          .backgroundColor(MaskSealPalette.paperSurface)
          .margin({ left: 12, top: -8 })
          .zIndex(1);
        TextInput({ text: this.value, placeholder: this.label })
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontColor(MaskSealPalette.ink)
          .placeholderColor('#957d7a')
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: this.error ? MaskSealPalette.error : MaskSealPalette.outlineLight })
          .borderRadius(4)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => this.onChange(value));
      }
      if (this.error.length > 0) {
        Text(this.error)
          .fontSize(12)
          .fontColor(MaskSealPalette.error)
          .padding({ left: 4 });
      }
    }
    .width('100%');
  }
}

@Component
export struct SettingRow {
  @Prop title: string = '';
  @Prop detail: string = '';
  @Prop interactive: boolean = true;
  @Prop onTap: () => void = () => {};

  build() {
    Row() {
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(16)
          .fontColor(MaskSealPalette.ink);
        if (this.detail.length > 0) {
          Text(this.detail)
            .fontFamily('monospace')
            .fontSize(11)
            .fontColor(MaskSealPalette.inkMuted);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
      Text(this.interactive ? '›' : '')
        .fontSize(24)
        .fontColor(MaskSealPalette.primary);
    }
    .width('100%')
    .padding({ left: 18, right: 16, top: 15, bottom: 15 })
    .backgroundColor(MaskSealPalette.paperSurface)
    .border({ width: { bottom: 1 }, color: '#eadbd7' })
    .onClick(() => this.onTap());
  }
}
