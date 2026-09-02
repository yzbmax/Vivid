# Vivid_0.1.9更新计划

> 供 Vivid 三人开发组执行。实施前以 `merge/all-three` 的 `c88e24a` 为共同基线；本文只定义工作，不代表当前会话已创建分支、提交或推送。

## 一、版本目标

Vivid 0.1.9 在现有图片编辑链路中完成以下更新：

1. 新增 8 款离线 LUT 滤镜；
2. 增加可直接叠加在照片上的文字图层，内置 5 款字体；
3. 把当前“模板”工具整体改为“边框”，提供 6 款离线边框；
4. 让滤镜、文字和边框同时进入实时预览、草稿保存、作品续编、缩略图和正式导出链路。

功能完成标准不是“编辑页能看到”，而是同一份编辑状态能够被保存、恢复并稳定合成到导出图片中。

## 二、冻结范围

### 2.1 新增滤镜

| ID | 名称 | 默认强度 | 视觉方向 |
|---|---|---:|---|
| `jade_mist` | 玉烟 | 0.68 | 低饱和青绿、柔和高光 |
| `cinnabar_glow` | 丹霞 | 0.65 | 暖红高光、轻微暖肤 |
| `ink_noir` | 墨影 | 0.80 | 冷调高反差黑白 |
| `rice_paper` | 宣纸 | 0.62 | 低对比、暖白、轻褪色 |
| `tea_film` | 茶褐 | 0.72 | 胶片褐色、压低蓝色 |
| `celadon_cool` | 青瓷 | 0.70 | 青蓝阴影、克制饱和度 |
| `amber_hour` | 琥珀 | 0.66 | 日落金黄、柔化阴影 |
| `moonlit_blue` | 月青 | 0.74 | 深蓝夜景、保留亮部 |

每款滤镜使用独立 `.cube` 文件、稳定 `id`、递增 `version` 和独立缩略图缓存键；不增加网络下载逻辑。

### 2.2 文字功能

- 单张作品最多 8 个文字图层；
- 每层 1–80 个 Unicode 字符，最多 3 行；
- 支持新增、选中、重新编辑、拖动和删除；
- 支持字体、字号、颜色、位置、旋转和透明度；
- 字号为照片长边的 2%–20%；
- 旋转为 `-180°…180°`；
- 透明度为 `30%…100%`；
- 位置保存为照片内容区域内的归一化中心坐标。

内置字体：

| `fontKey` | 名称 | 资源或回退 |
|---|---|---|
| `system_sans` | 鸿蒙黑体 | 系统 `HarmonyOS Sans SC` |
| `noto_serif_sc` | 思源宋体 | `rawfile/fonts/notoserifsc.ttf` |
| `gkai` | 古籍楷体 | `rawfile/fonts/gkai.ttf` |
| `system_mono` | 等宽题签 | 系统等宽字体，失败回退鸿蒙黑体 |
| `noto_serif_latin` | 西文衬线 | `rawfile/fonts/notoserif.ttf`，中文回退思源宋体 |

颜色使用 8 个固定色板，不提供任意取色器。

### 2.3 “模板”迁移为“边框”

本版本不增加第 8 个编辑工具，而是直接替换现有占位入口：

- `EditorToolKey` 从 `template` 改为 `border`；
- `EDITOR_TOOL_KEYS` 和 `EDITOR_TOOLS` 仍保持 7 项，最后一项显示“边框”；
- 编辑器底部工具栏把“模板”替换为“边框”；
- 首页第 8 个快捷工具从“模板”替换为“边框”；
- 首页点击后打开编辑页并激活 `border` 面板；
- 历史路由、待处理编辑意图和旧作品中的 `template` 兼容映射为 `border`；
- 贴纸域的 `StickerTemplate` 不在本次迁移范围内，不得批量改名；
- 新增 `home_border.svg` 并切换引用，不删除已有 `home_Template.svg`。

边框目录：

