import { FloatingInput, MASK_SEAL, SealButton, SealPaperBackground } from '../components/MaskSeal';
import { validateCode, validatePassword, validatePasswordConfirmation, validatePhone } from '../utils/AuthValidators';
import { PageHeader } from '../components/common/PageHeader';
import { Theme } from '../components/common/Theme';
import { AuthErrorCode, MockAuthStore } from '../models/MockAuthStore';
import { AuthUiState } from '../models/AuthUiState';
import { EditEntrySource } from '../models/EditModels';
import { PendingEditIntentStore } from '../models/PendingEditIntentStore';
import { LoginUnavailableOverlay } from '../components/auth/LoginUnavailableOverlay';

@Entry
@Component
struct RegisterPage {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State confirmation: string = '';
  @State agreed: boolean = false;
  @State phoneError: string = '';
  @State codeError: string = '';
  @State passwordError: string = '';
  @State confirmationError: string = '';
  @State agreementError: string = '';
  @State demoCode: string = '';
  @State codeCountdown: number = 0;

  private codeTimer: number = -1;

  aboutToDisappear(): void {
    this.clearCodeTimer();
  }

  private goBack(): void {
    PendingEditIntentStore.clear();
    try {
      this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  private async openAgreement(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch (err) {
      console.error(`Failed to open agreement page: ${JSON.stringify(err)}`);
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
    const result = MockAuthStore.requestRegistrationCode(this.phone);
    if (result.success) {
      this.demoCode = result.demoCode ?? '';
      this.codeCountdown = 60;
      this.startCodeCountdown();
    }
  }

  private async submit(): Promise<void> {
    this.phoneError = validatePhone(this.phone);
    this.codeError = validateCode(this.code);
    this.passwordError = validatePassword(this.password);
    this.confirmationError = validatePasswordConfirmation(this.password, this.confirmation);
    this.agreementError = this.agreed ? '' : '请阅读并同意用户协议和隐私政策';
    if (this.phoneError.length > 0 || this.codeError.length > 0 || this.passwordError.length > 0 ||
      this.confirmationError.length > 0 || this.agreementError.length > 0) {
      return;
    }
    const result = MockAuthStore.register(this.phone, this.code, this.password);
    if (!result.success) {
      this.applyAuthError(result.errorCode);
      return;
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
          displayUri: intent.displayUri,
          initialTool: intent.initialTool
        }
      });
    } catch (_err) {
      PendingEditIntentStore.set(intent);
      this.showToast('无法恢复所选照片，请重试');
    }
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (_err) {
    }
  }

  onBackPress(): boolean {
    this.goBack();
    return true;
  }

