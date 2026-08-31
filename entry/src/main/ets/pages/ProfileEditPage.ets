import { MASK_SEAL, SealButton, SealPaperBackground } from '../components/MaskSeal';
import { PageHeader } from '../components/common/PageHeader';
import { Theme } from '../components/common/Theme';
import { AuthUiState } from '../models/AuthUiState';
import { MockAuthStore } from '../models/MockAuthStore';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Entry
@Component
struct ProfileEditPage {
  @StorageProp('authRevision') authRevision: number = 0;
  @State nickname: string = '';
  @State avatarGlyph: string = '印';
  @State avatarUri: string = '';
  @State profileError: string = '';

  private readonly avatarGlyphs: string[] = ['印', '墨', '朱', '卷', '砚', '山'];

  aboutToAppear(): void {
    this.refreshProfile();
  }

  onPageShow(): void {
    this.refreshProfile();
  }

  private refreshProfile(): void {
    const user = MockAuthStore.getCurrentUser();
    if (user === undefined) {
      this.nickname = '';
      this.avatarGlyph = '印';
      this.avatarUri = '';
      return;
    }
    this.nickname = user.nickname;
    this.avatarGlyph = user.avatarGlyph;
    this.avatarUri = MockAuthStore.getCurrentAvatarUri() ?? '';
  }

  private async chooseAvatar(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await picker.select(options);
      const uri: string | undefined = result.photoUris[0];
      if (uri === undefined || uri.length === 0) {
        this.showToast('未选择头像');
        return;
      }
      this.avatarUri = uri;
      this.profileError = '';
      this.showToast('已选相册头像，保存后生效');
    } catch (err) {
      console.error(`Failed to choose avatar: ${JSON.stringify(err)}`);
      this.showToast('未选择头像');
    }
  }

  private async goBack(): Promise<void> {
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
    return MockAuthStore.getCurrentUser() !== undefined;
  }

  private save(): void {
    this.nickname = this.nickname.trim();
    const result = MockAuthStore.updateProfileWithAvatar({
      nickname: this.nickname,
      avatarGlyph: this.avatarGlyph,
      avatarUri: this.avatarUri.length > 0 ? this.avatarUri : undefined
    });
    if (!result.success) {
      this.profileError = this.profileErrorMessage(result.errorCode);
      return;
    }
    this.profileError = '';
    AuthUiState.bumpRevision();
    this.showToast('个人册页已更新');
    this.goBack();
  }

  private profileErrorMessage(errorCode?: string): string {
    switch (errorCode) {
      case 'INVALID_NICKNAME':
        return '昵称去除首尾空格后需为 1–12 个字符';
      case 'INVALID_AVATAR_GLYPH':
        return '请选择预设印章字形';
      case 'INVALID_AVATAR_URI':
        return '相册头像地址无效，请重新选择';
      case 'NOT_AUTHENTICATED':
        return '请先登录后再编辑个人册页';
      default:
        return '个人册页暂时无法保存';
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      SealPaperBackground();
      Column() {
        PageHeader({ title: '编辑个人册页', showBack: true, onBack: () => this.goBack(), topInset: true });
        Scroll() {
          Column({ space: 20 }) {
            if (!this.isAuthenticated()) {
              Column({ space: 14 }) {
                Text('请先登录')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MASK_SEAL.ink);
                Text('登录后才能编辑个人册页')
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
                Text('个人册页')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.primary)
                  .letterSpacing(1.5)
                  .width('100%');
                if (this.avatarUri.length > 0) {
                  Image(this.avatarUri)
                    .width(82)
                    .height(82)
                    .objectFit(ImageFit.Cover)
                    .border({ width: 1, color: '#d2a5a0' })
                    .borderRadius(41);
                } else {
                  Text(this.avatarGlyph)
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(36)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MASK_SEAL.primary)
                    .width(82)
                    .height(82)
                    .textAlign(TextAlign.Center)
                    .padding({ top: 20 })
                    .backgroundColor('#f9e3e1')
                    .border({ width: 1, color: '#d2a5a0' })
                    .borderRadius(41);
                }
                SealButton({ text: '从相册上传头像', secondary: true, onTap: () => this.chooseAvatar() });
                Text(this.avatarUri.length > 0 ? '相册头像优先显示，保存后生效' : '也可以使用下方印章字形作为头像')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(13)
                  .fontColor(MASK_SEAL.inkMuted);
                Text('选择印章字形')
                  .fontFamily(Theme.FONT_SERIF)
                  .fontSize(13)
                  .fontColor(MASK_SEAL.inkMuted);
                Row({ space: 8 }) {
                  ForEach(this.avatarGlyphs, (glyph: string) => {
                    Text(glyph)
                      .fontFamily(Theme.FONT_SERIF)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(glyph === this.avatarGlyph ? Color.White : MASK_SEAL.primary)
                      .width(42)
                      .height(42)
                      .textAlign(TextAlign.Center)
                      .padding({ top: 9 })
                      .backgroundColor(glyph === this.avatarGlyph ? MASK_SEAL.primary : '#f9e3e1')
                      .border({ width: 1, color: glyph === this.avatarGlyph ? MASK_SEAL.primary : '#d2a5a0' })
                      .borderRadius(21)
                      .onClick(() => {
                        this.avatarGlyph = glyph;
                        this.profileError = '';
                      });
                  });
                }
                .width('100%')
                .justifyContent(FlexAlign.Center);
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding(24)
              .backgroundColor(MASK_SEAL.paperSurface)
              .border({ width: 1, color: '#d9c4c0' });

              Column({ space: 8 }) {
                Text('昵称')
                  .fontFamily(Theme.FONT_MONO)
                  .fontSize(12)
                  .fontColor(MASK_SEAL.primary)
                  .width('100%');
                TextInput({ text: this.nickname, placeholder: '1–12 个字符' })
                  .width('100%')
                  .height(50)
                  .fontSize(16)
                  .fontColor(MASK_SEAL.ink)
                  .placeholderColor('#957d7a')
                  .backgroundColor(Color.Transparent)
                  .border({ width: 1, color: this.profileError.length > 0 ? MASK_SEAL.error : MASK_SEAL.outlineLight })
                  .borderRadius(4)
                  .padding({ left: 16, right: 16 })
                  .onChange((value: string) => {
                    this.nickname = value;
                    this.profileError = '';
                  });
                if (this.profileError.length > 0) {
                  Text(this.profileError)
                    .fontFamily(Theme.FONT_SERIF)
                    .fontSize(12)
                    .fontColor(MASK_SEAL.error)
                    .width('100%');
                }
                SealButton({ text: '落印保存', secondary: false, onTap: () => this.save() });
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
