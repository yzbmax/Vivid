import { EDITOR_TOOLS, EditorTool } from '../../models/EditModels';
import { Theme } from '../common/Theme';

/**
 * 底部工具导航（7 项）：滤镜 / 主体 / 背景 / 调节 / 贴纸 / 文字 / 模板。
 * 当前活动工具下方显示朱砂下划线。本轮仅「调节」有内容，其余切换后由页面显示占位。
 */
@Component
export struct EditorToolBar {
  @Prop activeTool: string = 'adjust';
  onSelectTool: (key: string) => void = () => {};

  build() {
    Column() {
      Row() {
        ForEach(EDITOR_TOOLS, (tool: EditorTool) => {
          Column() {
            Text(tool.label)
              .fontFamily(Theme.FONT_SANS)
              .fontSize(Theme.FONT_SIZE_BODY_MD)
              .fontWeight(this.activeTool === tool.key ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.activeTool === tool.key ? Theme.PRIMARY : Theme.ON_SURFACE_VARIANT)
              .maxLines(1)
          }
          .layoutWeight(1)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .border({ width: { bottom: this.activeTool === tool.key ? 3 : 0 }, color: Theme.SEAL_RED })
          .onClick(() => this.onSelectTool(tool.key))
        }, (tool: EditorTool) => tool.key)
      }
      .width('100%')
      .height(48)
      .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })
    }
    .width('100%')
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .backdropBlur(20)
    .border({ width: { top: 1 }, color: Theme.OUTLINE_VARIANT })
    // 底部留白：系统手势/导航条安全区，保底 22vp（部分设备 navBarHeight 上报为 0）
    .padding({ bottom: Math.max(AppStorage.get<number>('navBarHeight') ?? 0, 22) })
  }
}