| `templateId` | 名称 | 结构 |
|---|---|---|
| `none` | 无装裱 | 不扩展画布 |
| `paper_white` | 宣纸留白 | 四边等宽浅色留白 |
| `ink_black` | 墨框 | 四边等宽深色留白 |
| `floating_shadow` | 浮光卡片 | 外画布、投影、悬浮感 |
| `film_negative` | 胶片边框 | 深色边框、齿孔、底片编号 |
| `polaroid` | 拍立得 | 左右上窄、底部加宽 |
| `scroll_mount` | 卷轴装裱 | 宣纸外框、朱砂内线、角标 |

统一参数为 `widthRatio: 0…0.25`、`colorArgb` 和 `shadowStrength: 0…1`。边框只扩展画布，不得裁剪照片。

### 2.4 本版本不做

- 在线滤镜、字体或边框市场；
- 用户导入字体、Logo、签名或第三方素材；
- EXIF 水印、相机品牌水印、自动字幕、多图拼接；
- 渐变文字、文字描边、文字阴影和字距控制；
- 视频、Live Photo、RAW、批量处理；
- SDK、构建系统、状态管理方案或核心依赖升级；
- 对现有贴纸系统的重构。

## 三、共享架构与冻结契约

### 3.1 统一编辑快照

由开发者 C 新建并独占维护：

`entry/src/main/ets/models/SharedContracts.ets`

冻结接口：

```typescript
export interface FilterSnapshot {
  filterId: string;
  strength: number;
}

export interface TextLayer {
  id: string;
  content: string;
  fontKey: string;
  colorArgb: number;
  fontSizeRatio: number;
  centerX: number;
  centerY: number;
  rotationDeg: number;
  opacity: number;
}

export interface BorderState {
  templateId: string;
  widthRatio: number;
  colorArgb: number;
  shadowStrength: number;
}

export interface EditorSnapshot {
  schemaVersion: number;
  filter: FilterSnapshot;
  textLayers: TextLayer[];
  border: BorderState;
}
```

`schemaVersion` 在 0.1.9 固定为 `1`。`WorkRecord.editorSnapshot` 为可选字段；旧作品缺失快照时使用原图滤镜、空文字数组和 `none` 边框。

所有快照写入必须深拷贝；非法数字在进入编辑会话时钳制；未知滤镜、字体或边框 ID 使用安全默认值。

### 3.2 统一渲染顺序

```text
原图解码
  → LUT 滤镜
  → 现有全局调节与蒙版调节
  → 文字图层
  → 边框扩展画布
  → 预览 / 缩略图 / 保存 / 再次导出
```

文字坐标始终相对照片内容区域计算；改变边框宽度不得移动文字相对照片的位置。

### 3.3 预览与导出一致性

- 编辑过程：`PreviewPipeline` 提供滤镜与调色 PixelMap，ArkUI 交互层显示文字和边框；
- 最终输出：`EditorCompositionService` 在全分辨率 PixelMap 上按相同顺序合成；
- `TextLayoutResolver` 和 `BorderLayoutResolver` 必须是无 UI 依赖的纯逻辑；
- 预览与导出共享归一化坐标、字号、旋转、边宽和模板几何规则；
- 容许误差：文字中心点不超过输出长边的 0.5%，字号不超过 1 px，边框四边不超过 1 px。

## 四、三位开发者任务范围

### 开发者 A：文字图层与首页边框入口

负责范围：

- `entry/src/main/ets/features/editor/text/*`
- `entry/src/main/ets/components/editor/text/*`
- `entry/src/main/ets/components/editor/TextPanel.ets`
- `entry/src/main/ets/components/editor/TextLayer.ets`
- `entry/src/main/ets/components/home/HomePage.ets`
- `entry/src/main/resources/base/element/string.json` 中的 `home_tool8`
- 新增 `entry/src/main/resources/base/media/home_border.svg`
- `entry/src/test/TextLayerState.test.ets`
- `entry/src/test/TextLayoutResolver.test.ets`
- `EditPage.ets` 的 `// ===== A: Text Layer =====` 区块

交付：字体目录、文字状态纯函数、文字面板、文字预览交互层、布局解析器、首页“边框”快捷入口和对应测试。

