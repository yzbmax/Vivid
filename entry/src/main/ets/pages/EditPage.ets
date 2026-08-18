import {
  EDITOR_TOOLS,
  AdjustParams,
  EditEntrySource,
  EditRouteParams,
  SaveMode,
  buildSaveIntent,
  createDefaultAdjustments,
  editRouteError,
  parseEditRouteParams
} from '../models/EditModels';
import { EditWorkStore } from '../models/EditWorkStore';
import { Theme } from '../components/common/Theme';
import { PaperBackground } from '../components/common/PaperBackground';
import { PreviewArea } from '../components/editor/PreviewArea';
import { AdjustPanel } from '../components/editor/AdjustPanel';
import { EditorToolBar } from '../components/editor/EditorToolBar';

/**
 * 独立调色编辑页。
 *
 * 布局（自上而下）：
 *  1. 顶部导航区（~8-10%）：返回（左）| 标题 | 保存（右）。
 *  2. 中部预览区（~65-70%）：Contain 原比例不裁切，占满导航与面板之间。
 *  3. 中下部参数面板（~12-15%）：调节工具两行（重置/滑块/对比 + 调整类型选择）。
 *  4. 底部工具导航（~8-10%）：滤镜/主体/背景/调节/贴纸/文字/模板，高亮「调节」。
 *
 * 保存当前为占位（仅按钮不保存）；B 的 MockWorkStore / WorkRecord 扩展字段交付后接入。
 * 编辑页为独立 @Entry 路由，不进入 Index 底部 Tab。
 */
@Entry
@Component
struct EditPage {
  @State route: EditRouteParams | null = null;
  @State errorText: string = '';
  @State imageSrc: string = '';
  @State params: AdjustParams = createDefaultAdjustments();
  @State isComparing: boolean = false;
  @State selectedType: string = 'exposure';
  @State activeTool: string = 'adjust';
  @State saving: boolean = false;
  @State dirty: boolean = false;

  aboutToAppear(): void {
    const raw = this.getUIContext().getRouter().getParams() as Record<string, string>;
    const route = parseEditRouteParams(raw ?? {});
    this.route = route;
    this.errorText = editRouteError(route);
    this.params = createDefaultAdjustments();
    if (route != null && route.source === EditEntrySource.Picker) {
      this.imageSrc = route.imageUri ?? '';
    }
    // source=work：源图/参数恢复待 B 的 WorkRecord sourceImageUri/adjustments 字段接入。
  }

