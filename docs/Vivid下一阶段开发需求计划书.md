# Vivid 下一阶段三人协作：登录门禁、作品闭环与本地导出实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 由三名开发者在当前已合并的登录、编辑页和作品模块之上，分别完成入口认证、作品与导出基础设施、编辑与续编集成，最终形成登录门禁、作品/草稿持久化、续编、快捷入口和按设置导出到系统相册的完整客户端闭环。

**Architecture:** 保留现有 `Index` 三 Tab 和独立 `EditPage`，将首页导入与快捷入口统一收敛为“选图—认证门禁—编辑意图”流程；将 `EditWorkStore` 和 `MockWorkStore` 两套内存数据源统一到一个作品仓库。三人按文件所有权并行开发：A 负责入口与认证，B 负责作品与导出基础设施，C 负责编辑和作品 UI；正式保存同时更新作品仓库并导出到系统相册，草稿只保存到应用沙箱。

**Tech Stack:** HarmonyOS 6.1.1（API 24）、ArkTS、ArkUI、PhotoViewPicker、Image Kit、Media Library Kit/Core File Kit、Preferences 或等价 ArkData 本地键值存储、现有 Mask & Seal 设计系统。

**Spec:** `docs/项目结构.md`、`docs/# 蒙版调色——产品需求文档（PRD）.md`、`docs/Vivid 登录作品与调色编辑Mock闭环实施计划.md`，以及 2026-08-18 用户确认的七项下一阶段需求。

## Global Constraints

- 只实施客户端功能，不接入真实账号后端、云端作品库或云端图片处理。
- 首页导入和快捷功能只有在登录后才能进入编辑页；已登录用户不重复提示。
- 照片读取继续优先使用系统 Picker，不申请大范围图库读取权限。
- 正式保存默认写入系统相册；草稿不写系统相册，只保留应用内恢复所需数据。
- 作品列表、作品详情、编辑保存和草稿必须使用同一数据源，不保留双写逻辑。
- 导出格式支持 JPEG、PNG；默认 JPEG。导出画质支持标准、高清、超清，默认标准。
- 不新增第三方依赖，不升级 SDK，不更换现有构建系统和状态管理方式。
- 界面沿用 Mask & Seal：宣纸背景、朱砂主色、衬线标题、等宽状态标签和“落印保存 / 暂存草稿”文案。
- 不删除现有文件；`EditWorkStore.ets` 本阶段仅停止引用并标记为兼容遗留，后续如需删除须单独确认和单独提交。
- 所有 Git 写操作前重新检查当前分支、远程和工作区；本计划书不授权提交、推送或合并。

---

## 一、最新代码基线

当前分支为 `merge/all-three`，读取时工作区无已显示的修改。近期合并已经具备以下基础：

| 模块 | 当前已有 | 下一阶段缺口 |
|---|---|---|
| 登录 | `MockAuthStore`、登录/注册、`AuthUiState` 已形成 Mock 会话 | 登录成功只能返回上一页，不能恢复首页选图意图 |
| 首页导入 | `HeroCard` 已选取单张照片并直接进入 `EditPage` | 缺少登录判断、提示弹窗和登录后续接 |
| 编辑页 | `EditPage` 已注册；曝光、亮度、对比度、饱和度、重置、对比已存在 | 保存写入 `EditWorkStore`；续编未恢复作品；退出只能放弃，不能存草稿 |
| 作品 | `MockWorkStore` 已管理种子作品，作品页读取该 Store | 编辑页保存不写该 Store；详情仍通过 `findWork()` 读取静态种子 |
| 快捷功能 | 首页已有 8 个快捷入口；编辑页已有 7 个工具键 | 快捷入口无点击回调；编辑路由不支持初始工具 |
| 应用设置 | 画质和格式选项已展示 | 状态仅在页面生命周期内；导出流程不读取这些设置 |
| 本地导出 | 已有 PhotoViewPicker 输入能力 | 尚无实际渲染、编码、应用沙箱缓存和系统相册写入服务 |

当前最关键的结构问题是：

```text
EditPage.save()
  └─ EditWorkStore（临时内存数据）

WorksPage
  └─ MockWorkStore（另一份内存数据）

WorkDetailPage
  └─ MockWorks.findWork（每次重建静态种子）
```

下一阶段必须先统一数据源，再实现草稿、续编和相册导出；否则会继续出现“保存成功但作品页看不到”的假闭环。

## 二、目标用户流程

### 2.1 首页导入与登录门禁

```text
点击“导入照片”
  → 系统 Picker 选择照片
  → 已登录：直接进入 EditPage
  → 未登录：弹出“登录后方可呈报卷宗”
      ├─ 暂不登录：清除本次选图意图，停留首页
      └─ 前往登录：进入 LoginPage
            ├─ 登录/注册成功：恢复选中的照片并进入 EditPage
            └─ 返回且未登录：清除待续意图并回到首页
```

登录提示只针对未登录用户。登录过程中选中的 URI 只保存在进程内 `PendingEditIntentStore`，不写日志、不持久化、不通过多层路由参数反复传递。

### 2.2 正式保存

```text
EditPage 点击“落印保存”
  → 防重复提交
  → 读取 AppSettingsStore
  → 从源图 + AdjustParams 生成导出 PixelMap
  → 按格式/画质编码到应用缓存文件
  → 通过系统允许的相册保存流程写入图库
  → 成功后 create/update 统一作品仓库，状态 Sealed
  → bump workRevision
  → 返回并在作品页看到最新作品
```