不得修改：保存/导出服务、滤镜目录、边框目录、共享契约。

### 开发者 B：高清合成、保存与导出

负责范围：

- 新增 `entry/src/main/ets/services/EditorCompositionService.ets`
- 新增 `entry/src/main/ets/services/TextCompositionService.ets`
- 新增 `entry/src/main/ets/services/BorderCompositionService.ets`
- 修改 `entry/src/main/ets/services/ImageRenderService.ets`
- 修改 `entry/src/main/ets/services/WorkSaveService.ets`
- 修改 `entry/src/main/ets/services/PhotoExportService.ets`
- 修改 `entry/src/main/ets/models/WorkRecord.ets`
- 修改 `entry/src/main/ets/models/MockWorkStore.ets`
- 修改 `entry/src/test/MockWorkStore.test.ets`
- 新增 `entry/src/test/EditorSnapshot.test.ets`
- 新增 `entry/src/test/EditorCompositionModels.test.ets`

交付：兼容旧作品的快照持久化、深拷贝、统一高清合成、首次保存、作品再次导出和错误映射。

不得修改：`EditPage.ets`、编辑器 UI、滤镜/文字/边框目录、共享契约。

### 开发者 C：共享契约、滤镜、边框与最终集成

负责范围：

- 新增 `entry/src/main/ets/models/SharedContracts.ets`
- 修改 `entry/src/main/ets/models/EditModels.ets`
- `entry/src/main/ets/features/editor/filter/*`
- 新增 `entry/src/main/ets/features/editor/border/*`
- 新增 `entry/src/main/ets/components/editor/BorderPanel.ets`
- 新增 `entry/src/main/ets/components/editor/BorderPreviewLayer.ets`
- 修改 `entry/src/main/ets/components/editor/EditorToolBar.ets`
- 修改 `entry/src/main/ets/components/editor/FilterPanel.ets`
- 修改 `entry/src/main/ets/components/editor/PreviewArea.ets`
- 新增 `entry/src/main/resources/rawfile/filters/*.cube`
- 新增 `entry/src/main/resources/base/media/border_*.svg`
- 修改 `entry/src/main/ets/services/ThumbnailPipeline.ets`
- 修改 `entry/src/test/EditModels.test.ets`
- 修改 `entry/src/test/FilterState.test.ets`
- 新增 `entry/src/test/BorderState.test.ets`
- 最终修改 `entry/src/test/List.test.ets`
- `EditPage.ets` 的 `// ===== C: Filter & Border =====` 与 `// ===== C: Editor Snapshot Bridge =====` 区块

交付：共享类型、`template → border` 兼容迁移、8 款 LUT、6 款边框、编辑页最终接线、测试注册和集成验证汇总。

不得修改：A 的文字区块、B 的服务内部实现。

## 五、实施任务

以下任务按依赖顺序执行。每个开发者先写失败测试，再写最小实现，再运行直接相关测试；只有共享契约合入后 A、B 才开始导入该类型。

### 任务 0：冻结共享契约和工具键迁移（C，阻塞 A/B）

文件：

- 新建 `entry/src/main/ets/models/SharedContracts.ets`
- 修改 `entry/src/main/ets/models/EditModels.ets`
- 修改 `entry/src/test/EditModels.test.ets`

步骤：

1. 在 `EditModels.test.ets` 增加失败测试：工具总数仍为 7、最后一项为 `border/边框`、`template` 不再出现在公开工具键中。
2. 增加兼容测试：解析旧值 `template` 时归一化为 `border`；未知值仍回退 `adjust`。
3. 新建四个共享接口和安全默认值构造函数。
4. 实现 `normalizeEditorToolKey()`，集中处理 `template → border`，禁止在页面里散落字符串兼容判断。
5. 修改 `EDITOR_TOOL_KEYS` 和 `EDITOR_TOOLS`。
6. 运行 `EditModels.test.ets` 直接相关测试，确认先红后绿。
7. 三人评审字段、默认值和坐标语义；冻结后 A/B 只导入，不直接编辑。

