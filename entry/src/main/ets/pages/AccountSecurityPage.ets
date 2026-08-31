import { MASK_SEAL, SealButton, SealPaperBackground } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
import { Theme } from '../components/common/Theme';
import { AuthUiState } from '../models/AuthUiState';
import { MockAuthStore } from '../models/MockAuthStore';
import { validateCode, validatePassword, validatePhone, validatePasswordConfirmation } from '../utils/AuthValidators';

@Entry
@Component
struct AccountSecurityPage {
  @StorageProp('authRevision') authRevision: number = 0;
  @State boundPhone: string = '';
  @State hasPassword: boolean = false;
  @State newPhone: string = '';
  @State phoneCode: string = '';
  @State phoneError: string = '';
  @State phoneCodeError: string = '';
  @State phoneCountdown: number = 0;
  @State phoneDemoCode: string = '';
  @State currentPassword: string = '';
  @State passwordCode: string = '';
  @State password: string = '';
  @State passwordConfirmation: string = '';
  @State passwordError: string = '';
  @State passwordCodeError: string = '';
  @State passwordCountdown: number = 0;
  @State passwordDemoCode: string = '';
  @State closureCredential: string = '';
  @State closureError: string = '';
  @State closureCountdown: number = 0;
  @State closureDemoCode: string = '';

  private phoneTimer: number = -1;
  private passwordTimer: number = -1;
  private closureTimer: number = -1;

  aboutToAppear(): void {
    this.refreshSnapshot();
  }

  onPageShow(): void {
    this.refreshSnapshot();
  }

  aboutToDisappear(): void {
    this.clearTimers();
    MockAuthStore.cancelAccountClosure();
  }

  private refreshSnapshot(): void {
    const snapshot = MockAuthStore.getAccountSecuritySnapshot();
    if (snapshot === undefined) {
      this.boundPhone = '';
      this.hasPassword = false;
      return;
    }
    this.boundPhone = snapshot.maskedPhone;
    this.hasPassword = snapshot.hasPassword;
  }

  private async goBack(): Promise<void> {
    MockAuthStore.cancelAccountClosure();
    try {
      await this.getUIContext().getRouter().back();
    } catch (err) {
      console.error(`Failed to navigate back: ${JSON.stringify(err)}`);
    }
  }

