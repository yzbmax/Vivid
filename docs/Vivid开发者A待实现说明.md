# Vivid 开发者 A 实现与待验收说明

> 更新时间：2026-08-21
> 对应计划：`docs/Vivid下一阶段开发需求计划书.md`
> 责任范围：Task 2、Task 3、Task 8，以及 A 负责的集成回归

## 一、当前结论（2026-08-21）

开发者 C 已合入 `EditorToolKey`、`EditRouteParams.initialTool` 和 `PendingEditIntent` 冻结契约，开发者 A 的代码实现不再受契约阻塞。

开发者 A 已完成导出设置、系统选图服务、单条待续编辑意图、首页登录门禁、主导入与 8 个快捷入口，以及登录/注册成功后的编辑恢复。当前尚未完成的是 C 独占测试文件的最终注册/修复、真机手工回归和项目级构建验收；因此不能表述为完整集成验收通过。

## 二、本轮新增完成

### 2.1 待续编辑意图

文件：

- `entry/src/main/ets/models/PendingEditIntentStore.ets`
- `entry/src/test/PendingEditIntentStore.test.ets`

已实现单条进程内 `set/peek/consume/clear`，所有读写返回对象副本，`consume()` 只返回一次。测试覆盖设置、窥视、覆盖、清除、单次消费和外部对象不可修改内部状态。

### 2.2 首页集中选图与登录门禁

文件：

- `entry/src/main/ets/components/home/HomePage.ets`
- `entry/src/main/ets/components/home/HeroCard.ets`
- `entry/src/main/ets/components/home/HomeModels.ets`
- `entry/src/main/ets/components/home/QuickToolsSection.ets`

已完成：

- `HeroCard` 只通过回调上报点击；
- `HomePage` 使用单一、防重复入口编排选图、认证和路由；
- 取消选图静默留在首页，失败显示原有提示；
- 已登录用户携带 `source/imageUri/initialTool` 进入编辑页；
- 未登录用户保存待续意图并显示“暂不登录 / 前往登录”弹窗；
- 拒绝登录、关闭弹窗和登录页打开失败时清空意图；
- 8 项严格映射为 `subject/filter/background/adjust/subject/sticker/text/template`；
- 快捷格使用现有设计语言下的 `0.98` 按压反馈。

### 2.3 登录与注册恢复

文件：

- `entry/src/main/ets/pages/LoginPage.ets`
- `entry/src/main/ets/pages/RegisterPage.ets`

已完成：

- 登录或注册成功后先刷新 `AuthUiState`，再消费待续意图；
- 有意图时使用 `replaceUrl(EditPage)` 恢复照片和初始工具；
- 路由失败时恢复意图并提示；
- 无意图时保留原有返回逻辑；
- 带待续意图时从登录前往注册使用替换式导航；
- 登录/注册顶部返回和系统返回均清空未消费意图；
- 页面暂时跳往注册页或协议页时不在生命周期回调中误清意图。

### 2.4 选图结果 ArkTS 兼容修正

`PhotoPickerService.ets` 已将内联对象字面量类型改为显式接口，保持原可判别结果语义，并消除 A 文件的 ArkTS Linter 错误。

## 三、伙伴代码审阅结论

已确认可供 A 接入：

- C 的共享编辑契约与冻结计划一致；
- 编辑页能够解析并应用 `initialTool`；
- 作品页、详情页和首页近作已统一使用 `MockWorkStore`；
- `AppSettingsStore.test.ets` 已注册到主测试列表。

仍需伙伴跟进：

1. `entry/src/test/EditModels.test.ets` 仍有 11 处未显式声明类型的对象字面量，导致 `UnitTestArkTS` 编译失败；该文件由 C 独占，A 未修改。
2. 编辑页当前直接重复编排渲染、导出和作品写入，没有复用新增的 `WorkSaveService`；短期不阻塞 A 接入，但两条保存链路存在后续行为漂移风险。
3. ArkTS Linter 对 `PhotoExportService` 报告 `WRITE_IMAGEVIDEO` 权限要求，对 `ImageRenderService` / `WorkFileService` 报告多处可能抛出异常；需要 B/C 在 Task 10 结合 API 24 和真机行为确认。

## 四、仍待实现或验收

### 4.1 等待 C 注册新增测试并修复基线

C 需要在其独占的 `entry/src/test/List.test.ets` 中注册 `PendingEditIntentStore.test.ets`。当前测试在执行测试体前即被 `EditModels.test.ets` 的 ArkTS 编译错误阻断，修复前不能得到完整测试结果。

### 4.2 等待 Task 10 手工与真机验收

仍需覆盖：

