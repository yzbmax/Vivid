// 主视觉卡：展示品牌口号与行动召唤，点击后调起系统相册选择图片。
//
// 选图流程：
//   1. 点击卡片 → 创建 PhotoViewPicker，设置仅选图片、最多 1 张
//   2. 选择成功 → 跳转编辑页（source=picker + imageUri，见 models/EditModels 冻结契约）
//   3. 用户取消（错误码 13900042）→ Toast 提示"未选择图片"
//   4. 其他错误 → Toast 提示"选图失败，请重试"
//
// 注意：
//   - PhotoViewPicker 是系统选择器，不需要申请相册权限
//   - Toast 用 getUIContext().getPromptAction()，而非已废弃的全局 promptAction.showToast
//   - 编辑页路由见 main_pages.json 的 pages/EditPage（C 独占注册）

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { EditEntrySource } from '../../models/EditModels';

@Component
export struct HeroCard {
  build() {
    // 整张卡片可点击
    Column() {
      // 顶栏：上传图标（左）+ COLOR LAB 标签（右）
      Row() {
        // 朱砂红方块 + 白色上传图标（图片+加号）
        Stack({ alignContent: Alignment.Center }) {
          Path()
            .commands('M2 5 L14 5 L14 17 L2 17 Z M5 9 A1.5 1.5 0 1 0 5.01 9 M2 15 L6 11 L9 14 L13 10 M17 3 L17 7 M15 5 L19 5')
            .width(20)
            .height(20)
            .fillOpacity(0)
            .stroke('#FFFFFF')
            .strokeWidth(1.5)
            .strokeLineCap(LineCapStyle.Round)
        }
        .width(36)
        .height(36)
        .borderRadius(8)
        .backgroundColor($r('app.color.ink_red'))

        Blank()

        Text($r('app.string.home_hero_kicker'))
          .fontSize(11)
          .letterSpacing(2)
          .fontColor($r('app.color.ink_red'))
      }
      .width('100%')

      // 主体区：标题 + 副标题
      Column() {
        Text($r('app.string.home_hero_title'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_dark'))

        Text($r('app.string.home_hero_subtitle'))
          .fontSize(13)
          .margin({ top: 8 })
          .lineHeight(20)
          .fontColor($r('app.color.stone_gray'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 24 })
    }
    .margin({ left: 16, right: 16 })
    .padding({ left: 24, right: 24, top: 24, bottom: 28 })
    .backgroundColor($r('app.color.paper_pink'))
    .borderRadius(16)
    .onClick(() => {
      this.pickImage();
    })
  }

  /**
   * 调起系统相册选择器选取一张图片。
   * 使用 photoAccessHelper.PhotoViewPicker（系统选择器，无需申请相册权限）。
   */
  private pickImage(): void {
    const picker = new photoAccessHelper.PhotoViewPicker();
    // PhotoSelectOptions（不是 PhotoViewPickerOptions）
    const options = new photoAccessHelper.PhotoSelectOptions();
    // 仅选图片
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    // 最多选 1 张
    options.maxSelectNumber = 1;

    picker.select(options)
      .then((result: photoAccessHelper.PhotoSelectResult) => {
        // 取第一张图片的 URI
        const uri: string = result.photoUris[0];
        // 拿到 URI 后进入编辑页（source=picker，imageUri 为所选照片）
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/EditPage',
          params: { source: EditEntrySource.Picker, imageUri: uri }
        }).catch(() => {
          // 路由失败不影响首页
        });
      })
      .catch((err: BusinessError) => {
        // 13900042 = 用户取消选择（非异常，静默提示即可）
        if (err.code === 13900042) {
          this.showToast($r('app.string.home_cta_canceled'));
        } else {
          this.showToast($r('app.string.home_cta_failed'));
        }
      });
  }

  /**
   * 弹出 Toast 提示。
   * 使用 getUIContext().getPromptAction()（推荐方式，全局 promptAction 已废弃）。
   */
  private showToast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 3000
      });
    } catch (err) {
      // 忽略 Toast 异常（不影响主流程）
    }
  }
}