相册导出失败时留在编辑页，显示失败原因和重试入口，不将作品误标为“已封缄”。用户可改选“暂存草稿”。

### 2.3 未保存退出

新导入照片进入编辑页后即属于“尚未保存”，即使尚未拖动滑块也要拦截退出；续编作品仅在参数、工具状态或内容发生变化后拦截。

```text
返回 / 系统返回
  → 无未保存内容：直接返回
  → 有未保存内容：弹窗
      ├─ 暂存草稿：写应用沙箱 + 作品仓库，状态 Draft，然后返回
      ├─ 不保存：丢弃当前会话，然后返回
      └─ 关闭弹窗：继续编辑
```

草稿保存不写系统相册；作品页“草稿”筛选必须可见，并可再次进入编辑页。

### 2.4 作品续编

- 草稿卡片点击后直接进入 `EditPage(source=work, workId=...)`。
- 已封缄作品保留现有“作品详情 → 启封续编”路径。
- 编辑页从统一仓库恢复源图引用、调色参数、当前工具和作品状态。
- 续编保存更新原作品 ID，不新增重复作品卡片；再次正式保存会生成新的相册导出结果，但应用作品记录仍为同一条。

### 2.5 首页快捷功能

快捷入口复用导入和登录门禁，不允许绕过登录：

```text
点击快捷功能
  → 选择照片
  → 认证门禁
  → EditPage(initialTool=映射工具)
```

映射冻结如下：

| 首页入口 | EditPage `initialTool` | 本阶段结果 |
|---|---|---|
| AI智能抠图 | `subject` | 进入主体占位面板 |
| 滤镜 | `filter` | 进入滤镜占位面板 |
| 背景 | `background` | 进入背景占位面板 |
| 调节 | `adjust` | 进入已有四项调节面板 |
| 主体 | `subject` | 进入主体占位面板 |
| 贴纸 | `sticker` | 进入贴纸占位面板 |
| 文字 | `text` | 进入文字占位面板 |
| 模板 | `template` | 进入模板占位面板 |

本阶段不实现七个占位工具的业务，仅保证正确路由、正确选中和稳定返回。

## 三、三人职责与边界

### 开发者 A：登录门禁、首页入口与应用设置

**负责目标：** 把首页主导入和 8 个快捷功能统一接入照片选择与登录门禁；登录/注册成功后能够恢复待处理照片；导出设置可跨页面持久化。

**负责 Task：** Task 2、Task 3、Task 8。

**独占文件：**

- 新建：`entry/src/main/ets/models/PendingEditIntentStore.ets`
- 新建：`entry/src/main/ets/models/AppSettingsModels.ets`
- 新建：`entry/src/main/ets/models/AppSettingsStore.ets`
- 新建：`entry/src/main/ets/services/PhotoPickerService.ets`
- 修改：`entry/src/main/ets/components/home/HeroCard.ets`
- 修改：`entry/src/main/ets/components/home/HomePage.ets`
- 修改：`entry/src/main/ets/components/home/HomeModels.ets`
- 修改：`entry/src/main/ets/components/home/QuickToolsSection.ets`
- 修改：`entry/src/main/ets/pages/LoginPage.ets`
- 修改：`entry/src/main/ets/pages/RegisterPage.ets`
- 修改：`entry/src/main/ets/pages/AppSettingsPage.ets`
- 测试：`entry/src/test/PendingEditIntentStore.test.ets`
- 测试：`entry/src/test/AppSettingsStore.test.ets`

**只读依赖：**

- `MockAuthStore.getSession()`：判断当前是否登录。
- `AuthUiState.bumpRevision()`：沿用现有登录成功通知。
- `EditorToolKey`、`EditRouteParams`：由开发者 C 在接口冻结阶段提供。

**不得修改：**

- `WorkRecord.ets`、`MockWorkStore.ets`、`WorkFileService.ets`；
- `EditPage.ets` 和 `components/editor/`；
- 图片编码、系统相册写入和作品 upsert 逻辑。

**交付接口：**

```typescript
PendingEditIntentStore.set(intent: PendingEditIntent): void;
PendingEditIntentStore.peek(): PendingEditIntent | undefined;
PendingEditIntentStore.consume(): PendingEditIntent | undefined;
PendingEditIntentStore.clear(): void;

AppSettingsStore.getExportSettings(): Promise<AppExportSettings>;
AppSettingsStore.setExportQuality(value: ExportQuality): Promise<void>;
AppSettingsStore.setExportFormat(value: ExportFormat): Promise<void>;
```

**验收标准：**

- [ ] 未登录用户选图后看到“暂不登录 / 前往登录”弹窗。
- [ ] 暂不登录时停留首页并清除待续意图。
- [ ] 登录或注册成功后自动恢复所选照片和快捷功能目标。
- [ ] 普通登录不会错误恢复旧照片。
- [ ] 8 个快捷入口均能传递稳定 `EditorToolKey`。
- [ ] 导出设置首次为“标准 + JPEG”，重新进入设置页仍保持选择。
- [ ] 不在日志中输出完整照片 URI、手机号或账户凭证。

### 开发者 B：作品仓库、文件落地与相册导出基础设施

**负责目标：** 统一三处作品数据源，保存可持续访问的源图/预览图，完成 API 24 编码与系统相册导出技术链路，并向编辑页提供单一保存服务。

