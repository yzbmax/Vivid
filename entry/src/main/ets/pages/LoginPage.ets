import { FloatingInput, MASK_SEAL, SealButton, SealPaperBackground } from '../components/MaskSeal';
import { validateCode, validatePassword, validatePhone } from '../utils/AuthValidators';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { PageHeader } from '../components/common/PageHeader';
import { AuthErrorCode, MockAuthStore } from '../models/MockAuthStore';
import { AuthUiState } from '../models/AuthUiState';
import { EditEntrySource } from '../models/EditModels';
import { PendingEditIntentStore } from '../models/PendingEditIntentStore';

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
  @State demoCode: string = '';
  @State codeCountdown: number = 0;

  private readonly loginScroller: Scroller = new Scroller();
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private codeTimer: number = -1;

  aboutToAppear(): void {
    const uiContext = this.getUIContext();
    this.previousKeyboardAvoidMode = uiContext.getKeyboardAvoidMode();
    uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
  }

  aboutToDisappear(): void {
    this.clearCodeTimer();
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
    PendingEditIntentStore.clear();
    try {
      this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  private async openRegister(): Promise<void> {
    try {
      if (PendingEditIntentStore.peek() !== undefined) {
        await this.getUIContext().getRouter().replaceUrl({ url: 'pages/RegisterPage' });
      } else {
        await this.getUIContext().getRouter().pushUrl({ url: 'pages/RegisterPage' });
      }
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
    if (this.codeCountdown > 0) {
      return;
    }
    this.phoneError = validatePhone(this.phone);
    if (this.phoneError.length > 0) {
      return;
    }
    const result = MockAuthStore.requestCode(this.phone);
    if (result.success) {
      this.demoCode = result.demoCode ?? '';
      this.codeCountdown = 60;
      this.startCodeCountdown();
    }
  }

  private async submit(): Promise<void> {
    this.phoneError = validatePhone(this.phone);
    this.codeError = '';
    this.passwordError = '';
    if (this.phoneError.length > 0) {
      return;
    }
    if (this.mode === LoginMode.CODE) {
      this.codeError = validateCode(this.code);
      if (this.codeError.length > 0) {
        return;
      }
      const result = MockAuthStore.loginWithCode(this.phone, this.code);
      if (!result.success) {
        this.codeError = this.authErrorMessage(result.errorCode);
        return;
      }
    } else {
      this.passwordError = validatePassword(this.password);
      if (this.passwordError.length > 0) {
        return;
      }
      const result = MockAuthStore.loginWithPassword(this.phone, this.password);
      if (!result.success) {
        this.passwordError = this.authErrorMessage(result.errorCode);
        return;
      }
    }
    AuthUiState.bumpRevision();
    await this.resumePendingEditOrGoBack();
  }

  private async resumePendingEditOrGoBack(): Promise<void> {
    const intent = PendingEditIntentStore.consume();
    if (intent === undefined) {
      this.goBack();
      return;
    }
    try {
      await this.getUIContext().getRouter().replaceUrl({
        url: 'pages/EditPage',
        params: {
          source: EditEntrySource.Picker,
          imageUri: intent.imageUri,
          initialTool: intent.initialTool
        }
      });
    } catch (_err) {
      PendingEditIntentStore.set(intent);
      this.showToast('无法恢复所选照片，请重试');
    }
  }

  onBackPress(): boolean {
    this.goBack();
    return true;
  }

  private authErrorMessage(errorCode?: AuthErrorCode): string {
    switch (errorCode) {
      case 'CODE_NOT_REQUESTED':
        return '请先获取验证码';
      case 'CODE_PHONE_MISMATCH':
        return '验证码与手机号不匹配';
      case 'CODE_PURPOSE_MISMATCH':
        return '验证码用途不匹配，请重新获取';
      case 'CODE_ALREADY_CONSUMED':
        return '验证码已使用，请重新获取';
      case 'INVALID_CODE':
        return '验证码不正确';
      case 'INVALID_CREDENTIALS':
        return '手机号或密码不正确';
      default:
        return '';
    }
  }

  private startCodeCountdown(): void {
    this.clearCodeTimer();
    this.codeTimer = setInterval(() => {
      if (this.codeCountdown <= 1) {
        this.codeCountdown = 0;
        this.clearCodeTimer();
      } else {
        this.codeCountdown -= 1;
      }
    }, 1000);
  }

  private clearCodeTimer(): void {
    if (this.codeTimer >= 0) {
      clearInterval(this.codeTimer);
      this.codeTimer = -1;
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
            Image($r('app.media.Login'))
              .width(68)
              .height(68)
              .objectFit(ImageFit.Contain)
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
                  Button(this.codeCountdown > 0 ? `重发 ${this.codeCountdown}s` : '获取验证码')
                    .width(108)
                    .height(50)
                    .margin({ top: 2 })
                    .fontSize(13)
                    .fontColor(MASK_SEAL.primary)
                    .backgroundColor('#fff8f7')
                    .border({ width: 1, color: '#c8a4a0' })
                    .borderRadius(4)
                    .enabled(this.codeCountdown === 0)
                    .onClick(() => this.requestCode());
                }
                if (this.demoCode.length > 0) {
                  Text(`演示数据：验证码 ${this.demoCode}`)
                    .fontSize(12)
                    .fontColor(MASK_SEAL.primary)
                    .padding({ left: 4 });
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