  private async openLogin(): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error(`Failed to open login page: ${JSON.stringify(err)}`);
    }
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (err) {
      console.error(`Failed to show toast: ${JSON.stringify(err)}`);
    }
  }

  private isAuthenticated(): boolean {
    if (this.authRevision < 0) {
      return false;
    }
    return MockAuthStore.getAccountSecuritySnapshot() !== undefined;
  }

  private requestPhoneCode(): void {
    if (this.phoneCountdown > 0) {
      return;
    }
    this.phoneError = validatePhone(this.newPhone);
    this.phoneCodeError = '';
    if (this.phoneError.length > 0) {
      return;
    }
    const result = MockAuthStore.requestPhoneBindingCode(this.newPhone);
    if (!result.success) {
      this.phoneError = this.settingsErrorMessage(result.errorCode);
      return;
    }
    this.phoneDemoCode = result.demoCode ?? '';
    this.phoneCountdown = 60;
    this.startTimer('phone');
  }

  private changePhone(): void {
    this.phoneError = validatePhone(this.newPhone);
    this.phoneCodeError = validateCode(this.phoneCode);
    if (this.phoneError.length > 0 || this.phoneCodeError.length > 0) {
      return;
    }
    const result = MockAuthStore.changePhoneBinding({ newPhone: this.newPhone, code: this.phoneCode });
    if (!result.success) {
      this.applyPhoneError(result.errorCode);
      return;
    }
    AuthUiState.bumpRevision();
    this.newPhone = '';
    this.phoneCode = '';
    this.phoneDemoCode = '';
    this.phoneError = '';
    this.phoneCodeError = '';
    this.refreshSnapshot();
    this.showToast('绑定手机号已更新');
  }

  private requestPasswordCode(): void {
    if (this.passwordCountdown > 0 || this.hasPassword) {
      return;
    }
    this.passwordCodeError = '';
    const result = MockAuthStore.requestPasswordSetupCode();
    if (!result.success) {
      this.passwordCodeError = this.settingsErrorMessage(result.errorCode);
      return;
    }
    this.passwordDemoCode = result.demoCode ?? '';
    this.passwordCountdown = 60;
    this.startTimer('password');
  }

  private savePassword(): void {
    const settingFirstPassword: boolean = !this.hasPassword;
    this.passwordError = '';
    this.passwordCodeError = '';
    if (!this.hasPassword) {
      this.passwordCodeError = validateCode(this.passwordCode);
    }
    if (validatePassword(this.password).length > 0) {
      this.passwordError = '密码需为 8-20 位字母和数字组合';
    } else if (validatePasswordConfirmation(this.password, this.passwordConfirmation).length > 0) {
      this.passwordError = '两次输入的密码不一致';
    }
    if (this.passwordError.length > 0 || this.passwordCodeError.length > 0) {
      return;
    }

    const result = this.hasPassword
      ? MockAuthStore.changePassword({ currentPassword: this.currentPassword, newPassword: this.password })
      : MockAuthStore.setupPassword({ code: this.passwordCode, newPassword: this.password });
    if (!result.success) {
      this.passwordError = this.settingsErrorMessage(result.errorCode);
      return;
    }
    AuthUiState.bumpRevision();
    this.currentPassword = '';
    this.passwordCode = '';
    this.password = '';
    this.passwordConfirmation = '';
    this.passwordDemoCode = '';
    this.passwordCodeError = '';
    this.passwordError = '';
    this.refreshSnapshot();
    this.showToast(settingFirstPassword ? '密码已设置' : '密码已修改');
  }

  private requestClosureCode(): void {
    if (this.closureCountdown > 0 || this.hasPassword) {
      return;
    }
    this.closureError = '';
    const result = MockAuthStore.requestAccountClosureCode();
    if (!result.success) {
      this.closureError = this.settingsErrorMessage(result.errorCode);
      return;
    }
    this.closureDemoCode = result.demoCode ?? '';
    this.closureCountdown = 60;
    this.startTimer('closure');
  }

  private async verifyAndConfirmClosure(): Promise<void> {
    this.closureError = '';
    const method = this.hasPassword ? 'password' : 'code';
    if (!this.hasPassword) {
      this.closureError = validateCode(this.closureCredential);
      if (this.closureError.length > 0) {
        return;
      }
    } else if (this.closureCredential.length === 0) {
      this.closureError = '请输入当前密码';
      return;
    }
    const verified = MockAuthStore.verifyAccountClosure({ method: method, credential: this.closureCredential });
    if (!verified.success) {
      this.closureError = this.settingsErrorMessage(verified.errorCode);
      return;
    }
    try {
      const response = await this.getUIContext().getPromptAction().showDialog({
        title: '确认注销账号',
        message: '注销后将删除当前进程内的 Mock 账号与个人资料，且无法在本次运行中恢复。',
        buttons: [
          { text: '取消', color: MASK_SEAL.inkMuted },
          { text: '确认注销', color: MASK_SEAL.primary }
        ]
      });
      if (response.index !== 1) {
        MockAuthStore.cancelAccountClosure();
        this.closureCredential = '';
        this.showToast('已取消注销');
        return;
      }
      const closed = MockAuthStore.closeAccount();
      if (!closed.success) {
        this.closureError = this.settingsErrorMessage(closed.errorCode);
        return;
      }
      AuthUiState.bumpRevision();
      this.showToast('账号已注销');
      await this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      MockAuthStore.cancelAccountClosure();
      console.error(`Failed to confirm account closure: ${JSON.stringify(err)}`);
    }
  }

  private applyPhoneError(errorCode?: string): void {
    if (errorCode === 'SAME_PHONE' || errorCode === 'PHONE_ALREADY_BOUND' || errorCode === 'INVALID_PHONE') {
      this.phoneError = this.settingsErrorMessage(errorCode);
    } else {
      this.phoneCodeError = this.settingsErrorMessage(errorCode);
    }
  }

  private settingsErrorMessage(errorCode?: string): string {
    switch (errorCode) {
      case 'INVALID_PHONE':
        return '请输入有效的手机号';
      case 'SAME_PHONE':
        return '新手机号不能与当前手机号相同';
      case 'PHONE_ALREADY_BOUND':
        return '该手机号已绑定其他 Mock 账号';
      case 'INVALID_CODE':
        return '验证码不正确';
      case 'CODE_NOT_REQUESTED':
        return '请先获取验证码';
      case 'CODE_PHONE_MISMATCH':
        return '验证码与手机号不匹配';
      case 'CODE_PURPOSE_MISMATCH':
        return '验证码用途不匹配，请重新获取';
      case 'CODE_ALREADY_CONSUMED':
        return '验证码已使用，请重新获取';
      case 'PASSWORD_ALREADY_SET':
        return '当前账号已经设置密码';
      case 'PASSWORD_NOT_SET':
        return '当前账号尚未设置密码';
      case 'INCORRECT_CURRENT_PASSWORD':
        return '原密码不正确';
      case 'SAME_PASSWORD':
        return '新密码不能与原密码相同';
      case 'INVALID_PASSWORD':
        return '密码需为 8-20 位字母和数字组合';
      case 'INVALID_CREDENTIALS':
        return '验证凭证不正确';
      case 'CLOSURE_NOT_VERIFIED':
        return '注销验证已失效，请重新验证';
      case 'NOT_AUTHENTICATED':
        return '请先登录后再管理账号安全';
      default:
        return '操作暂时无法完成';
    }
  }

  private startTimer(kind: 'phone' | 'password' | 'closure'): void {
    this.clearTimer(kind);
    const timer: number = setInterval(() => {
      if (kind === 'phone') {
        if (this.phoneCountdown <= 1) {
          this.phoneCountdown = 0;
          this.clearTimer('phone');
        } else {
          this.phoneCountdown -= 1;
        }
      } else if (kind === 'password') {
        if (this.passwordCountdown <= 1) {
          this.passwordCountdown = 0;
          this.clearTimer('password');
        } else {
          this.passwordCountdown -= 1;
        }
      } else if (this.closureCountdown <= 1) {
        this.closureCountdown = 0;
        this.clearTimer('closure');
      } else {
        this.closureCountdown -= 1;
      }
    }, 1000);
    if (kind === 'phone') {
      this.phoneTimer = timer;
    } else if (kind === 'password') {
      this.passwordTimer = timer;
    } else {
      this.closureTimer = timer;
    }
  }

  private clearTimer(kind: 'phone' | 'password' | 'closure'): void {
    let timer: number = -1;
    if (kind === 'phone') {
      timer = this.phoneTimer;
      this.phoneTimer = -1;
    } else if (kind === 'password') {
      timer = this.passwordTimer;
      this.passwordTimer = -1;
    } else {
      timer = this.closureTimer;
      this.closureTimer = -1;
    }
    if (timer >= 0) {
      clearInterval(timer);
    }
  }

  private clearTimers(): void {
    this.clearTimer('phone');
    this.clearTimer('password');
    this.clearTimer('closure');
  }

  @Builder
  textField(label: string, value: string, placeholder: string, password: boolean,
    error: string, onChange: (value: string) => void, layoutWeight: number = 0): void {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontFamily(Theme.FONT_MONO)
        .fontColor(MASK_SEAL.primary)
        .width('100%');
      TextInput({ text: value, placeholder: placeholder })
        .width('100%')
        .height(50)
        .type(password ? InputType.Password : InputType.Normal)
        .showPasswordIcon(false)
        .fontSize(16)
        .fontColor(MASK_SEAL.ink)
        .placeholderColor('#957d7a')
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: error.length > 0 ? MASK_SEAL.error : MASK_SEAL.outlineLight })
        .borderRadius(4)
        .padding({ left: 16, right: 16 })
        .onChange((nextValue: string) => onChange(nextValue));
      if (error.length > 0) {
        Text(error).fontSize(12).fontColor(MASK_SEAL.error).width('100%');
      }
    }
    .width('100%')
    .layoutWeight(layoutWeight);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
        PageHeader({ title: '手机号与登录安全', showBack: true, onBack: () => this.goBack(), topInset: true });
        Scroll() {
          Column({ space: 20 }) {
            if (!this.isAuthenticated()) {
              Column({ space: 14 }) {
                Text('请先登录')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MASK_SEAL.ink);
                Text('登录后才能管理手机号与登录安全')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(14)
                  .fontColor(MASK_SEAL.inkMuted);
                SealButton({ text: '前往登录', secondary: false, onTap: () => this.openLogin() });
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding(24)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#d9c4c0' });
            } else {
              Column({ space: 14 }) {
                Text('当前绑定手机号')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.primary)
                  .width('100%');
                Text(this.boundPhone)
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MASK_SEAL.ink)
                  .width('100%');
                this.textField('新手机号', this.newPhone, '请输入新的手机号', false, this.phoneError,
                  (value: string) => { this.newPhone = value; this.phoneError = ''; });
                Row({ space: 8 }) {
                  this.textField('验证码', this.phoneCode, '6 位验证码', false, this.phoneCodeError,
                    (value: string) => { this.phoneCode = value; this.phoneCodeError = ''; }, 1);
                  Button(this.phoneCountdown > 0 ? `重发 ${this.phoneCountdown}s` : '获取验证码')
                    .width(108)
                    .height(50)
                    .margin({ top: 18 })
                    .fontSize(13)
                    .fontColor(MASK_SEAL.primary)
                    .backgroundColor('#fff8f7')
                    .border({ width: 1, color: '#c8a4a0' })
                    .borderRadius(4)
                    .enabled(this.phoneCountdown === 0)
                    .onClick(() => this.requestPhoneCode());
                }
                .width('100%')
                .alignItems(VerticalAlign.Top);
                if (this.phoneDemoCode.length > 0) {
                  Text(`演示数据：验证码 ${this.phoneDemoCode}`)
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(12)
                    .fontColor(MASK_SEAL.primary)
                    .width('100%');
                }
                SealButton({ text: '确认换绑', secondary: false, onTap: () => this.changePhone() });
              }
              .width('100%')
              .padding(24)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#d9c4c0' });

              Column({ space: 14 }) {
                Text(this.hasPassword ? '修改密码' : '首次设置密码')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.primary)
                  .width('100%');
                if (this.hasPassword) {
                  this.textField('原密码', this.currentPassword, '请输入当前密码', true, '',
                    (value: string) => { this.currentPassword = value; });
                } else {
                  Row({ space: 8 }) {
                    this.textField('验证码', this.passwordCode, '当前手机号验证码', false, this.passwordCodeError,
                      (value: string) => { this.passwordCode = value; this.passwordCodeError = ''; }, 1);
                    Button(this.passwordCountdown > 0 ? `重发 ${this.passwordCountdown}s` : '获取验证码')
                      .width(108)
                      .height(50)
                      .margin({ top: 18 })
                      .fontSize(13)
                      .fontColor(MASK_SEAL.primary)
                      .backgroundColor('#fff8f7')
                      .border({ width: 1, color: '#c8a4a0' })
                      .borderRadius(4)
                      .enabled(this.passwordCountdown === 0)
                      .onClick(() => this.requestPasswordCode());
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top);
                  if (this.passwordDemoCode.length > 0) {
                    Text(`演示数据：验证码 ${this.passwordDemoCode}`)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(12)
                      .fontColor(MASK_SEAL.primary)
                      .width('100%');
                  }
                }
                this.textField('新密码', this.password, '8-20 位字母和数字组合', true, this.passwordError,
                  (value: string) => { this.password = value; this.passwordError = ''; });
                this.textField('确认密码', this.passwordConfirmation, '请再次输入密码', true, '',
                  (value: string) => { this.passwordConfirmation = value; });
                SealButton({ text: this.hasPassword ? '确认修改' : '设置密码', secondary: false,
                  onTap: () => this.savePassword() });
              }
              .width('100%')
              .padding(24)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#d9c4c0' });

              Column({ space: 14 }) {
                Text('注销账号')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.primary)
                  .width('100%');
                Text(this.hasPassword ? '输入当前密码后再确认注销' : '向当前手机号发送验证码后再确认注销')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(13)
                  .fontColor(MASK_SEAL.inkMuted)
                  .width('100%');
                if (!this.hasPassword) {
                  Row({ space: 8 }) {
                    this.textField('验证码', this.closureCredential, '当前手机号验证码', false, this.closureError,
                      (value: string) => { this.closureCredential = value; this.closureError = ''; }, 1);
                    Button(this.closureCountdown > 0 ? `重发 ${this.closureCountdown}s` : '获取验证码')
                      .width(108)
                      .height(50)
                      .margin({ top: 18 })
                      .fontSize(13)
                      .fontColor(MASK_SEAL.primary)
                      .backgroundColor('#fff8f7')
                      .border({ width: 1, color: '#c8a4a0' })
                      .borderRadius(4)
                      .enabled(this.closureCountdown === 0)
                      .onClick(() => this.requestClosureCode());
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top);
                  if (this.closureDemoCode.length > 0) {
                    Text(`演示数据：验证码 ${this.closureDemoCode}`)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(12)
                      .fontColor(MASK_SEAL.primary)
                      .width('100%');
                  }
                } else {
                  this.textField('当前密码', this.closureCredential, '请输入当前密码', true, this.closureError,
                    (value: string) => { this.closureCredential = value; this.closureError = ''; });
                }
                SealButton({ text: '注销账号', secondary: true, onTap: () => this.verifyAndConfirmClosure() });
              }
              .width('100%')
              .padding(24)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#d9c4c0' });
            }
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
