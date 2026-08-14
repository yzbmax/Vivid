import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { FloatingInput, MASK_SEAL, SealButton, SealPageHeader, SealPaperBackground } from '../components/MaskSeal';
import { validateCode, validatePassword, validatePasswordConfirmation, validatePhone } from '../utils/AuthValidators';

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
  @State showPassword: boolean = false;
  @State showConfirmation: boolean = false;

  private requestCode(): void {
    this.phoneError = validatePhone(this.phone);
    if (this.phoneError.length === 0) {
      promptAction.showToast({ message: '验证码服务暂未接入' });
    }
  }

  private submit(): void {
    this.phoneError = validatePhone(this.phone);
    this.codeError = validateCode(this.code);
    this.passwordError = validatePassword(this.password);
    this.confirmationError = validatePasswordConfirmation(this.password, this.confirmation);
    this.agreementError = this.agreed ? '' : '请阅读并同意用户协议和隐私政策';
    if (this.phoneError.length === 0 && this.codeError.length === 0 && this.passwordError.length === 0 &&
      this.confirmationError.length === 0 && this.agreementError.length === 0) {
      promptAction.showToast({ message: '前端校验通过，注册服务暂未接入' });
    }
  }

  @Builder
  passwordField(label: string, placeholder: string, value: string, error: string, visible: boolean,
    onChange: (value: string) => void, onVisibilityChange: () => void): void {
    Column({ space: 5 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(label)
          .fontSize(12)
          .fontFamily('monospace')
          .fontColor(MASK_SEAL.primary)
          .padding({ left: 5, right: 5 })
          .backgroundColor(MASK_SEAL.paperSurface)
          .margin({ left: 12, top: -8 })
          .zIndex(1);
        Row() {
          TextInput({ text: value, placeholder: placeholder })
            .layoutWeight(1)
            .height(50)
            .type(visible ? InputType.Normal : InputType.Password)
            .fontSize(16)
            .fontColor(MASK_SEAL.ink)
            .placeholderColor('#957d7a')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: error ? MASK_SEAL.error : MASK_SEAL.outlineLight })
            .borderRadius(4)
            .padding({ left: 16, right: 4 })
            .onChange((nextValue: string) => onChange(nextValue));
          Button(visible ? '隐藏' : '显示')
            .width(54)
            .height(42)
            .margin({ left: -60, right: 6 })
            .fontSize(12)
            .fontColor(MASK_SEAL.primary)
            .backgroundColor(Color.Transparent)
            .onClick(() => onVisibilityChange());
        }
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
      SealPageHeader({ title: '登记在册', showBack: true, onBack: () => router.back() });
      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 8 }) {
            Text('册')
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
            Text('登记卷宗')
              .fontFamily('Noto Serif SC')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(MASK_SEAL.ink);
            Text('提交凭据后建立您的个人册页')
              .fontSize(15)
              .fontColor(MASK_SEAL.inkMuted);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 12 });

          Column({ space: 18 }) {
            FloatingInput({ value: this.phone, label: '手机号', error: this.phoneError,
              onChange: (value: string) => { this.phone = value; this.phoneError = ''; } });
            Row({ space: 8 }) {
              FloatingInput({ value: this.code, label: '验证码', error: this.codeError,
                onChange: (value: string) => { this.code = value; this.codeError = ''; } }).layoutWeight(1);
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
            this.passwordField('设置密函', '8-20 位字母和数字组合', this.password, this.passwordError,
              this.showPassword, (value: string) => { this.password = value; this.passwordError = ''; },
              () => this.showPassword = !this.showPassword);
            this.passwordField('确认密函', '请再次输入密码', this.confirmation, this.confirmationError,
              this.showConfirmation, (value: string) => { this.confirmation = value; this.confirmationError = ''; },
              () => this.showConfirmation = !this.showConfirmation);
            Row({ space: 6 }) {
              Checkbox({ name: 'agreement', group: 'register' })
                .select(this.agreed)
                .selectedColor(MASK_SEAL.primary)
                .onChange((checked: boolean) => { this.agreed = checked; this.agreementError = ''; });
              Text('我已阅读并同意').fontSize(13).fontColor(MASK_SEAL.inkMuted);
              Text('《用户协议》').fontSize(13).fontColor(MASK_SEAL.primary)
                .onClick(() => router.pushUrl({ url: 'pages/UserAgreementPage' }));
              Text('和').fontSize(13).fontColor(MASK_SEAL.inkMuted);
              Text('《隐私政策》').fontSize(13).fontColor(MASK_SEAL.primary)
                .onClick(() => router.pushUrl({ url: 'pages/PrivacyPolicyPage' }));
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);
            if (this.agreementError.length > 0) {
              Text(this.agreementError).fontSize(12).fontColor(MASK_SEAL.error);
            }
            SealButton({ text: '提交登记', onTap: () => this.submit() });
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
    }
    .width('100%')
    .height('100%');
  }
}