验收：`template` 不再作为公开工具键，但旧输入不会失效；共享契约没有 UI 或服务依赖。

### 任务 1：文字状态、字体与布局纯逻辑（A）

文件：

- 新建 `entry/src/main/ets/features/editor/text/FontCatalog.ets`
- 新建 `entry/src/main/ets/features/editor/text/TextLayerState.ets`
- 新建 `entry/src/main/ets/features/editor/text/TextLayoutResolver.ets`
- 新建 `entry/src/test/TextLayerState.test.ets`
- 新建 `entry/src/test/TextLayoutResolver.test.ets`

步骤：

1. 写状态测试：空白文本拒绝创建、81 字截断或拒绝、超过 3 行拒绝、最多 8 层、删除选中层后选择安全回退。
2. 写参数测试：字号、旋转、透明度和归一化坐标在边界内钳制。
3. 写布局测试：同一 `TextLayer` 在两种输出尺寸下保持相同比例；旋转不改变保存坐标。
4. 实现 `FontCatalog` 的 5 个字体条目和确定性回退链。
5. 实现不可变的新增、更新、删除、选中和校验函数。
6. 实现 `TextLayoutResolver`，输入照片内容矩形和 `TextLayer`，输出像素中心、字号、旋转和透明度。
7. 运行两个新增测试文件。

验收：纯逻辑无 ArkUI 依赖，任何非法输入都得到稳定结果，不修改传入数组或对象。

### 任务 2：文字面板与预览交互（A）

文件：

- 新建 `entry/src/main/ets/components/editor/TextPanel.ets`
- 新建 `entry/src/main/ets/components/editor/TextLayer.ets`
- 按需新建 `entry/src/main/ets/components/editor/text/*`
- 修改 `entry/src/main/ets/pages/EditPage.ets` 的 A 专属区块

步骤：

1. 先为面板事件转换函数补测试，验证输入、确认、删除、字体和参数变更只产生新的 `TextLayer[]`。
2. 在编辑页建立 `textLayers`、`selectedTextLayerId` 和输入框状态。
3. 实现“添题签”、编辑、删除和 8 层上限提示。
4. 实现 5 字体选择、8 色板、字号、旋转和透明度控件。
5. 在照片内容区域叠加文字；拖动时通过 `TextLayoutResolver` 反算归一化坐标。
6. 键盘出现时保持输入框和确认按钮可见；全空白内容不得创建。
7. 仅运行文字相关测试和 ArkTS 静态检查。

验收：横图、竖图和长图上拖动均受照片内容区域约束；切换面板不丢失文字状态。

### 任务 3：首页“模板”入口改为“边框”（A）

文件：

- 修改 `entry/src/main/ets/components/home/HomePage.ets`
- 修改 `entry/src/main/resources/base/element/string.json`
- 新增 `entry/src/main/resources/base/media/home_border.svg`

步骤：

1. 将第 8 个 `ToolItem` 的 key 从 `template` 改为 `border`。
2. 将 `home_tool8` 的值从“模板”改为“边框”。
3. 新增符合 Mask & Seal 视觉语言的边框图标，并切换 `$r('app.media.home_border')` 引用。
4. 保留 `home_Template.svg`，不做删除或批量资源改名。
5. 检查首页点击后生成的编辑意图携带 `initialTool: 'border'`。
6. 运行相关模型/路由测试；本任务不单独跑完整构建。

验收：首页不再显示“模板”，点击“边框”能够进入编辑器边框工具。

### 任务 4：8 款 LUT 与缩略图（C，可与任务 1–3 并行）

文件：

- 新增 8 个 `entry/src/main/resources/rawfile/filters/*.cube`
- 修改 `entry/src/main/ets/features/editor/filter/FilterCatalog.ets`
- 修改 `entry/src/main/ets/services/ThumbnailPipeline.ets`
- 修改 `entry/src/test/FilterState.test.ets`

步骤：

