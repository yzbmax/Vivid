import { FloatingInput, MASK_SEAL, SealButton, SealPaperBackground } from '../components/MaskSeal';
import { validateCode, validatePassword, validatePhone } from '../utils/AuthValidators';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { PageHeader } from '../components/common/PageHeader';

enum LoginMode {
  CODE,
  PASSWORD
}

@Entry
@Component
struct LoginPage {
  @State mode: LoginMode = LoginMode.CODE;
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State phoneError: string = '';
  @State codeError: string = '';
  @State passwordError: string = '';
  @State showPassword: boolean = false;

  private readonly loginScroller: Scroller = new Scroller();
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;

  aboutToAppear(): void {
    const uiContext = this.getUIContext();
    this.previousKeyboardAvoidMode = uiContext.getKeyboardAvoidMode();
    uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
  }

  private handleViewportChange(oldArea: Area, newArea: Area): void {
    const oldHeight: number = Number(oldArea.height);
    const newHeight: number = Number(newArea.height);
    const keyboardResizeThreshold: number = 80;

    if (!Number.isFinite(oldHeight) || !Number.isFinite(newHeight)) {
      return;
    }
    if (oldHeight - newHeight > keyboardResizeThreshold) {
      this.loginScroller.scrollEdge(Edge.Bottom);
    } else if (newHeight - oldHeight > keyboardResizeThreshold) {
      this.loginScroller.scrollEdge(Edge.Top);
    }
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`Failed to show toast: ${JSON.stringify(err)}`);
    }
  }

  private goBack(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  private async openRegister(): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: 'pages/RegisterPage' });
    } catch (err) {
      console.error(`Failed to open register page: ${JSON.stringify(err)}`);
    }
  }

  private selectMode(mode: LoginMode): void {
    this.mode = mode;
    if (mode === LoginMode.CODE) {
      this.passwordError = '';
    } else {
      this.codeError = '';
    }
  }

  private requestCode(): void {
    this.phoneError = validatePhone(this.phone);
    if (this.phoneError.length === 0) {
      this.showToast('验证码服务暂未接入');
    }
  }

  private submit(): void {
    this.phoneError = validatePhone(this.phone);
    if (this.mode === LoginMode.CODE) {
      this.codeError = validateCode(this.code);
    } else {
      this.passwordError = validatePassword(this.password);
    }
    const valid = this.phoneError.length === 0 && (this.mode === LoginMode.CODE
      ? this.codeError.length === 0 : this.passwordError.length === 0);
    if (valid) {
      this.showToast('前端校验通过，登录服务暂未接入');
    }
  }

  @Builder
  passwordField(): void {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text('密函')
          .fontSize(12)
          .fontFamily('monospace')
          .fontColor(MASK_SEAL.primary)
          .padding({ left: 5, right: 5 })
          .backgroundColor(MASK_SEAL.paperSurface)
          .margin({ left: 12, top: -8 })
          .zIndex(1);
        Row() {
          TextInput({ text: this.password, placeholder: '请输入密码' })
            .layoutWeight(1)
            .height(50)
            .type(InputType.Password)
            .showPassword(this.showPassword)
            .showPasswordIcon(false)
            .fontSize(16)
            .fontColor(MASK_SEAL.ink)
            .placeholderColor('#957d7a')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: this.passwordError ? MASK_SEAL.error : MASK_SEAL.outlineLight })
            .borderRadius(4)
            .padding({ left: 16, right: 64 })
            .onChange((value: string) => { this.password = value; this.passwordError = ''; });
          Button() {
            Image(this.showPassword ? $r('app.media.eye') : $r('app.media.eyeoff'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain);
          }
            .width(54)
            .height(42)
            .margin({ left: -60, right: 6 })
            .backgroundColor(Color.Transparent)
            .accessibilityText(this.showPassword ? '隐藏密码' : '显示密码')
            .onClick(() => this.showPassword = !this.showPassword);
        }
      }
      if (this.passwordError.length > 0) {
        Text(this.passwordError).fontSize(12).fontColor(MASK_SEAL.error).padding({ left: 4 });
      }
    }
    .width('100%');
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      PageHeader({ title: '档册查验', showBack: true, onBack: () => this.goBack(), topInset: true });
      Scroll(this.loginScroller) {
        Column({ space: 24 }) {
          Column({ space: 8 }) {
            Text('印')
              .fontFamily('Noto Serif SC')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.primary)
              .width(68)
              .height(68)
              .textAlign(TextAlign.Center)
              .padding({ top: 13 })
              .backgroundColor('#f9e3e1')
              .border({ width: 1, color: '#d2a5a0' })
              .borderRadius(34);
            Text('档册查验')
              .fontFamily('Noto Serif SC')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
            Text('验证身份以开启个人设置')
              .fontSize(15)
              .fontColor(MASK_SEAL.inkMuted);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 16 });

          Column({ space: 20 }) {
            Row() {
              Text('验证码登录')
                .fontFamily('Noto Serif SC')
                .fontSize(17)
                .fontColor(this.mode === LoginMode.CODE ? MASK_SEAL.ink : '#987f7b')
                .fontWeight(this.mode === LoginMode.CODE ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding({ bottom: 10 })
                .border({ width: { bottom: this.mode === LoginMode.CODE ? 3 : 1 }, color: this.mode === LoginMode.CODE ? MASK_SEAL.sealRed : '#dfcbc7' })
                .onClick(() => this.selectMode(LoginMode.CODE));
              Text('密码登录')
                .fontFamily('Noto Serif SC')
                .fontSize(17)
                .fontColor(this.mode === LoginMode.PASSWORD ? MASK_SEAL.ink : '#987f7b')
                .fontWeight(this.mode === LoginMode.PASSWORD ? FontWeight.Bold : FontWeight.Normal)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .padding({ bottom: 10 })
                .border({ width: { bottom: this.mode === LoginMode.PASSWORD ? 3 : 1 }, color: this.mode === LoginMode.PASSWORD ? MASK_SEAL.sealRed : '#dfcbc7' })
                .onClick(() => this.selectMode(LoginMode.PASSWORD));
            }
            FloatingInput({ value: this.phone, label: '手机号', error: this.phoneError, layoutWeight: 0,
              onChange: (value: string) => { this.phone = value; this.phoneError = ''; } });
            if (this.mode === LoginMode.CODE) {
              Column({ space: 5 }) {
                Row({ space: 8 }) {
                  FloatingInput({ value: this.code, label: '验证码', error: this.codeError, layoutWeight: 1,
                    onChange: (value: string) => { this.code = value; this.codeError = ''; } });
                  Button('获取验证码')
                    .width(108)
                    .height(50)
                    .margin({ top: 2 })
                    .fontSize(13)
                    .fontColor(MASK_SEAL.primary)
                    .backgroundColor('#fff8f7')
                    .border({ width: 1, color: '#c8a4a0' })
                    .borderRadius(4)
                    .onClick(() => this.requestCode());
                }
              }
            } else {
              this.passwordField();
            }
            SealButton({ text: '呈验登录', secondary: false, onTap: () => this.submit() });
            Row({ space: 6 }) {
              Text('尚未登记在册？').fontSize(14).fontColor(MASK_SEAL.inkMuted);
              Text('前往注册')
                .fontFamily('Noto Serif SC')
                .fontSize(16)
                .fontColor(MASK_SEAL.primary)
                .fontWeight(FontWeight.Bold)
                .onClick(() => this.openRegister());
            }
            .width('100%')
            .justifyContent(FlexAlign.Center);
          }
          .width('100%')
          .padding(24)
          .backgroundColor(MASK_SEAL.paperSurface)
          .border({ width: 1, color: '#d9c4c0' });
        }
        .width('100%')
        .padding(20);
      }
      .layoutWeight(1)
      .onAreaChange((oldArea: Area, newArea: Area) => this.handleViewportChange(oldArea, newArea));
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