**负责 Task：** Task 1、Task 4、Task 5。

**独占文件：**

- 新建：`docs/技术验证-API24本地图片导出.md`
- 新建：`entry/src/main/ets/models/WorkUiState.ets`
- 新建：`entry/src/main/ets/services/WorkFileService.ets`
- 新建：`entry/src/main/ets/services/ImageRenderService.ets`
- 新建：`entry/src/main/ets/services/PhotoExportService.ets`
- 新建：`entry/src/main/ets/services/WorkSaveService.ets`
- 修改：`entry/src/main/ets/models/WorkRecord.ets`
- 修改：`entry/src/main/ets/models/MockWorkStore.ets`
- 修改：`entry/src/main/ets/models/EditWorkStore.ets`（仅标记兼容遗留并停止新调用，不删除）
- 测试：`entry/src/test/MockWorkStore.test.ets`
- 测试：`entry/src/test/WorkSaveModels.test.ets`

**只读依赖：**

- `AdjustParams`、`EditorToolKey`：由开发者 C 负责定义，B 只存储快照。
- `AppSettingsStore.getExportSettings()`、`toExportProfile()`：由开发者 A 提供。

**不得修改：**

- 登录、注册、首页和快捷功能页面；
- `EditPage.ets`、`WorksPage.ets`、`WorkDetailPage.ets` 的 UI；
- `AppSettingsPage.ets` 的展示与交互。

**交付接口：**

```typescript
mockWorkStore.init(): Promise<void>;
mockWorkStore.list(): WorkRecord[];
mockWorkStore.findById(id: string): WorkRecord | null;
mockWorkStore.upsert(record: WorkRecord): Promise<WorkRecord>;

WorkSaveService.saveDraft(request: WorkSaveRequest): Promise<WorkSaveResult>;
WorkSaveService.saveSealed(request: WorkSaveRequest): Promise<WorkSaveResult>;
```

**验收标准：**

- [ ] `EditWorkStore`、`MockWorkStore`、`MockWorks.findWork()` 不再形成三份运行时作品数据。
- [ ] 新建、草稿转正式、续编更新均保持正确 ID 和时间排序。
- [ ] 应用重启后能够恢复真实作品元数据和沙箱源图。
- [ ] 草稿不写系统相册，正式保存才触发图库导出。
- [ ] JPEG、PNG 和三档画质按冻结映射编码。
- [ ] 导出失败不将作品标记为已封缄。
- [ ] 缓存清理只处理单个明确文件，不执行递归或批量删除。

### 开发者 C：编辑页、草稿/正式保存、作品页续编与集成

**负责目标：** 将统一作品仓库和保存服务接入编辑页，完成未保存退出弹窗、草稿恢复、作品页刷新和续编；继续完善编辑体验并负责最终集成清单。

**负责 Task：** Task 6、Task 7、Task 9；Task 10 由三人共同执行，C 负责汇总。

**独占文件：**

- 修改：`entry/src/main/ets/models/EditModels.ets`
- 修改：`entry/src/main/ets/pages/EditPage.ets`
- 修改：`entry/src/main/ets/components/editor/PreviewArea.ets`
- 修改：`entry/src/main/ets/components/editor/AdjustPanel.ets`
- 修改：`entry/src/main/ets/components/editor/EditorToolBar.ets`
- 修改：`entry/src/main/ets/pages/WorksPage.ets`
- 修改：`entry/src/main/ets/pages/WorkDetailPage.ets`
- 修改：`entry/src/main/ets/components/works/WorkCard.ets`
- 修改：`entry/src/main/ets/components/common/PaperFrame.ets`
- 修改：`entry/src/test/EditModels.test.ets`
- 修改：`entry/src/test/List.test.ets`（仅最终集成测试注册）

**只读依赖：**

- `PendingEditIntentStore`、`AppSettingsStore`：开发者 A 提供。
- `mockWorkStore`、`WorkSaveService`、`WorkUiState`：开发者 B 提供。

**不得修改：**

- `MockAuthStore.ets`、登录/注册页面和首页入口组件；
- `MockWorkStore.ets`、导出服务的内部实现；
- 应用设置的持久化规则。

