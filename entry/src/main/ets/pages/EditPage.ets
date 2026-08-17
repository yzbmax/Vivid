import { EditEntrySource, EditRouteParams, editRouteError, parseEditRouteParams } from '../models/EditModels';
import { Theme } from '../components/common/Theme';
import { PageHeader } from '../components/common/PageHeader';
import { PaperBackground } from '../components/common/PaperBackground';

/**
 * 独立调色编辑页（第 0 阶段：冻结接口 + 路由骨架 + 错误态）。
 * 后续阶段接入 PreviewArea / AdjustPanel / EditActionBar 与 MockWorkStore。
 * 编辑页为独立 @Entry 路由，不进入 Index 底部 Tab。
 */
@Entry
@Component
struct EditPage {
  @State route: EditRouteParams | null = null;
  @State errorText: string = '';

  aboutToAppear(): void {
    const raw = this.getUIContext().getRouter().getParams() as Record<string, string>;
    const route = parseEditRouteParams(raw ?? {});
    this.route = route;
    this.errorText = editRouteError(route);
  }

  build() {
    Column() {
      PaperBackground() {
        Column() {
          PageHeader({
            title: '调色复核',
            showBack: true,
            onBack: () => this.getUIContext().getRouter().back(),
            topInset: true
          })
          if (this.errorText !== '') {
            this.errorState()
          } else {
            this.previewPlaceholder()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  errorState() {
    Column({ space: 12 }) {
      Text('无法进入编辑页')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text(this.errorText)
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .textAlign(TextAlign.Center)
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      Row() {
        Text('返回')
          .fontFamily(Theme.FONT_SANS)
          .fontSize(Theme.FONT_SIZE_BODY_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ON_PRIMARY)
      }
      .width(160)
      .height(48)
      .margin({ top: 12 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Theme.PRIMARY)
      .borderRadius(Theme.RADIUS_DEFAULT)
      .onClick(() => this.getUIContext().getRouter().back())
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 96, bottom: 96 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  previewPlaceholder() {
    Column({ space: 12 }) {
      Text('预览区占位')
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text(this.placeholderHint())
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
        .textAlign(TextAlign.Center)
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
      Text('调色预览与四参数滑块将在后续阶段接入')
        .fontFamily(Theme.FONT_MONO)
        .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
        .fontColor(Theme.ON_SURFACE_VARIANT_70)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 96, bottom: 96 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  private placeholderHint(): string {
    if (this.route == null) {
      return '';
    }
    if (this.route.source === EditEntrySource.Picker) {
      return `来源：首页选图 · ${this.route.imageUri ?? ''}`;
    }
    return `来源：作品续编 · ${this.route.workId ?? ''}`;
  }
}