  build() {
    Column() {
      PaperBackground() {
        Column() {
          this.editorTopBar()
          if (this.errorText !== '') {
            this.errorState()
          } else {
            this.editorBody()
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
  editorTopBar() {
    Column() {
      // 返回/保存的 Row 保持原位置不动；标题为独立覆盖层，按屏幕中心绝对居中
      Stack({ alignContent: Alignment.Center }) {
        // 底：返回 + 保存（布局与原来完全一致，标题位用 Blank 占位）
        Row() {
          Image($r('app.media.icon_back'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .fillColor(Theme.PRIMARY)
            .onClick(() => this.tryBack())

          Blank().layoutWeight(1)

          Text('保存')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_BODY_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ON_PRIMARY)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(Theme.SEAL_RED)
            .borderRadius(Theme.RADIUS_DEFAULT)
            .onClick(() => this.save())
        }
        .width('100%')
        .height(Theme.HEADER_HEIGHT)
        .padding({ left: 16, right: 16 })

        // 顶：标题（占满宽度、文本居中，不占位、不拦截点击）
        Text('调色复核')
          .fontFamily(Theme.FONT_SERIF)
          .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
          .fontWeight(600)
          .fontColor(Theme.ON_SURFACE)
          .letterSpacing(2)
          .maxLines(1)
          .width('100%')
          .textAlign(TextAlign.Center)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height(Theme.HEADER_HEIGHT)
    }
    .width('100%')
    .padding({ top: AppStorage.get<number>('statusBarHeight') ?? 0 })
    .backgroundColor(Theme.PAPER_SURFACE_80)
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: Theme.OUTLINE_VARIANT })
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
  editorBody() {
    Column() {
      // 中部预览区：原比例不裁切，占满导航与面板之间
      PreviewArea({
        imageSrc: this.imageSrc,
        params: this.params,
        isComparing: this.isComparing,
        onCompareChange: (down: boolean) => {
          this.isComparing = down;
        }
      })
        .layoutWeight(1)
        .padding({ top: Theme.GUTTER })

      if (this.route?.source === EditEntrySource.Work) {
        Row() {
          Text('续编恢复待 WorkRecord 源图/参数字段接入，当前从默认参数开始')
            .fontFamily(Theme.FONT_SANS)
            .fontSize(Theme.FONT_SIZE_LABEL_MONO_SM)
            .fontColor(Theme.ON_SURFACE_VARIANT_70)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE, top: 4 })
      }

      // 中下部参数面板：仅「调节」工具有内容，其余占位
      if (this.activeTool === 'adjust') {
        AdjustPanel({
          params: this.params,
          selectedType: this.selectedType,
          onChange: (key: string, value: number) => {
            this.updateParam(key, value);
          },
          onSelectType: (key: string) => {
            this.selectedType = key;
          },
          onReset: () => this.showResetOptions(),
          onCompareChange: (down: boolean) => {
            this.isComparing = down;
          }
        })
      } else {
        this.toolPlaceholder()
      }

      // 底部工具导航
      EditorToolBar({
        activeTool: this.activeTool,
        onSelectTool: (key: string) => {
          this.activeTool = key;
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  toolPlaceholder() {
    Column({ space: 8 }) {
      Text(this.activeToolLabel())
        .fontFamily(Theme.FONT_SERIF)
        .fontSize(Theme.FONT_SIZE_HEADLINE_MD)
        .fontWeight(600)
        .fontColor(Theme.ON_SURFACE)
      Text('功能待接入')
        .fontFamily(Theme.FONT_SANS)
        .fontSize(Theme.FONT_SIZE_BODY_MD)
        .fontColor(Theme.ON_SURFACE_VARIANT)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
  }

  private updateParam(key: string, value: number): void {
    const next: AdjustParams = {
      exposure: this.params.exposure,
      brightness: this.params.brightness,
      contrast: this.params.contrast,
      saturation: this.params.saturation
    };
    if (key === 'exposure') {
      next.exposure = value;
    } else if (key === 'brightness') {
      next.brightness = value;
    } else if (key === 'contrast') {
      next.contrast = value;
    } else if (key === 'saturation') {
      next.saturation = value;
    }
    this.params = next;
    this.dirty = true;
  }

  private resetCurrentSlider(): void {
    const next: AdjustParams = {
      exposure: this.params.exposure,
      brightness: this.params.brightness,
      contrast: this.params.contrast,
      saturation: this.params.saturation
    };
    if (this.selectedType === 'exposure') {
      next.exposure = 0;
    } else if (this.selectedType === 'brightness') {
      next.brightness = 0;
    } else if (this.selectedType === 'contrast') {
      next.contrast = 0;
    } else if (this.selectedType === 'saturation') {
      next.saturation = 0;
    }
    this.params = next;
    this.dirty = true;
  }

  private resetAllSliders(): void {
    this.params = createDefaultAdjustments();
    this.isComparing = false;
    this.dirty = false;
  }

  private showResetOptions(): void {
    this.getUIContext().showActionSheet({
      title: '重置',
      message: '选择重置范围',
      sheets: [
        { title: '重置当前区域', action: () => this.resetCurrentSlider() },
        { title: '全部重置', action: () => this.resetAllSliders() }
      ],
      cancel: () => {
      }
    });
  }

  private activeToolLabel(): string {
    for (let i = 0; i < EDITOR_TOOLS.length; i++) {
      if (EDITOR_TOOLS[i].key === this.activeTool) {
        return EDITOR_TOOLS[i].label;
      }
    }
    return '';
  }

  private save(): void {
    if (this.saving) {
      return;
    }
    this.saving = true;
    const route = this.route;
    const intent = buildSaveIntent(
      route?.source ?? EditEntrySource.Picker,
      route?.workId ?? '',
      this.imageSrc,
      this.params,
      Date.now()
    );
    if (intent.mode === SaveMode.Update) {
      const updated = EditWorkStore.update(intent.id ?? '', intent.draft);
      if (updated == null) {
        this.saving = false;
        this.toast('卷宗不存在，无法续编');
        return;
      }
    } else {
      EditWorkStore.create(intent.draft);
    }
    this.dirty = false;
    this.saving = false;
    this.toast(intent.mode === SaveMode.Update ? '已续编保存' : '已落印保存');
    this.getUIContext().getRouter().back();
  }

  private tryBack(): void {
    if (this.dirty && this.errorText === '') {
      this.getUIContext().showAlertDialog({
        title: '放弃未保存的调整？',
        message: '当前调整尚未落印，返回将丢失。',
        primaryButton: {
          value: '继续编辑',
          action: () => {
          }
        },
        secondaryButton: {
          value: '放弃返回',
          action: () => this.getUIContext().getRouter().back()
        },
        cancel: () => {
        }
      });
    } else {
      this.getUIContext().getRouter().back();
    }
  }

  onBackPress(): boolean {
    this.tryBack();
    return true;
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      // 提示失败不影响页面
    }
  }
}