1. 先写目录测试，断言 8 个 ID、名称、默认强度、唯一资源路径和有效版本号。
2. 为缩略图缓存键写测试，确保包含 `sessionId + preset.id + preset.version`。
3. 添加 8 个 LUT 文件，检查文件头、网格大小和数据行数量。
4. 将预设注册到 `FilterCatalog`，保持原有滤镜顺序不变，新滤镜追加在现有目录尾部。
5. 确认强度为 0 时输出原图，默认强度来自预设。
6. 运行滤镜目录和缩略图相关测试。

验收：8 款滤镜均可被原生桥加载，资源缺失时返回既有错误而非崩溃，缓存互不串图。

### 任务 5：边框状态、模板几何与资源（C）

文件：

- 新建 `entry/src/main/ets/features/editor/border/BorderCatalog.ets`
- 新建 `entry/src/main/ets/features/editor/border/BorderState.ets`
- 新建 `entry/src/main/ets/features/editor/border/BorderLayoutResolver.ets`
- 新增 `entry/src/main/resources/base/media/border_*.svg`
- 新建 `entry/src/test/BorderState.test.ets`

步骤：

1. 写目录测试：`none` 加 6 个真实模板 ID 唯一，能力声明完整。
2. 写参数测试：边宽、颜色、投影钳制；不支持的参数由模板能力禁用。
3. 写几何测试：横图、竖图、长图均完整保留照片，输出画布只向外扩展。
4. 写特殊模板测试：拍立得底边更宽，胶片齿孔不侵入照片，卷轴内线位于外框内。
5. 实现边框目录、状态纯函数和 `BorderLayoutResolver`。
6. 添加 6 款预览 SVG 资源；几何数值必须来自 resolver，而不是 UI 中重复硬编码。
7. 运行 `BorderState.test.ets`。

验收：相同状态在预览尺寸和导出尺寸下产生相同比例；`none` 不改变画布尺寸。

### 任务 6：边框面板、工具栏和预览（C）

文件：

- 新建 `entry/src/main/ets/components/editor/BorderPanel.ets`
- 新建 `entry/src/main/ets/components/editor/BorderPreviewLayer.ets`
- 修改 `entry/src/main/ets/components/editor/EditorToolBar.ets`
- 修改 `entry/src/main/ets/components/editor/PreviewArea.ets`
- 修改 `entry/src/main/ets/pages/EditPage.ets` 的 C 边框区块

步骤：

1. 将工具栏末项显示为“边框”，工具总数保持 7。
2. 实现“边式”横向选择列表和选中态。
3. 实现边宽、色纸、投影控件；根据模板能力禁用无效控件。
4. 使用 `BorderPreviewLayer` 显示完整照片与外扩边框，禁止 `ImageFit.Cover` 裁切。
5. 让 `template` 兼容路由进入同一个 `border` 面板，不保留空白模板面板。
6. 运行 `EditModels`、边框状态和预览相关测试。

验收：编辑器中无用户可见“模板”入口；连续切换边式时旧异步结果不得覆盖新状态。

### 任务 7：快照持久化与旧作品兼容（B，依赖任务 0）

文件：

- 修改 `entry/src/main/ets/models/WorkRecord.ets`
- 修改 `entry/src/main/ets/models/MockWorkStore.ets`
- 修改 `entry/src/main/ets/services/WorkSaveService.ets`
- 修改 `entry/src/test/MockWorkStore.test.ets`
- 新建 `entry/src/test/EditorSnapshot.test.ets`

步骤：

1. 写失败测试：新增/更新作品时 `editorSnapshot` 深拷贝，后续修改请求对象不污染存储记录。
2. 写兼容测试：旧作品没有快照时得到安全默认值；旧 `lastTool: 'template'` 恢复为 `border`。
3. 给 `WorkRecord` 增加可选 `editorSnapshot`，不给旧构造调用增加强制参数。
4. 扩展 `WorkSaveRequest`，接收当前完整 `EditorSnapshot`。
5. 修改 `MockWorkStore.update()`，逐层深拷贝滤镜、文字数组和边框对象。
6. 修改草稿保存与作品保存逻辑，持久化同一份规范化快照。
7. 运行 `MockWorkStore.test.ets` 和 `EditorSnapshot.test.ets`。

