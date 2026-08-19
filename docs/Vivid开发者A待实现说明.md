# Vivid 开发者 A 待实现说明

> 更新时间：2026-08-19
> 对应计划：`docs/Vivid下一阶段开发需求计划书.md`
> 责任范围：Task 2、Task 3、Task 8，以及 A 负责的集成回归

## 一、当前结论

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