**交付接口：**

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
```

**验收标准：**

- [ ] 新导入作品保存后立即出现在作品页。
- [ ] 新导入图片即使未调参数，退出时也提示暂存草稿或不保存。
- [ ] 草稿在作品页可见并可直接继续编辑。
- [ ] 已保存作品可以从详情页启封续编，恢复源图和参数。
- [ ] 续编保存更新原作品，不新增重复卡片。
- [ ] 快捷入口进入时选中正确工具；占位工具不丢失当前会话。
- [ ] 预览、保存和导出使用一致的参数方向。
- [ ] C 汇总三人验证结果，但不得把未执行的真机验证标记为通过。

### 三人共享规则

| 共享对象 | 唯一修改负责人 | 其他人使用方式 |
|---|---|---|
| `EditModels.ets` | C | A/B 只导入冻结类型 |
| `WorkRecord.ets` | B | C 只读取和构造记录 |
| `HomePage.ets` | A | B/C 不修改首页路由 |
| `MockWorkStore.ets` | B | C 只调用公开方法 |
| `EditPage.ets` | C | A/B 不修改页面 |
| `AppSettingsStore.ets` | A | B 只读取导出设置 |
| `List.test.ets` | C（最终集成阶段） | A/B 先提交独立测试文件 |

三人开始实现前先确认接口签名；接口冻结后如需变更，由提出者先说明调用方影响，再由唯一负责人修改。不得通过复制模型、另建临时 Store 或在页面内维护第二份作品数组绕过协作边界。

## 四、冻结数据契约

### 3.1 编辑路由

修改 `entry/src/main/ets/models/EditModels.ets`，在现有契约上增加初始工具：

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

`parseEditRouteParams()` 对非法 `initialTool` 回退到 `adjust`。从作品续编时，作品记录内的 `lastTool` 优先于路由默认值。

### 3.2 作品记录

扩展 `WorkRecord`，保留现有字段并增加：

```typescript
sourceImageUri: string;       // 应用可持续访问的沙箱源图 URI
previewImageUri: string;      // 作品卡片预览 URI
exportedAssetUri: string;     // 最近一次正式导出的媒体库 URI；草稿为空
adjustments: AdjustParams;
lastTool: EditorToolKey;
status: WorkStatus;           // Draft / Sealed / Damaged
createdAt: number;
updatedAt: number;
```

内置 Resource 种子作品继续使用 `previewImage`；真实导入作品优先使用 `previewImageUri`。展示组件统一接受 `ResourceStr`，页面不直接判断 Store 来源。

### 3.3 导出设置

新增 `entry/src/main/ets/models/AppSettingsModels.ets`：

```typescript
export enum ExportQuality {
  Standard = 'standard',
  High = 'high',
  Ultra = 'ultra'
}

export enum ExportFormat {
  JPEG = 'jpeg',
  PNG = 'png'
}

export interface AppExportSettings {
  quality: ExportQuality;
  format: ExportFormat;
}

export interface ExportProfile {
  mimeType: 'image/jpeg' | 'image/png';
  extension: '.jpg' | '.png';
  maxLongEdge: number;
  encoderQuality: number;
}
```

冻结映射：

| 设置 | 最大长边 | JPEG 编码质量 | PNG 行为 |
|---|---:|---:|---|
| 标准 | 1920 px | 85 | 长边 1920，保持无损编码 |
| 高清 | 2560 px | 92 | 长边 2560，保持无损编码 |
| 超清 | 原始尺寸 | 98 | 原始尺寸，保持无损编码 |

PNG 不把“画质”解释为有损压缩质量，画质档位只控制输出尺寸。若 API 24 的编码器对 PNG 质量字段有特殊限制，以技术验证结果固定实现，但用户可见规则不变。

### 3.4 保存结果

```typescript
export interface WorkSaveRequest {
  workId?: string;
  sourceImageUri: string;
  adjustments: AdjustParams;
  lastTool: EditorToolKey;
  mode: 'draft' | 'sealed';
}