- 主导入和 8 个快捷入口的已登录、匿名、取消选图、拒绝登录流程；
- 登录成功、注册成功、登录/注册匿名返回和普通登录无意图流程；
- 设置页退出重进及应用重启后的选择恢复；
- 编辑初始工具定位、页面和日志不泄露照片 URI 或认证信息；
- 相册写入权限、PNG/JPEG 六档导出和作品保存闭环。

### 4.3 构建环境阻断

`default@BuildArkTS` 已完成资源处理和 ArkTS 页面静态检查，A 文件未报告 Linter 错误；随后 DevEco SDK 在生成 source map 时仍触发：

```text
TypeError: Cannot read properties of undefined (reading 'share')
```

因此项目级 debug 构建仍不能标记为通过。

## 五、协作边界记录

- A 未修改 `EditModels.ets`、`EditPage.ets`、`components/editor/`、作品模型、作品 Store 和导出编码实现。
- A 未修改 C 独占的 `entry/src/test/List.test.ets` 与 `EditModels.test.ets`。
- 未删除文件、未新增第三方依赖、未生成签名安装包。
- 本轮未创建分支、未提交、未推送；当前分支仍为 `merge/all-three`。

---

## 六、2026-08-19 历史交接记录（以下阻塞状态已失效）

开发者 A 已完成导出设置的数据模型、持久化 Store、设置页接线和独立的系统选图服务基础。

登录门禁、登录成功后的选图恢复、首页快捷入口以及待续意图 Store 尚未完成。原因是这些功能依赖开发者 C 在 `EditModels.ets` 中冻结共享契约，而当前契约尚未落库。按照协作边界，A 没有复制临时类型，也没有修改 C 独占文件。

## 二、已实现功能

### 2.1 导出设置模型

文件：`entry/src/main/ets/models/AppSettingsModels.ets`

- 新增 `ExportQuality`：标准、高清、超清。
- 新增 `ExportFormat`：JPEG、PNG。
- 新增 `AppExportSettings` 和 `ExportProfile`。
- 新增 `toExportProfile()` 映射：
  - 标准 JPEG：1920px、质量 85；
  - 高清 JPEG：2560px、质量 92；
  - 超清 JPEG：原始尺寸（`maxLongEdge = 0`）、质量 98；
  - PNG 三档均使用无损意图值 100，画质档位只控制输出尺寸。

### 2.2 导出设置持久化

文件：`entry/src/main/ets/models/AppSettingsStore.ets`

- 使用命名空间化 `PersistentStorage + AppStorage` 保存画质和格式。
- 首次读取默认为“标准 + JPEG”。
- 读取到未知或损坏值时回退默认值。
- 提供以下接口：

```typescript
AppSettingsStore.getExportSettings(): Promise<AppExportSettings>;
AppSettingsStore.setExportQuality(value: ExportQuality): Promise<void>;
AppSettingsStore.setExportFormat(value: ExportFormat): Promise<void>;
```

### 2.3 应用设置页接线

文件：`entry/src/main/ets/pages/AppSettingsPage.ets`

- 页面状态从数字索引改为 `ExportQuality` / `ExportFormat` 枚举。
- 页面进入时异步恢复已保存设置。
- 切换选项后立即写入 Store。
- 写入失败时恢复原选择并提示用户。
- 将“仅保留在页面生命周期内”的说明更新为本机持久化说明。
- 未改变现有 Mask & Seal 页面结构和视觉令牌。

### 2.4 系统选图服务基础

文件：`entry/src/main/ets/services/PhotoPickerService.ets`

- 封装 `PhotoViewPicker` 单图选择。
- 仅请求图片类型，最多选择一张，不申请大范围图库权限。
- 将空结果和取消错误码 `13900042` 归类为 `cancelled`。
- 其他错误归类为 `failed`，不打印照片 URI。
- 选中结果统一返回 `selected + imageUri`。

### 2.5 设置测试草稿

文件：`entry/src/test/AppSettingsStore.test.ets`

已覆盖默认值、独立写入、非法值回退和六种导出配置映射。由于 `List.test.ets` 由 C 独占，当前尚未把该测试套件注册到总测试列表。

## 三、尚未实现功能

### 3.1 待续编辑意图

计划文件：`entry/src/main/ets/models/PendingEditIntentStore.ets`

尚未实现：

- `set()`、`peek()`、`consume()`、`clear()`；
- 单条进程内意图保存；
- 对象副本和单次消费语义；
- 拒绝登录、返回首页、路由失败时的清理；
- `PendingEditIntent.test.ets` 测试。

依赖 C 提供 `PendingEditIntent` 类型。