验收：保存、退出、恢复后滤镜 ID/强度、每个文字字段和边框参数逐项一致；旧作品可正常打开。

### 任务 8：统一高清合成服务（B）

文件：

- 新建 `entry/src/main/ets/services/EditorCompositionService.ets`
- 新建 `entry/src/main/ets/services/TextCompositionService.ets`
- 新建 `entry/src/main/ets/services/BorderCompositionService.ets`
- 修改 `entry/src/main/ets/services/ImageRenderService.ets`
- 修改 `entry/src/main/ets/services/PhotoExportService.ets`
- 新建 `entry/src/test/EditorCompositionModels.test.ets`

步骤：

1. 先检查当前 HarmonyOS SDK 的 PixelMap、Canvas、字体注册与编码 API 声明，记录可用调用和错误码；不升级 SDK或引入大型依赖。
2. 写模型级失败测试：固定输入尺寸下，合成顺序必须是滤镜/调节 → 文字 → 边框。
3. 写文字绘制命令测试：字体回退、中心坐标、字号、旋转、透明度和图层顺序确定。
4. 写边框绘制命令测试：输出尺寸、照片偏移、四边宽度、投影范围和装饰元素确定。
5. 实现 `TextCompositionService` 与 `BorderCompositionService`，复用 A/C 的 resolver，不复制比例算法。
6. 实现 `EditorCompositionService.render()`，返回最终 PixelMap 和可用于诊断的输出尺寸。
7. 保留 `ImageRenderService.render()` 现有调用兼容层，将新路径统一导向合成服务。
8. 由 `PhotoExportService` 只负责编码/写相册，不再自行解释编辑状态。
9. 运行合成模型、字体回退和边框几何测试。

验收：预览和导出使用相同 resolver；合成失败时释放中间 PixelMap 并返回明确错误，不泄漏资源。

### 任务 9：保存、再次导出与编辑页快照桥接（B/C 串行）

文件所有权：

- B 修改 `WorkSaveService.ets` 的保存/导出内部实现；
- C 修改 `EditPage.ets` 的 `// ===== C: Editor Snapshot Bridge =====` 区块；
- 双方不得在同一个提交中交叉修改对方文件。

步骤：

1. B 写失败测试：`save()` 和 `exportWork()` 都向 `EditorCompositionService` 传递作品自身完整快照。
2. B 修改首次保存、覆盖保存和作品再次导出，禁止只携带 `adjustments`。
3. C 在编辑页集中实现 `buildEditorSnapshot()`，把当前滤镜、文字和边框规范化后传给保存请求。
4. C 在续编初始化时恢复快照；无快照使用默认值；旧 `template` 恢复成 `border`。
5. C 确认路由 `initialTool`、当前工具和保存的 `lastTool` 都使用归一化后的 `EditorToolKey`。
6. B 运行保存/导出服务测试，C 运行编辑模型与状态测试。

验收：首次保存生成的图片、作品页再次导出的图片和同参数编辑预览在允许误差内一致。

### 任务 10：测试注册、联合回归与发布前验证（C 汇总，三人共同执行）

文件：

- 修改 `entry/src/test/List.test.ets`
- 只在发现本版本缺陷时修改对应所有者文件，不做无关重构

步骤：

1. C 将新增测试套件注册到 `List.test.ets`。
2. A 验证文字：5 字体、8 色、8 层上限、横竖长图、键盘、删除与恢复。
3. B 验证合成：首次保存、草稿恢复、作品再次导出、资源释放和错误路径。
4. C 验证 8 滤镜、6 边框、`template → border` 路由兼容、首页入口和工具栏。
5. 运行项目测试：

   ```powershell
   $env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
   $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
   & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug test --no-daemon --no-incremental
   ```

6. 因本版本修改共享模型、保存和导出链路，测试通过后运行一次 debug ArkTS 构建：

   ```powershell
   $env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
   $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
   & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug 'default@BuildArkTS' --no-daemon --no-incremental
   ```