  private applyAuthError(errorCode?: AuthErrorCode): void {
    if (errorCode === 'PHONE_ALREADY_REGISTERED') {
      this.phoneError = '该手机号已注册';
    } else if (errorCode === 'CODE_NOT_REQUESTED') {
      this.codeError = '请先获取验证码';
    } else if (errorCode === 'CODE_PHONE_MISMATCH') {
      this.codeError = '验证码与手机号不匹配';
    } else if (errorCode === 'CODE_PURPOSE_MISMATCH') {
      this.codeError = '验证码用途不匹配，请重新获取';
    } else if (errorCode === 'CODE_ALREADY_CONSUMED') {
      this.codeError = '验证码已使用，请重新获取';
    } else if (errorCode === 'INVALID_CODE') {
      this.codeError = '验证码不正确';
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
  passwordField(label: string, placeholder: string, value: string, error: string,
    onChange: (value: string) => void): void {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(label)
          .fontSize(12)
          .fontFamily(Theme.FONT_MONO)
          .fontColor(MASK_SEAL.primary)
          .padding({ left: 5, right: 5 })
          .backgroundColor(MASK_SEAL.paperSurface)
          .margin({ left: 12, top: -8 })
          .zIndex(1);
        TextInput({ text: value, placeholder: placeholder })
          .width('100%')
          .height(50)
          .type(InputType.Password)
          .showPasswordIcon(false)
          .fontSize(16)
          .fontColor(MASK_SEAL.ink)
          .placeholderColor('#957d7a')
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: error ? MASK_SEAL.error : MASK_SEAL.outlineLight })
          .borderRadius(4)
          .padding({ left: 16, right: 16 })
          .onChange((nextValue: string) => onChange(nextValue));
      }
      if (error.length > 0) {
        Text(error).fontSize(12).fontColor(MASK_SEAL.error).padding({ left: 4 });
      }
    }
    .width('100%');
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
      PageHeader({ title: '登记在册', showBack: true, onBack: () => this.goBack(), topInset: true });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 8 }) {
            Image($r('app.media.Register'))
              .width(68)
              .height(68)
              .objectFit(ImageFit.Contain)
              .borderRadius(34);
            Text('注册档册')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
            Text('提交凭据后建立您的个人册页')
              .fontFamily(Theme.FONT_SERIF)
              .fontSize(15)
              .fontColor(MASK_SEAL.inkMuted);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 12 });

          Column({ space: 18 }) {
            FloatingInput({ value: this.phone, label: '手机号', error: this.phoneError, layoutWeight: 0,
              onChange: (value: string) => { this.phone = value; this.phoneError = ''; } });
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
                .fontFamily(Theme.FONT_SERIF)
                .fontSize(12)
                .fontColor(MASK_SEAL.primary)
                .padding({ left: 4 });
            }
            this.passwordField('设置密函', '8-20 位字母和数字组合', this.password, this.passwordError,
              (value: string) => { this.password = value; this.passwordError = ''; });
            this.passwordField('确认密函', '请再次输入密码', this.confirmation, this.confirmationError,
              (value: string) => { this.confirmation = value; this.confirmationError = ''; });
            Row({ space: 6 }) {
              Checkbox({ name: 'agreement', group: 'register' })
                .width(22)
                .height(22)
                .select(this.agreed)
                .selectedColor(MASK_SEAL.primary)
                .onChange((checked: boolean) => { this.agreed = checked; this.agreementError = ''; });
              Text() {
                Span('我已阅读并同意').fontColor(MASK_SEAL.inkMuted);
                Span('《用户协议》')
                  .fontColor(MASK_SEAL.primary)
                  .onClick(() => this.openAgreement('pages/UserAgreementPage'));
                Span('和').fontColor(MASK_SEAL.inkMuted);
                Span('《隐私政策》')
                  .fontColor(MASK_SEAL.primary)
                  .onClick(() => this.openAgreement('pages/PrivacyPolicyPage'));
              }
              .layoutWeight(1)
              .fontSize(13)
              .lineHeight(20)
              .fontColor(MASK_SEAL.inkMuted)
              .textAlign(TextAlign.Start);
            }
            .width('100%')
            .alignItems(VerticalAlign.Top);
            if (this.agreementError.length > 0) {
              Text(this.agreementError).fontSize(12).fontColor(MASK_SEAL.error);
            }
            SealButton({ text: '提交登记', secondary: false, onTap: () => this.submit() });
          }
          .width('100%')
          .padding(24)
          .backgroundColor(MASK_SEAL.paperSurface)
          .border({ width: 1, color: '#d9c4c0' });
        }
        .width('100%')
        .padding(20);
      }
      .layoutWeight(1);
      }
      .width('100%')
      .height('100%');

      // 注册功能暂不可用提示遮罩及赞赏加餐
      LoginUnavailableOverlay({
        title: '注册功能暂未开启',
        message: '因开发者付不起服务器钱所以登陆与注册功能暂不可用，想加速上线登陆功能和云存储功能可以给我加个餐',
        onBack: () => this.goBack()
      })
        .width('100%')
        .height('100%')
        .zIndex(100);
    }
    .width('100%')
    .height('100%');
  }
}