export interface WorkSaveResult {
  success: boolean;
  work?: WorkRecord;
  errorCode?: 'SOURCE_UNAVAILABLE' | 'RENDER_FAILED' |
    'ENCODE_FAILED' | 'GALLERY_SAVE_FAILED' | 'WORK_WRITE_FAILED';
}
```

页面只根据 `WorkSaveResult` 更新 UI，不直接拼装多个 Store 或文件服务调用。

## 五、目标文件结构

### 新建文件

| 文件 | 单一职责 |
|---|---|
| `entry/src/main/ets/models/PendingEditIntentStore.ets` | 保存/消费登录后的待续编辑意图 |
| `entry/src/main/ets/models/AppSettingsModels.ets` | 导出格式、画质及映射类型 |
| `entry/src/main/ets/models/AppSettingsStore.ets` | 持久化读取导出设置 |
| `entry/src/main/ets/models/WorkUiState.ets` | 维护 `workRevision`，通知作品页刷新 |
| `entry/src/main/ets/services/PhotoPickerService.ets` | 封装单图选择，供主卡片和快捷入口共用 |
| `entry/src/main/ets/services/WorkFileService.ets` | 将选中源图/预览图保存在应用沙箱并返回稳定 URI |
| `entry/src/main/ets/services/ImageRenderService.ets` | 根据源图和 `AdjustParams` 生成可编码 PixelMap |
| `entry/src/main/ets/services/PhotoExportService.ets` | 按 `ExportProfile` 编码并写入系统相册 |
| `entry/src/main/ets/services/WorkSaveService.ets` | 编排草稿保存、正式导出和作品仓库更新 |
| `entry/src/test/PendingEditIntentStore.test.ets` | 待续意图一次性消费测试 |
| `entry/src/test/AppSettingsStore.test.ets` | 默认值、持久化和映射测试 |
| `entry/src/test/WorkSaveModels.test.ets` | 保存模式和结果映射纯逻辑测试 |

### 修改文件

| 文件 | 修改范围 |
|---|---|
| `entry/src/main/ets/models/EditModels.ets` | 增加 `EditorToolKey`、`initialTool`、草稿构造函数 |
| `entry/src/main/ets/models/WorkRecord.ets` | 增加沙箱、预览、导出和最后工具字段 |
| `entry/src/main/ets/models/MockWorkStore.ets` | 成为唯一作品仓库；增加持久化、upsert 和异步初始化 |
| `entry/src/main/ets/models/EditWorkStore.ets` | 标记兼容遗留并停止所有新调用，不删除 |
| `entry/src/main/ets/components/home/HeroCard.ets` | 只上报点击/选图结果，不再直接跳转 |
| `entry/src/main/ets/components/home/QuickToolsSection.ets` | 增加工具点击回调 |
| `entry/src/main/ets/components/home/HomeModels.ets` | `ToolItem` 增加稳定工具键 |
| `entry/src/main/ets/components/home/HomePage.ets` | 统一选图、登录弹窗、待续意图和编辑路由 |
| `entry/src/main/ets/pages/LoginPage.ets` | 登录成功后消费待续意图并替换到编辑页 |
| `entry/src/main/ets/pages/RegisterPage.ets` | 注册成功后同样恢复待续意图 |
| `entry/src/main/ets/pages/EditPage.ets` | 恢复作品、草稿退出、异步保存、初始工具和错误态 |
| `entry/src/main/ets/components/editor/EditorToolBar.ets` | 使用冻结的 `EditorToolKey` 类型 |
| `entry/src/main/ets/components/editor/PreviewArea.ets` | 支持恢复图片引用和真实渲染结果 |
| `entry/src/main/ets/pages/WorksPage.ets` | 监听 `workRevision`、展示草稿/已保存作品 |
| `entry/src/main/ets/pages/WorkDetailPage.ets` | 改用统一仓库并恢复续编入口 |
| `entry/src/main/ets/components/works/WorkCard.ets` | 支持 URI 预览和草稿点击策略 |
| `entry/src/main/ets/components/common/PaperFrame.ets` | 图片源类型从 Resource 扩展为 `ResourceStr` |
| `entry/src/main/ets/pages/AppSettingsPage.ets` | 绑定并保存 `AppSettingsStore` |
| `entry/src/test/EditModels.test.ets` | 增加初始工具、草稿和恢复测试 |
| `entry/src/test/MockWorkStore.test.ets` | 增加持久化、upsert、状态和排序测试 |
| `entry/src/test/List.test.ets` | 注册新增测试套件 |

## 六、实施任务

### Task 1：API 24 本地导出技术验证

**负责人：开发者 B**

**Files:**

- Create: `docs/技术验证-API24本地图片导出.md`
- Inspect only: 本机 HarmonyOS 6.1.1（API 24）SDK 的 Image Kit、Media Library Kit 和安全保存控件声明

**Produces:** 确认后的图库保存入口、编码方法、临时文件生命周期、错误码和真机验证记录。

- [ ] 验证 `ImagePacker` 能否分别按 `image/jpeg`、`image/png` 将 PixelMap 编码到应用缓存文件。
- [ ] 验证 JPEG `quality` 对文件大小有效；验证 PNG 的质量字段行为，并固定为无损输出。
- [ ] 验证 API 24 推荐的图库写入方式：优先使用显式用户点击触发的安全保存控件或等价系统授权流程，不申请受限图库写权限。
- [ ] 验证保存后返回的媒体 URI 是否可用于成功提示和 `WorkRecord.exportedAssetUri`。
- [ ] 记录用户取消、空间不足、文件不存在、编码失败和图库写入失败的错误映射。
- [ ] 在真实设备完成一次 JPEG 和一次 PNG 导出；没有设备时把该任务标记为“设备验证未完成”，不得进入正式导出验收。

### Task 2：持久化导出设置

**负责人：开发者 A**

**Files:**

- Create: `entry/src/main/ets/models/AppSettingsModels.ets`
- Create: `entry/src/main/ets/models/AppSettingsStore.ets`
- Modify: `entry/src/main/ets/pages/AppSettingsPage.ets`
- Test: `entry/src/test/AppSettingsStore.test.ets`

**Produces:** `getExportSettings()`、`setExportQuality()`、`setExportFormat()`、`toExportProfile()`。

- [ ] 先编写默认值测试：首次读取必须是“标准 + JPEG”。
- [ ] 编写画质/格式写入后重新读取的测试。
- [ ] 编写六种设置组合到 `ExportProfile` 的映射测试。
- [ ] 实现 Store，设置使用 Preferences 或项目已验证的等价本地存储，不依赖页面实例。
- [ ] 将 `AppSettingsPage` 的两个数字状态替换为枚举绑定；切换后立即写 Store，重新进入页面仍保持选择。
- [ ] 单独运行 `AppSettingsStore.test.ets`，确认默认值、持久化和映射全部通过。

### Task 3：统一照片选择与登录后待续意图

**负责人：开发者 A**

**Files:**

- Create: `entry/src/main/ets/services/PhotoPickerService.ets`
- Create: `entry/src/main/ets/models/PendingEditIntentStore.ets`
- Modify: `entry/src/main/ets/models/EditModels.ets`
- Modify: `entry/src/main/ets/components/home/HeroCard.ets`
- Modify: `entry/src/main/ets/components/home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/LoginPage.ets`
- Modify: `entry/src/main/ets/pages/RegisterPage.ets`
- Test: `entry/src/test/PendingEditIntentStore.test.ets`

**Consumes:** `MockAuthStore.getSession()`、`AuthUiState.bumpRevision()`。

**Produces:** `PendingEditIntentStore.set()`、`peek()`、`consume()`、`clear()`。

- [ ] 编写待续意图“设置—读取—只消费一次—清除”的纯逻辑测试。
- [ ] 将 PhotoViewPicker 从 `HeroCard` 抽到 `PhotoPickerService`，空结果与用户取消返回明确结果，不抛到页面。
- [ ] `HeroCard` 改为触发 `HomePage` 的导入动作，不再直接 `pushUrl(EditPage)`。
- [ ] `HomePage` 在选图成功后检查 `MockAuthStore.getSession().status`。
- [ ] 匿名状态显示双操作弹窗：“暂不登录”清除意图并留在首页；“前往登录”保存意图并进入 `LoginPage`。
- [ ] 已登录状态直接进入编辑页，不显示弹窗。
- [ ] 登录或注册成功时优先 `consume()` 待续意图；存在意图则用 `replaceUrl` 打开 `EditPage`，不存在则保持当前返回逻辑。
- [ ] 登录页返回且仍匿名时清除意图，避免下次普通登录错误恢复旧照片。

### Task 4：作品仓库单一化与本地恢复数据

**负责人：开发者 B**

**Files:**

- Create: `entry/src/main/ets/models/WorkUiState.ets`
- Create: `entry/src/main/ets/services/WorkFileService.ets`
- Modify: `entry/src/main/ets/models/WorkRecord.ets`
- Modify: `entry/src/main/ets/models/MockWorkStore.ets`
- Modify: `entry/src/main/ets/models/EditWorkStore.ets`
- Test: `entry/src/test/MockWorkStore.test.ets`

**Produces:** `init()`、`list()`、`findById()`、`create()`、`update()`、`upsert()` 和 `WorkUiState.bumpRevision()`。

- [ ] 扩展测试：新建草稿、草稿转已封缄、续编更新不换 ID、更新时间排序、序列化后恢复。
- [ ] `WorkRecord` 增加源图沙箱 URI、预览 URI、导出 URI、最后工具字段。
- [ ] `WorkFileService` 将 Picker URI 复制到应用 `filesDir/works/<workId>/source.<ext>`；预览/导出临时文件放入明确的单作品目录。
- [ ] `MockWorkStore` 首次初始化加载种子和持久化记录，后续只维护一份内存缓存并写回元数据。
- [ ] `upsert()` 根据 ID 决定 create/update，且每次成功后由调用页面 bump `workRevision`。
- [ ] 将 `EditWorkStore` 标记为兼容遗留；本阶段不删除，后续任务不得再导入它。
- [ ] 验证应用重启后至少能恢复真实保存作品的元数据与沙箱源图；损坏文件标记 `Damaged`，不崩溃。

### Task 5：图片渲染与相册导出服务

**负责人：开发者 B**

**Files:**

- Create: `entry/src/main/ets/services/ImageRenderService.ets`
- Create: `entry/src/main/ets/services/PhotoExportService.ets`
- Create: `entry/src/main/ets/services/WorkSaveService.ets`
- Test: `entry/src/test/WorkSaveModels.test.ets`

**Consumes:** `AppSettingsStore.getExportSettings()`、`mockWorkStore.upsert()`、`WorkFileService`。

**Produces:** `saveDraft(request)`、`saveSealed(request)`，返回 `WorkSaveResult`。

- [ ] 编写保存模式测试：draft 不产生相册导出请求，sealed 必须产生导出请求。
- [ ] 编写新建与续编测试：无 `workId` 创建，有 `workId` 更新原记录。
- [ ] `ImageRenderService` 从源图重新计算四项参数，不累积修改源图；导出尺寸按 `ExportProfile.maxLongEdge` 控制。
- [ ] `PhotoExportService` 使用 Task 1 确认的 API 24 方案编码 JPEG/PNG，并从明确的用户保存动作写入图库。
- [ ] `WorkSaveService.saveDraft()` 只保证沙箱源图、预览图、参数和 Draft 元数据落地。
- [ ] `WorkSaveService.saveSealed()` 完成渲染、编码、图库写入后再把记录标为 Sealed；失败时不伪造成功状态。
- [ ] 清理单次导出产生的缓存文件时一次只处理一个明确文件路径；不使用递归删除。
- [ ] 对重复点击使用单次保存锁，保证同一编辑会话不会生成重复相册文件。

### Task 6：编辑页保存、草稿与续编恢复

**负责人：开发者 C**

**Files:**

- Modify: `entry/src/main/ets/pages/EditPage.ets`
- Modify: `entry/src/main/ets/models/EditModels.ets`
- Modify: `entry/src/main/ets/components/editor/EditorToolBar.ets`
- Modify: `entry/src/main/ets/components/editor/PreviewArea.ets`
- Test: `entry/src/test/EditModels.test.ets`

**Consumes:** `mockWorkStore.findById()`、`WorkSaveService`、`WorkUiState`。

- [ ] 增加路由解析测试：`initialTool` 合法时采用，非法时回退 `adjust`。
- [ ] 增加会话状态测试：新导入进入即未保存；续编未修改不提示；续编修改后提示。
- [ ] `aboutToAppear()` 在 `source=work` 时从统一仓库恢复图片、参数、最后工具和状态，移除“续编恢复待接入”提示。
- [ ] 保存按钮改为异步状态：保存中禁用重复点击并显示进度，成功后 bump `workRevision` 再返回。
- [ ] 返回弹窗固定为“暂存草稿 / 不保存”，关闭弹窗继续编辑；系统返回键复用同一逻辑。
- [ ] “暂存草稿”调用 `saveDraft()`；成功后返回，失败时留在编辑页并显示可重试错误。
- [ ] “落印保存”调用 `saveSealed()`；相册导出成功后显示“已保存到相册”。
- [ ] 退出不保存时释放当前预览 PixelMap 和临时会话资源，不删除已有作品源文件。

### Task 7：作品页可见、详情统一与继续编辑

**负责人：开发者 C**

**Files:**

- Modify: `entry/src/main/ets/pages/WorksPage.ets`
- Modify: `entry/src/main/ets/pages/WorkDetailPage.ets`
- Modify: `entry/src/main/ets/components/works/WorkCard.ets`
- Modify: `entry/src/main/ets/components/common/PaperFrame.ets`

**Consumes:** `mockWorkStore`、`WorkUiState.workRevision`。

- [ ] 作品页监听 `workRevision`，每次变更重新读取 `mockWorkStore.list()`；切回作品 Tab 无需重启页面即可看到新作品。
- [ ] `WorkCard` 优先显示 `previewImageUri`，再回退内置 Resource；图片损坏显示 `Damaged` 状态。
- [ ] 草稿卡片点击直接进入 `EditPage(source=work, workId)`。
- [ ] 已封缄卡片保持进入详情页，详情页改用 `mockWorkStore.findById()`，不再调用 `MockWorks.findWork()`。
- [ ] “启封续编”传入同一 `workId`，编辑页恢复参数并更新原作品。
- [ ] 草稿筛选、全部筛选、时间排序和作品数量同时覆盖新建、更新和草稿场景。

### Task 8：首页快捷功能路由

**负责人：开发者 A**

**Files:**

- Modify: `entry/src/main/ets/components/home/HomeModels.ets`
- Modify: `entry/src/main/ets/components/home/QuickToolsSection.ets`
- Modify: `entry/src/main/ets/components/home/HomePage.ets`
- Modify: `entry/src/main/ets/models/EditModels.ets`

**Consumes:** Task 3 的统一选图/登录门禁。

- [ ] 给每个 `ToolItem` 增加稳定 `EditorToolKey`，禁止用显示文案作为路由键。
- [ ] `QuickToolsSection` 增加 `onToolClick(key)`，每个网格项可点击并有按压反馈。
- [ ] 点击后复用 PhotoPickerService；取消选图停留首页。
- [ ] 未登录时复用相同登录弹窗和待续意图；登录后恢复对应 `initialTool`。
- [ ] 已登录时直接进入编辑页并选中正确工具；占位面板显示“功能待接入”，不出现空白页。
- [ ] 手工覆盖 8 个入口的映射，不要求实现占位工具业务。

### Task 9：编辑页下一批功能完善

**负责人：开发者 C**

**Files:**

- Modify: `entry/src/main/ets/pages/EditPage.ets`
- Modify: `entry/src/main/ets/components/editor/PreviewArea.ets`
- Modify: `entry/src/main/ets/components/editor/AdjustPanel.ets`
- Modify: `entry/src/main/ets/components/editor/EditorToolBar.ets`

**Scope:** 本任务只完善现有编辑能力和占位体验，不实现 AI 分割或完整贴纸/文字系统。

- [ ] 统一滑块值、预览值和最终导出值，确保保存结果与预览方向一致。
- [ ] 增加加载源图、渲染中、保存中、导出成功、导出失败五种明确状态。
- [ ] 原图对比在 Touch Cancel、页面后台和保存开始时自动复位。
- [ ] 重置当前项与全部重置后正确更新未保存状态。
- [ ] 占位工具保留当前图片和编辑会话，切回“调节”不丢参数。
- [ ] 检查小屏、长图、横图和安全区，底部工具栏不遮挡操作面板。

### Task 10：集成验证与交付检查

**负责人：三人共同执行；开发者 C 负责集成清单和结果汇总**

**Files:**

- Modify: `entry/src/test/List.test.ets`
- Review: 本计划涉及的全部文件

- [ ] 运行 Auth 相关测试，确保登录、注册和资料安全流程没有回归。
- [ ] 运行 `PendingEditIntentStore`、`AppSettingsStore`、`EditModels`、`MockWorkStore`、`WorkSaveModels` 相关测试。
- [ ] 运行 `git diff --check`，检查路由引用、遗留 `EditWorkStore` 导入和 `findWork()` 页面调用。
- [ ] 由于本阶段修改数据模型、本地文件、系统相册和多个页面，执行一次项目级 debug 构建；不生成或交付签名 HAP。
- [ ] 在真机验证选图、登录门禁、JPEG/PNG 导出、三档画质、图库可见性和 URI 重启恢复。
- [ ] 分别验证新建保存、续编保存、草稿退出、草稿恢复、导出失败重试和重复点击保存。
- [ ] 记录未验证设备、图片格式和极端尺寸，不以模拟器结果替代真机相册结论。

## 七、实施顺序与并行边界

```text
Task 1 API 验证（B）
   ├─ Task 2 设置持久化（A）
   ├─ Task 3 登录门禁与待续意图（A）
   └─ Task 4 统一作品仓库（B）
           ↓
       Task 5 保存/导出服务（B）
           ↓
       Task 6 编辑页接入（C）
        ├─ Task 7 作品与续编（C）
        ├─ Task 8 快捷入口（A）
        └─ Task 9 编辑体验（C）
           ↓
       Task 10 集成验证（A/B/C，C 汇总）
