# ArkUI 常用组件速查

> 组件按 容器 / 基础 / 弹层 / 高级 分类，列出构造参数 + 关键属性 + 典型用途。
> 通用属性（所有组件共有）：`width` / `height` / `margin` / `padding` / `backgroundColor` / `border` / `borderRadius` / `opacity` / `visibility` / `enabled` / `constraintSize`。
> 通用事件：`onClick` / `onTouch` / `onAreaChange` / `onVisibleAreaChange` / `gesture` 系列。

## 一、容器组件

| 组件 | 构造参数 | 关键属性 | 用途 |
|---|---|---|---|
| `Column` | 无 | `.space(8)` `.alignItems(HorizontalAlign.Center)` `.justifyContent(FlexAlign.SpaceBetween)` | 纵向布局 |
| `Row` | 无 | `.space(8)` `.alignItems(VerticalAlign.Center)` `.justifyContent(FlexAlign.Start)` | 横向布局 |
| `Stack` | 无 | `.alignContent(Alignment.Center)` | 层叠布局 |
| `Flex` | 无 | `.direction(FlexDirection.Row)` `.wrap(FlexWrap.Wrap)` `.justifyContent()` `.alignItems()` | 弹性布局 |
| `RelativeContainer` | 无 | 子组件用 `.alignRules({ left: { anchor: 'X', align: HorizontalAlign.End } })` | 相对定位（替代 RelativeContainer） |
| `Grid` | `GridItem[]` 或 `GridCol` | `.columnsTemplate('1fr 2fr 1fr')` `.rowsGap(8)` `.columnsGap(8)` | 网格布局 |
| `List` | 无 | `.divider()` `.cachedCount(50)` `.scrollBar(BarState.Auto)` `.edgeEffect(EdgeEffect.Spring)` | 列表（配合 `ListItem`） |
| `ListItem` | 无 | `.swipeAction({ right: deleteBtn })` | `List` 的子项 |
| `ListItemGroup` | `{ header?: ()=>void, footer?: ()=>void }` | 同 `List` | `List` 分组 |
| `Scroll` | 无 | `.scrollable(ScrollDirection.Vertical)` `.scrollBar(BarState.Auto)` `.edgeEffect()` | 滚动容器 |
| `Tabs` | `{ barPosition: BarPosition.Start }` | `.barWidth()` `.barHeight()` `.onChange(index => {})` `.scrollable(false)` | 选项卡（配合 `TabContent`） |
| `TabContent` | 无 | `.tabBar( ()=>CustomTab )` | `Tabs` 的内容页 |
| `Swiper` | 无 | `.index(0)` `.autoPlay(true)` `.interval(3000)` `.indicator(Indicator.dot())` `.loop(true)` | 轮播 |
| `WaterFlow` | 无 | 搭配 `FlowItem` | 瀑布流（配合 `LazyForEach`） |
| `Navigation` | `{ name?: string, navBarWidth?: Length }` | `.title()` `.menus()` `.toolBar()` `.hideTitleBar()` `.mode(NavigationMode.Auto)` | 页面导航容器 |
| `NavDestination` | 无 | `.title()` `.toolbar()` `.onBackPressed(() => boolean)` | `Navigation` 内的页面 |
| `Router`（老） | 无 | 通过 `@ohos.router` API 操作 | 老项目页面路由（新项目用 Navigation） |

## 二、基础组件

| 组件 | 构造参数 | 关键属性 |
|---|---|---|
| `Text` | `content?: string` | `.fontSize(16)` `.fontColor(Color.Black)` `.fontWeight(FontWeight.Bold)` `.maxLines(2)` `.textOverflow({ overflow: TextOverflow.Ellipsis })` `.decoration({ type: TextDecorationType.Underline })` |
| `Image` | `src: string \| Resource` | `.objectFit(ImageFit.Cover)` `.alt(failImg)` `.interpolation(ImageInterpolation.Low)` `.borderRadius(8)` |
| `Button` | `label?: string, type?: ButtonType` | `.onClick(() => {})` `.type(ButtonType.Capsule)` `.stateEffect(true)` `.backgroundColor()` |
| `TextInput` | `{ placeholder?: string, text?: string }` | `.onChange(v => {})` `.type(InputType.Password)` `.maxLength(100)` `.caretColor()` |
| `TextArea` | `{ placeholder?: string, text?: string }` | `.onChange()` `.maxLength()` `.height()` |
| `Checkbox` | `{ name?: string, info?: string }` | `.select(true)` `.selectedColor()` `.onChange(v => {})` |
| `Radio` | `{ value: string, group: string }` | `.checked(true)` `.onChange(isChecked => {})` |
| `Toggle` | `{ type: ToggleType.Switch, isOn: boolean }` | `.onChange(isOn => {})` `.switchPointColor()` |
| `Slider` | `{ value: number, min?: number, max?: number, step?: number }` | `.onChange(v => {})` `.block` 系列属性 |
| `Progress` | `{ value: number, total?: number, type?: ProgressType }` | `.color()` `.style()` |
| `LoadingProgress` | 无 | `.color()` `.width()` `.height()` |
| `Marquee` | `{ text: string }` | `.speed(100)` `.direction(MarqueeDirection.Left)` `.onChange()` |
| `RichText` | `{ content: string }` | HTML 片段渲染 |
| `Search` | `{ value?: string }` | `.placeholder()` `.onSubmit()` `.onChange()` |
| `Divider` | 无 | `.vertical(false)` `.strokeWidth(1)` `.color()` `.margin()` |
| `Blank` | 无 | `.color()` | `Row`/`Column`/`Flex` 中撑开空白 |
| `QRCode` | `{ value: string }` | `.color()` `.backgroundColor()` |
| `Web` | `{ src: string, controller: WebviewController }` | `.javaScriptAccess(true)` `.onPageBegin()` `.onPageEnd()` |
| `XComponent` | `{ id: string, type: XComponentType, controller }` | 嵌入 Native 渲染（OpenGL/Vulkan） |

