import { Theme } from './Theme';

export class PageHeaderParams {
  title: string = '';
  showBack: boolean = false;
  onBack: () => void = () => {};
  /** 是否在顶部自行避让状态栏。嵌入 PaperBackground 子内容时传 false（其已避让）。 */
  topInset: boolean = true;
}

/**
 * 统一头部标题栏（Mask & Seal「固定顶栏」）：
 * - 半透明 paper-surface + 毛玻璃，底部描边
 * - 标题用衬线字体（Noto Serif SC，类似 Times New Roman 的衬线气质）绝对居中
 * - 左侧可选返回箭头，右侧预留操作/头像位（等宽占位，保证标题居中）
 * - 顶部按 statusBarHeight（vp）避让系统状态栏
 */
@Builder
export function PageHeader($$: PageHeaderParams) {
  Column() {
    Row() {
      // 左侧：返回箭头 / 空占位（等宽，保证标题居中）
      if ($$.showBack) {
        Image($r('app.media.icon_back'))
          .width(20)
          .height(20)
          .objectFit(ImageFit.Contain)
          .fillColor(Theme.PRIMARY)
          .onClick(() => $$.onBack())
      } else {
        Blank()
          .width(32)
      }

      // 标题（衬线、居中、占满剩余宽度）
      Text($$.title)
        .fontFamily(Theme.FONT_SERIF)

        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
        .letterSpacing(2)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      // 右侧：预留操作/头像位
      Blank()
        .width(32)
    }
    .width('100%')
    .height(Theme.HEADER_HEIGHT)
    .padding({ left: 16, right: 16 })
  }
  .width('100%')
  .padding({ top: $$.topInset ? (AppStorage.get<number>('statusBarHeight') ?? 0) : 0 })
  .backgroundColor(Theme.PAPER_SURFACE_80)
  .backdropBlur(20)
  .border({ width: { bottom: 1 }, color: Theme.OUTLINE_VARIANT })
}