```

可并行任务：Task 2、3、4 在契约冻结后可分别开发。Task 5 必须等待 Task 1、2、4；Task 6 必须等待 Task 4、5；Task 7—9 可在 Task 6 主接口稳定后并行。

### 三人阶段安排

| 阶段 | 开发者 A | 开发者 B | 开发者 C | 阶段出口 |
|---|---|---|---|---|
| 第 0 阶段：接口冻结 | 确认待续意图与设置接口 | 确认作品与保存接口 | 定义 `EditorToolKey`、路由和编辑会话 | 三人签字确认接口和文件所有权 |
| 第 1 阶段：独立开发 | Task 2、Task 3 | Task 1、Task 4 | 先补 Task 6 所需纯逻辑测试与页面适配准备 | A/B 的公共接口测试通过，C 不提前复制桩实现 |
| 第 2 阶段：核心串联 | Task 8 首页快捷入口 | Task 5 保存与导出服务 | Task 6 编辑页保存/草稿/恢复 | 选图—登录—编辑—草稿/保存主路径可运行 |
| 第 3 阶段：作品闭环 | 修复入口联调问题 | 修复仓库/导出联调问题 | Task 7、Task 9 | 作品可见、续编和编辑体验完成 |
| 第 4 阶段：验证 | Auth、首页与设置回归 | 文件、编码和相册真机验证 | 页面、路由、构建与结果汇总 | Task 10 验收记录完整 |

为减少冲突，文件负责人固定如下：

| 负责人 | 责任域 | 独占文件 |
|---|---|---|
| A | 登录门禁、设置和首页路由 | `PendingEditIntentStore.ets`、`AppSettingsStore.ets`、`LoginPage.ets`、`RegisterPage.ets`、`HomePage.ets`、`HeroCard.ets`、`QuickToolsSection.ets` |
| B | 作品数据、文件与导出基础设施 | `WorkRecord.ets`、`MockWorkStore.ets`、`WorkFileService.ets`、`ImageRenderService.ets`、`PhotoExportService.ets`、`WorkSaveService.ets` |
| C | 编辑页、作品 UI 与集成 | `EditModels.ets`、`EditPage.ets`、editor 组件、`WorksPage.ets`、`WorkDetailPage.ets`、`WorkCard.ets` |

`EditModels.ets` 是共享冲突热点，只由 C 在接口冻结阶段和编辑页整合阶段修改；A/B 发现契约缺口时先提出变更，不直接编辑该文件。

## 八、验收矩阵

| 需求 | 验收结果 |
|---|---|
| 1. 首页导入登录提示 | 匿名用户选择照片后出现双操作弹窗；不登录留在首页；登录成功自动恢复照片进入编辑页 |
| 2. 保存后作品页可见 | 正式保存后无需重启，在作品页看到新作品且状态为已封缄 |
| 3. 作品继续编辑 | 草稿可直接续编；已封缄作品从详情启封续编；参数和图片正确恢复 |
| 4. 未保存退出处理 | 弹窗可暂存草稿或不保存；草稿在作品页可见并能再次编辑 |
| 5. 编辑页更新 | 状态反馈、真实保存链路、参数一致性、占位工具会话保持完成 |
| 6. 首页快捷入口 | 8 个入口都能选图、经过门禁并打开正确编辑工具或占位面板 |
| 7. 本地相册与设置 | 默认标准 JPEG；六种格式/画质组合按规则导出并在系统相册可见 |

## 九、异常与回滚策略

| 异常 | 页面行为 | 数据行为 |
|---|---|---|
| 用户取消选图 | 留在首页 | 不创建意图/作品 |
| 用户拒绝登录 | 留在首页 | 清除待续意图 |
| 登录页返回 | 回首页 | 匿名状态清除待续意图 |
| 源图 URI 失效 | 编辑页显示“源图不可用” | 现有作品标记 Damaged，不覆盖原记录 |
| 草稿写入失败 | 留在编辑页，可重试或不保存 | 不新增不完整草稿 |
| 相册导出失败 | 留在编辑页，提示重试/存草稿 | 不标记 Sealed |
| 作品元数据写入失败但相册已成功 | 明确提示“已导出，但作品记录失败” | 不伪造作品记录；提供重新建立记录入口 |
| 重复点击保存 | 第一次处理中，其余点击忽略 | 只生成一个导出文件 |
| 应用进入后台 | 保留编辑会话，停止对比态 | 不自动导出、不自动丢弃 |

每个任务使用小提交，出现问题可以按任务回退。不得通过 `git reset --hard`、`git restore .` 或批量删除回滚。

## 十、明确不做

- 真实服务端登录、云同步、跨设备作品恢复；
- AI 主体分割、背景自动替换、贴纸/文字/模板完整实现；
- 手动抠图、HSL、曲线、滤镜市场；
- 覆盖系统相册中的旧导出文件；续编再次保存生成新的相册资源；
- 批量删除缓存、作品或图库资源；
- SDK/依赖升级、发布签名、上架、部署或自动推送。

## 十一、完成定义

- 七项用户需求全部对应到已执行任务和可复现验收步骤；
- 三个页面域只使用统一作品仓库，`EditPage` 不再导入 `EditWorkStore`；
- 正式保存与草稿保存语义分离，任何失败不会显示虚假成功；
- 导出设置跨页面生效，默认值和六种组合都有测试或真机记录；
- 登录门禁不会丢失当前选图，也不会在普通登录时恢复过期选图；
- 相关单元测试和项目级 debug 构建实际通过；
- JPEG/PNG 和系统相册写入已在真机验证；
- 未修改无关文件，未删除文件，未创建额外依赖，未提交敏感信息；
- 是否提交、推送或合并由用户另行明确授权。