### 3.2 首页主导入登录门禁

尚未修改：

- `HeroCard.ets` 仍直接调用 Picker 并直接跳转编辑页；
- `HomePage.ets` 尚未统一处理选图、认证状态和弹窗；
- 未登录时的“暂不登录 / 前往登录”流程未接入；
- 已登录用户的直接进入编辑页流程未接入。

### 3.3 登录/注册成功后的选图恢复

尚未修改：

- `LoginPage.ets` 登录成功后仍只返回上一页；
- `RegisterPage.ets` 注册成功后仍只返回上一页；
- 尚未消费待续意图并用 `replaceUrl` 恢复 `imageUri` 和初始工具；
- 尚未处理登录页、注册页匿名返回时的意图清理。

### 3.4 首页八个快捷入口

尚未修改：

- `ToolItem` 尚未增加稳定 `EditorToolKey`；
- `QuickToolsSection.ets` 尚未增加 `onToolClick`；
- 八个入口尚未映射到 `subject/filter/background/adjust/subject/sticker/text/template`；
- 尚未实现快捷入口复用选图和登录门禁的流程。

### 3.5 A 负责的集成验证

尚未完成：

- 主导入和八个快捷入口的手工流程；
- 登录、注册、取消登录、匿名返回和普通登录回归；
- 设置跨页面和应用重启恢复的真机验证；
- Task 10 中 A 负责的 Auth、首页和设置回归。

## 四、当前阻塞与等待事项

### 4.1 等待 C 冻结共享契约

当前 `entry/src/main/ets/models/EditModels.ets` 仍没有以下导出：

```typescript
export type EditorToolKey =
  'filter' | 'subject' | 'background' | 'adjust' |
  'sticker' | 'text' | 'template';

export interface EditRouteParams {
  source: EditEntrySource;
  imageUri?: string;
  workId?: string;
  initialTool?: EditorToolKey;
}

export interface PendingEditIntent {
  imageUri: string;
  initialTool: EditorToolKey;
  createdAt: number;
}
```

C 合入这些契约后，A 才能继续实现 Pending Store、首页门禁、登录恢复和快捷入口。A 不应自行在其他文件复制这些类型，也不应直接修改 `EditModels.ets`。

### 4.2 等待 C 注册测试套件

C 需要在最终集成阶段修改 `entry/src/test/List.test.ets`，注册：

- `AppSettingsStore.test.ets`；
- `PendingEditIntentStore.test.ets`；
- 其他本阶段新增测试。

在注册前，A 可以维护独立测试文件，但不能声称项目测试已覆盖这些套件。

### 4.3 现有测试基线问题

当前 Hvigor 单元测试首先报告了与本次 A 改动无关的基线错误：

- `entry/src/test/EditModels.test.ets` 多处 ArkTS 对象字面量错误；
- `entry/src/test/MockWorkStore.test.ets` 引用了当前 `WorkRecord` 未导出的 `DEFAULT_ADJUSTMENTS`。

这些问题需要由 C/B 在共享模型和作品模型整合时一并修复，否则无法得到完整测试结果。

### 4.4 构建工具环境问题

项目级 `default@BuildArkTS` 已启动到 ArkTS 阶段，但随后触发 DevEco SDK 的 source-map 内部异常：

```text
TypeError: Cannot read properties of undefined (reading 'share')
```

因此当前不能把项目级 debug 构建标记为通过。该问题需要在 Task 10 使用稳定的 DevEco/Hvigor 环境重新验证。

## 五、契约合入后的继续顺序

1. C 合入 `EditorToolKey`、`initialTool` 和 `PendingEditIntent`。
2. A 新增 `PendingEditIntentStore` 及其测试，先完成纯逻辑验证。
3. A 将 `PhotoPickerService` 接入 `HomePage`，改造 `HeroCard` 为回调组件。
4. A 接入登录/注册成功恢复和匿名返回清理。
5. A 接入 `ToolItem` 稳定键、快捷入口点击回调和八项映射。
6. C 注册 A 的测试套件，三人共同运行 Auth、设置、门禁和快捷入口回归。
7. Task 10 再进行项目级 debug 构建和真机验证；未完成的真机项目必须明确记录，不能以模拟器结果替代。

## 六、协作边界记录

- 本次未修改 `EditModels.ets`、`EditPage.ets`、`components/editor/`、作品模型和作品 Store。
- 本次未修改 `List.test.ets`。
- 本次未删除文件、未新增第三方依赖、未创建提交、未推送远程。
- 当前工作区仍保留 A 的未提交改动，后续实现应继续沿用这些文件，不覆盖其他开发者的修改。