## 三、弹层 / 弹窗

| API / 组件 | 用途 | 备注 |
|---|---|---|
| `AlertDialog.show({...})` | 系统弹窗（确认/取消） | 简单场景 |
| `AlertDialog.show({ title, message, primaryButton, secondaryButton })` | 自定义按钮弹窗 | - |
| `CustomDialog`（V1） | 自定义弹窗类 | 继承 `CustomDialogController` |
| `openCustomDialog`（V2） | `context.getUIContext().getPromptAction().openCustomDialog()` | V2 推荐方式 |
| `ActionSheet.show({...})` | 底部操作菜单 | 多个选项场景 |
| `DatePicker` / `TimePicker` | 日期/时间选择 | 可独立或嵌入弹窗 |
| `TextPicker` | 文本滚轮选择 | - |
| `Popup`（组件方法） | `.popup({ content, placement })` | 附着在某组件上的气泡 |
| `Menu` | `.bindMenu([...])` | 右键菜单 / 长按菜单 |
| `Sheet` | `.bindSheet()` | 半模态底部抽屉 |
| `SideBarContainer` | `{ side: SideBarSide.Left }` | 侧边栏 |
| `GridCol` + 自适应 | - | 双栏/三栏自适应布局 |

## 四、高级 / 动画 / 绘制

| 组件或方法 | 用途 |
|---|---|
| `Canvas` | 2D 自绘（`CanvasRenderingContext2D`） |
| `@ohos.graphics.drawing` | 高级 2D 绘制（Canvas/Path/Pen/Brush） |
| `animateTo({ duration, curve }, () => { /* 状态变化 */ })` | 显式动画 |
| `.animation({ duration, curve, delay })` | 属性变化隐式动画 |
| `.transition({ type, translate, scale, opacity })` | 组件进出场动画 |
| `.geometryTransition({ id })` | 跨页面共享元素动画 |
| `.keyframeAnimateTo` | 关键帧动画 |
| `.morphTo({ options })` | 形变动画（V2） |

## 五、媒体相关组件

| 组件 | 用途 |
|---|---|
| `Video` | 视频播放（`{ src, controller }` + `.autoPlay()` `.controls()`） |
| `AVPlayer`（API） | 更底层的音视频播放控制 |
| `Camera`（API via `@ohos.multimedia.camera`） | 相机预览 |
| `CameraPreview`（组件） | 相机预览组件 |

## 六、选择组件的小决策

```
需要纵向排列多个组件？ → Column
需要横向排列？ → Row
需要层叠（如叠加蒙版）？ → Stack
需要自适应换行？ → Flex
需要精确对齐到某个锚点？ → RelativeContainer
需要网格？ → Grid
需要 100+ 项的列表？ → List + LazyForEach
需要分组列表？ → List + ListItemGroup
需要横向滑动切换？ → Swiper
需要选项卡？ → Tabs + TabContent
需要瀑布流？ → WaterFlow + FlowItem
需要导航容器（多页面 + 标题栏）？ → Navigation + NavDestination
```

## 七、组件通用写法速记

```typescript
// 完整示例：卡片
Column() {
  Image($r('app.media.cover'))
    .width('100%')
    .height(160)
    .objectFit(ImageFit.Cover)
    .borderRadius({ topLeft: 8, topRight: 8 })
  Column() {
    Text('标题')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    Text('副标题副标题副标题')
      .fontSize(14)
      .fontColor($r('app.color.secondary'))
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .padding(12)
  .width('100%')
}
.width(200)
.backgroundColor(Color.White)
.borderRadius(8)
.shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
.onClick(() => { /* ... */ })
```

## 八、相关 slug

- `harmonyos-guides/arkts-declarative-ui-description` — 声明式 UI 描述
- `harmonyos-guides/arkts-create-custom-components` — 自定义组件
- `harmonyos-guides/arkts-layout-development-overview` — 布局开发总览
- `harmonyos-guides/arkts-animation-overview` — 动画总览
- `harmonyos-references/ts-basic-components-navigation` — Navigation API
- `harmonyos-references/ts-basic-components-navdestination` — NavDestination API
- `harmonyos-references/ts-container-list` — List API
- `harmonyos-references/ts-basic-components-column` — Column API
- `harmonyos-references/ts-basic-components-row` — Row API
- `harmonyos-references/ts-basic-components-stack` — Stack API