7. 在真机验证字体实际加载、系统相册导出、高分辨率合成和内存占用；没有真机时必须标记未验证。
8. 对下列输入做截图和参数记录：横图、竖图、长图、中文、英文、中英混排、旋转文字、最大边框、投影边框。
9. 三人分别检查自己范围的 `git diff`，C 汇总测试结果和遗留风险。

验收：测试、静态检查和 debug 构建有真实通过记录；真机未验证项不得写成已通过。

## 六、协作与合入顺序

### 6.1 分支建议

- `codex/shared-contracts`
- `codex/a-text-layers`
- `codex/b-editor-composition`
- `codex/c-filter-border`

实际创建分支、提交、推送和合并前，仍需按仓库规则检查 `git status`、当前分支和远程状态，并取得对应操作授权。

### 6.2 固定顺序

```text
C：shared-contracts
  → A：text-layers + home-border-entry
  → B：editor-composition + persistence
  → C：filter-border-integration
  → 三人联合回归
```

可并行开发：任务 1–3 与任务 4–6；B 可在共享契约冻结后开发任务 7–8。最终接线任务 9 必须在 A/B/C 的公共接口稳定后进行。

### 6.3 冲突规则

- `SharedContracts.ets`：C 唯一写入；
- `EditPage.ets`：A/C 只写各自标记区块；
- `List.test.ets`：C 最后统一注册；
- `string.json`、`HomePage.ets`：A 唯一写入；
- 保存与导出服务：B 唯一写入；
- 共享字段需要变化时，先三人确认，再由 C 追加兼容字段；
- 不使用 `git add .`，只暂存当前任务文件；
- 不自动解决来源不明的修改，不删除现有文件，不重写公开历史。

## 七、界面与文案约束

沿用 Mask & Seal（炎国卷轴 · 文书钤印）语言：

- 工具栏显示“文字”“边框”，面板内用“题签”“添题签”“装裱”“边式”；
- 选中态使用朱砂 `#b23b2f`，主要动作使用 `#7b171b`；
- 面板使用纸白表面，标题使用衬线字体，参数标签使用等宽字体；
- 滑块沿用朱砂方块滑块头，不引入新的控件体系；
- 边框缩略图使用四角括号和浅朱砂内线；
- 首页、编辑器和辅助提示中不得再把新功能称为“模板”。

## 八、验收清单

- [ ] 新增 8 款滤镜可选、可调强度、有缩略图、可保存和导出；
- [ ] 最多 8 个文字图层可新增、编辑、拖动、旋转、调透明度和删除；
- [ ] 5 款字体在预览和导出中执行同一回退规则；
- [ ] 编辑器工具总数仍为 7，“模板”已替换为“边框”；
- [ ] 首页第 8 个快捷入口显示“边框”并打开边框面板；
- [ ] 旧 `template` 输入兼容映射到 `border`；
- [ ] 贴纸域 `StickerTemplate` 未被误改；
- [ ] 6 款边框均完整保留照片并按规则扩展画布；
- [ ] 草稿和作品续编完整恢复 `EditorSnapshot`；
- [ ] 首次保存与作品再次导出使用同一合成管线；
- [ ] 预览与导出一致性达到规定阈值；
- [ ] 新增测试已注册并实际通过；
- [ ] ArkTS 静态检查和 debug 构建实际通过；
- [ ] 真机验证结果及未覆盖风险已有记录；
- [ ] 未新增网络依赖、未升级 SDK、未删除现有文件；
- [ ] 三位开发者没有越过文件所有权边界。

## 九、完成报告模板

每位开发者完成任务后必须报告：

1. 修改文件列表；
2. 已完成能力；
3. 明确未修改范围；
4. 实际运行的测试、静态检查或构建及结果；
5. 未验证内容和风险；
6. 当前分支；
7. 是否创建提交；
8. 是否推送；
9. `git status` 摘要；
10. 需要下一位开发者注意的接口或兼容事项。

详细设计依据见 `docs/superpowers/specs/2026-09-01-vivid-0.1.9-design.md`。
