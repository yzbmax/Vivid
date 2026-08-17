# Vivid 登录、作品与调色编辑 Mock 闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 在现有三分支合并界面基础上，由三名开发者分别完善 Mock 登录、作品与照片导入、独立调色编辑页，并最终跑通“登录—选图—调色—保存为作品—继续编辑”的纯前端闭环。

**架构：** 保留当前 `Index` 的“首页 / 作品 / 我的”三 Tab 框架，新增独立路由 `EditPage`。登录状态、作品数据和编辑参数分别由轻量 Mock Store 管理；页面只消费 Store 暴露的数据与动作，避免三人同时修改同一页面。首轮不接后端、不做 AI 分割和真实高质量像素导出，图片仅在本地流转。

**技术栈：** HarmonyOS 6.1.1（API 24）、ArkTS、ArkUI、系统 `PhotoViewPicker`、现有 `Theme` / `MaskSeal` 组件与资源。

## 全局约束

- 只完善前端交互和 Mock 数据，不接入真实服务器、短信、账号中心、云存储或生产数据库。
- 用户照片只在本地通过 URI 使用，不上传、不复制到外部服务。
- 首轮调色只包含曝光、亮度、对比度、饱和度；不做 AI 分割、主体/背景独立蒙版、HSL、曲线、滤镜和手动抠图。
- `EditPage` 为独立路由，不进入 `Index` 底部 Tab；首页选图和作品“启封续编”都进入该页面。
- 所有新界面沿用 Mask & Seal 设计令牌：宣纸背景、朱砂主色、衬线标题、等宽数值标签、方形滑块头和“落印保存”文案。
- 不新增第三方依赖，不升级 SDK，不修改构建系统。
- 合并集成只能在 `codex/merge-prep` 进行；当前读取到的分支为 `XYW`，实际开发前需按仓库规则准备集成分支或隔离工作区。
- 不删除现有文件，不覆盖用户已有未提交修改，不批量格式化无关文件。

---

## 一、当前基线

| 模块 | 已有内容 | 当前缺口 |
|---|---|---|
| 主框架 | `Index.ets` 已集成首页、作品、我的三个 Tab | 编辑页尚未注册为独立路由 |
| 登录 | 登录、注册、协议、设置页面及表单校验已存在 | 验证码、提交、会话、登录后页面、退出均为占位 |
| 作品 | `WorksPage`、`WorkDetailPage`、六条 `MockWorks` 已存在 | 数据每次重新构造；不能新增作品；续编入口只弹 Toast |
| 图片导入 | `HeroCard` 已调用 `PhotoViewPicker` 选择单张图片 | 选图后只提示文件名，没有进入编辑页 |
| 调色 | PRD 与 `docs/项目结构.md` 已定义 `EditPage` | 页面、路由、编辑状态和调色交互均未实现 |
| 测试 | `AuthValidators.test.ets` 已覆盖表单校验 | 无会话、作品 Store、编辑状态的单元测试 |

## 二、MVP 用户闭环

```text
未登录进入“我的”
  → 使用 Mock 验证码/密码登录
  → “我的”展示 Mock 用户并可退出

首页“呈交新卷宗”
  → PhotoViewPicker 选择一张照片
  → EditPage 预览照片
  → 调整曝光/亮度/对比度/饱和度
  → “落印保存”生成一条 Mock 作品
  → 作品列表能看到新作品
  → 打开详情并“启封续编”
  → EditPage 恢复该作品及参数
```

取消选图、路由参数缺失、作品不存在时必须有明确提示，并允许返回，不出现空白页或崩溃。

## 三、三人职责与边界

### 开发者 A：登录系统与 Mock 会话

**独占范围：** 登录、注册、我的页、认证模型与 Store。

**主要文件：**

- 新建：`entry/src/main/ets/models/AuthModels.ets`
- 新建：`entry/src/main/ets/models/MockAuthStore.ets`
- 修改：`entry/src/main/ets/pages/LoginPage.ets`
- 修改：`entry/src/main/ets/pages/RegisterPage.ets`
- 修改：`entry/src/main/ets/components/mine/MinePage.ets`
- 修改：`entry/src/main/ets/pages/UserSettingsPage.ets`（仅在需要展示 Mock 用户资料时）
- 测试：`entry/src/test/MockAuthStore.test.ets`

**不修改：** `HeroCard.ets`、`WorksPage.ets`、`WorkDetailPage.ets`、`EditPage.ets`。

**Mock 规则：**

- 固定验证码：`123456`。
- 演示账号：`13800138000`；演示密码：`Vivid123`。
- “获取验证码”在手机号合法后显示验证码并进入 60 秒倒计时；倒计时期间不可重复请求。
- 验证码登录只校验合法手机号与固定验证码；密码登录只接受演示账号，避免“任意密码都能登录”的不确定行为。
- 注册完成后生成 Mock 用户并直接建立会话；不持久化明文密码。
- 会话只保存 `userId`、手机号脱敏值、昵称、头像字形和登录状态；退出后清空会话。
- Mock 能力需在界面标注“演示数据”，不得伪装为真实短信或真实账号服务。

**验收标准：**

- [x] 非法手机号、错误验证码、错误密码分别显示对应错误，不只弹通用 Toast。
- [x] 登录成功后返回“我的”，页面从“未登录”切换为用户卡片。
- [x] 注册勾选协议并通过校验后能形成 Mock 会话。
- [x] 登录状态下隐藏“登录 / 注册”，显示“退出登录”。
- [x] 退出后恢复未登录状态，设置页不能继续展示旧用户信息。
- [x] Mock Store 单元测试覆盖成功、失败、退出与脱敏展示。

### 开发者 B：作品数据、照片导入与续编入口

**独占范围：** 照片选择结果、作品 Store、作品列表/详情刷新、进入编辑页的路由。

**主要文件：**

- 新建：`entry/src/main/ets/models/MockWorkStore.ets`
- 修改：`entry/src/main/ets/models/WorkRecord.ets`
- 修改：`entry/src/main/ets/models/MockWorks.ets`
- 修改：`entry/src/main/ets/components/home/HeroCard.ets`
- 修改：`entry/src/main/ets/pages/WorksPage.ets`
- 修改：`entry/src/main/ets/pages/WorkDetailPage.ets`
- 测试：`entry/src/test/MockWorkStore.test.ets`

**不修改：** 登录相关页面、`EditPage` 的界面和调色逻辑。

**数据要求：**

- `MockWorks.ets` 只负责提供初始样例，`MockWorkStore` 负责 `list()`、`findById()`、`create()`、`update()`。
- `WorkRecord` 补充源图引用、编辑参数快照、图片尺寸和更新时间；保留现有六张 Resource 样例兼容展示。
- Store 至少在本次应用进程内保持数据，新增/修改时更新 `updatedAt` 并触发作品页刷新。
- 作品页的统计数字使用真实列表长度，不再固定显示“叁拾贰”。
- 新导入照片的 URI 不写入日志，不放入用户可分享的调试信息。

**验收标准：**

- [ ] 首页选择一张图片后，以 `source=picker` 和 `imageUri` 进入 `EditPage`。
- [ ] 用户取消选择时停留首页，只给轻提示，不进入编辑页。
- [ ] 作品列表继续支持全部/已封缄/草稿筛选和时间排序。
- [ ] 编辑页保存后返回作品页时能看到新增或更新的作品。
- [ ] 作品详情“启封续编”以 `source=work` 和 `workId` 进入 `EditPage`。
- [ ] 无效 `workId` 显示“卷宗不存在”并允许返回。
- [ ] Store 单元测试覆盖初始化、创建、更新、查找和排序。

### 开发者 C：独立调色编辑页

**独占范围：** 编辑页、编辑状态、预览和保存动作；使用 A/B 提供的公共接口，不修改其页面。

**主要文件：**

- 新建：`entry/src/main/ets/pages/EditPage.ets`
- 新建：`entry/src/main/ets/models/EditModels.ets`
- 新建：`entry/src/main/ets/components/editor/PreviewArea.ets`
- 新建：`entry/src/main/ets/components/editor/AdjustPanel.ets`
- 新建：`entry/src/main/ets/components/editor/EditActionBar.ets`
- 修改：`entry/src/main/resources/base/profile/main_pages.json`
- 测试：`entry/src/test/EditModels.test.ets`

**不修改：** 登录页面、作品列表卡片布局、首页三 Tab 框架。

**界面结构：**

```text
EditPage
├─ PageHeader：调色复核 + 返回
├─ PreviewArea：照片、装裱边框、原图对比按压层
├─ AdjustPanel
│  ├─ 曝光 Exposure      -100 … +100
│  ├─ 亮度 Brightness    -100 … +100
│  ├─ 对比度 Contrast    -100 … +100
│  └─ 饱和度 Saturation  -100 … +100
└─ EditActionBar：重置 / 对比 / 落印保存
```

**实现边界：**

- 滑块数值必须实时回显，格式为 `+15`、`00`、`-08`。
- 四个参数都从原图与当前参数重新计算预览，不允许把每次滑动累积写回源图。
- 首轮允许采用 SDK 已验证可用的图片显示效果完成 Mock 预览；如果 API 24 没有稳定的组件级效果，则退化为“参数状态 + 明暗覆盖层”的可见演示，不在本轮临时引入自研像素引擎。
- 原图对比按下时临时显示原图，松开后恢复当前预览。
- “重置”将四项归零；离开存在未保存调整时弹确认提示。
- “落印保存”调用 `MockWorkStore.create/update`，不在本轮写入系统相册。

**验收标准：**

- [ ] `EditPage` 已注册路由，且不显示底部主导航。
- [ ] 从 picker 进入时显示选中的本地照片；从作品进入时恢复作品图片和参数。
- [ ] 四个滑块可独立调整并实时显示数值与预览反馈。
- [ ] 重置与原图对比行为正确。
- [ ] 新建保存生成作品，续编保存更新原作品而不是重复创建。
- [ ] 缺少 `imageUri` / `workId` 时显示错误态并允许返回。
- [ ] 编辑状态单元测试覆盖默认值、边界钳制、重置和参数恢复。

## 四、共享接口冻结

三人开工前先冻结以下命名，避免并行开发期间互相改接口。

```typescript
export enum EditEntrySource {
  Picker = 'picker',
  Work = 'work'
}

export interface EditRouteParams {
  source: EditEntrySource;
  imageUri?: string;
  workId?: string;
}

export interface AdjustParams {
  exposure: number;
  brightness: number;
  contrast: number;
  saturation: number;
}

export interface MockUser {
  userId: string;
  maskedPhone: string;
  nickname: string;
  avatarGlyph: string;
}
```

`WorkRecord` 至少统一以下新增字段：

```typescript
sourceImageUri: string;
width: number;
height: number;
adjustments: AdjustParams;
```

约束：Resource 样例作品允许 `sourceImageUri` 为空；新导入作品必须有本地 URI。`MockWorkStore` 的方法名统一为 `list`、`findById`、`create`、`update`，开发者 C 不直接操作内部数组。

## 五、实施顺序与依赖

### 第 0 阶段：接口冻结（半天）

- [ ] 三人确认上述路由参数、`AdjustParams`、`WorkRecord` 字段和 Store 方法名。
- [ ] 只由开发者 B 修改共享的 `WorkRecord.ets`；开发者 C 只导入使用。
- [ ] 只由开发者 C 注册 `EditPage` 路由；开发者 B 不同时修改 `main_pages.json`。
- [ ] 确认各自文件清单，避免交叉编辑。

### 第 1 阶段：并行完成独立可测模块（第 1—2 天）

- [ ] A 完成 Auth Models、Mock Store 和单元测试，再接登录/注册页。
- [ ] B 完成 Work Store、模型兼容和单元测试，再替换作品页静态构造。
- [ ] C 完成 Edit Models、编辑页静态骨架和路由错误态，再接四个滑块。

### 第 2 阶段：串联入口与出口（第 3 天）

- [ ] B 将 `HeroCard` 选图成功接到 `EditPage`。
- [ ] B 将作品详情“启封续编”接到 `EditPage`。
- [ ] C 接入 `MockWorkStore`，完成新建保存与续编更新。
- [ ] A 将成功登录/注册后的返回行为与“我的”状态切换接通。

### 第 3 阶段：集成验证（第 4 天）

- [ ] 在 `codex/merge-prep` 依次集成：共享模型 → Work Store → EditPage → 入口路由 → Auth。
- [ ] 每次集成后运行 `git diff --check`、路由注册检查和引用残留检查。
- [ ] 最后仅运行与变更直接相关的单元测试、静态检查和一次 `assembleApp` debug 构建；不交付签名 HAP。

## 六、提交建议

每个提交只包含一个可审查目标，不使用 `git add .`：

1. `feat(auth): add mock session store`
2. `feat(auth): connect login and registration flows`
3. `feat(auth): render authenticated mine state`
4. `feat(works): add mutable mock work store`
5. `feat(works): route selected photos to editor`
6. `feat(works): connect work detail resume action`
7. `feat(editor): add edit route and state model`
8. `feat(editor): add basic adjustment controls`
9. `feat(editor): save edits into mock works`

实际执行提交前仍须按 `AGENTS.md` 检查当前分支、远程、工作区、diff 和待暂存文件；本计划书本身不授权提交或推送。

## 七、Mock 数据设计

### 登录 Mock

| 场景 | 输入 | 结果 |
|---|---|---|
| 验证码成功 | 合法手机号 + `123456` | 创建演示会话 |
| 验证码失败 | 其他验证码 | 字段错误“验证码不正确” |
| 密码成功 | `13800138000` + `Vivid123` | 创建演示会话 |
| 密码失败 | 其他账号或密码 | 字段错误“账号或密函不匹配” |
| 注册成功 | 合法字段 + 已同意协议 | 创建新 Mock 用户并登录 |

### 作品 Mock

- 保留现有六条静态作品作为初始数据。
- 新选照片默认标题为“未题新卷”，状态为草稿；保存后可变为已封缄。
- 新增 ID 使用 `MOCK-时间戳` 或递增编号，保证进程内唯一。
- 保存时记录 `sourceImageUri`、四项调色参数、`createdAt`、`updatedAt`。
- Mock 重启后是否恢复不作为本轮验收项；若需要跨启动持久化，应另开计划评估 Preferences 与 URI 可持续访问问题。

## 八、集成验收清单

### 主路径

- [ ] 启动后首页、作品、我的三个 Tab 正常切换。
- [ ] 首页选择照片后进入独立编辑页。
- [ ] 调整四项参数、对比、重置均有可见反馈。
- [ ] 保存后作品列表出现新作品，详情可打开。
- [ ] 从详情续编后恢复同一作品，保存不会新增重复卡片。
- [ ] 登录和注册成功后“我的”显示 Mock 用户，退出后恢复未登录。

### 异常路径

- [ ] 取消相册选择不会进入编辑页。
- [ ] 空 URI、无效作品 ID、作品图片不可访问时显示错误态。
- [ ] 快速重复点击保存只执行一次。
- [ ] 登录错误信息与具体字段对应。
- [ ] 路由返回后底部 Tab 和安全区布局不发生错位。

### 最小验证命令

计划执行阶段优先使用仓库现有测试与构建入口；具体命令以 DevEco/Hvigor 当前环境为准：

- Auth：运行 `AuthValidators.test.ets` 与 `MockAuthStore.test.ets`。
- Works：运行 `MockWorkStore.test.ets`。
- Editor：运行 `EditModels.test.ets`。
- 集成前：`git diff --check`。
- 集成完成：执行项目级 `assembleApp` debug 构建，只验证 ArkTS 编译、路由注册和应用打包链路；不直接执行 `default@BuildArkTS`。

真机相册 URI、系统选择器和视觉预览必须在真机或模拟器补测；未连接设备时不得声称这些能力已验证通过。

## 九、风险与处置

| 风险 | 影响 | 处置 |
|---|---|---|
| 三人同时改 `WorkRecord` 或路由表 | 合并冲突、字段不一致 | 第 0 阶段冻结接口并指定唯一负责人 |
| URI 在应用重启后失效 | 旧作品图片无法恢复 | 本轮只保证进程内 Mock；持久化另立计划 |
| API 24 的图片显示效果不足以模拟四项调色 | 预览与滑块不一致 | 保留参数闭环与明显可见的 Mock 效果，不临时扩大到像素引擎 |
| 静态 Resource 与 URI 类型不兼容 | 旧卡片或新照片无法共用组件 | 由 B 在 `WorkRecord` 建立统一图片引用适配，组件不直接判断数据来源 |
| 登录会话与页面状态不同步 | 返回“我的”仍显示未登录 | Store 变更通过统一 revision/状态键通知页面刷新 |
| 当前分支不是规定的集成分支 | 违反仓库合并规则 | 实施前切换到 `codex/merge-prep` 或建立符合规则的隔离工作区 |

## 十、完成定义

满足以下全部条件才算本计划完成：

- 三个工作包都达到各自验收标准；
- 选图—编辑—保存—作品—续编形成可重复的 Mock 闭环；
- 登录—用户态—退出形成可重复的 Mock 闭环；
- 无新增第三方依赖、无真实网络请求、无照片上传；
- 相关单元测试通过，ArkTS debug 编译通过；
- 真机未验证项被明确记录，不以静态检查代替真机结论；
- 所有集成提交只包含本任务相关文件，没有提交敏感信息或用户已有修改。

## 十一、本轮明确不做

- 真实验证码、账号后端、找回密码和第三方登录；
- AI 主体识别、主体/背景独立蒙版；
- 真实像素级高质量渲染与系统相册导出；
- 图片云同步、跨设备恢复和作品分享；
- 社区、会员、支付、埋点和生产发布；
- HAP 签名、上架或部署；`assembleApp` 仅作为本地编译与打包链路验证。

---

## 十二、本轮用户资料与登录安全增补（开发者 A）

本节是在既有登录 Mock 闭环基础上的增补要求。计划书先于代码修改；本轮新增契约创建后即冻结，页面只消费契约，不因 UI 调整改名或改变字段含义。

### 12.1 产品边界与安全决策

- 退出登录必须先弹确认框；取消不改变会话，确认后才调用 `logout()`。
- 用户设置的“个人册页”进入昵称、预设印章字形头像编辑；本轮不接系统相册头像、图片 URI 或新增权限。
- “手机号与登录安全”进入独立安全页，支持换绑手机号、首次设密/修改密码和注销账号。
- Mock 阶段换绑手机号只校验新手机号验证码，不增加旧手机号或密码二次校验；真实服务接入时必须重新评估高风险操作验证策略。
- 验证码登录未注册手机号时创建无密码正式 Mock 账户；首次设密需验证当前绑定手机号，之后修改密码必须输入原密码。
- 昵称保存前执行 `trim()`，合法条件为 `trim().length` 在 1—12 之间；长度按 ArkTS/JS UTF-16 code units 计算，纯空白无效。
- 账户注销必须先完成凭证验证，再弹最终确认框；取消确认会清除本次注销授权并要求重新验证。
- 本轮不接真实短信、后端账号中心、持久化存储或生产安全策略。

### 12.2 新增冻结契约

新增 `entry/src/main/ets/models/AccountSettingsModels.ets`，不得重声明或改动已冻结的 `MockUser`、`AuthStatus`、`AuthSession`、`EditEntrySource`、`EditRouteParams` 和 `AdjustParams`。

```typescript
export interface AccountSecuritySnapshot {
  maskedPhone: string;
  hasPassword: boolean;
}

export interface ProfileUpdateRequest {
  nickname: string;
  avatarGlyph: string;
}

export interface PhoneBindingChangeRequest {
  newPhone: string;
  code: string;
}

export interface PasswordSetupRequest {
  code: string;
  newPassword: string;
}

export interface PasswordChangeRequest {
  currentPassword: string;
  newPassword: string;
}

export interface AccountClosureVerification {
  method: 'password' | 'code';
  credential: string;
}
```

同时冻结 `AccountSettingsResult`、`SettingsCodeRequestResult` 和 `AccountSettingsErrorCode`。错误码至少包括：

`INVALID_NICKNAME`、`INVALID_AVATAR_GLYPH`、`INVALID_PHONE`、`INVALID_CODE`、`CODE_NOT_REQUESTED`、`CODE_PHONE_MISMATCH`、`CODE_PURPOSE_MISMATCH`、`CODE_ALREADY_CONSUMED`、`SAME_PHONE`、`PHONE_ALREADY_BOUND`、`PASSWORD_NOT_SET`、`PASSWORD_ALREADY_SET`、`INVALID_PASSWORD`、`INCORRECT_CURRENT_PASSWORD`、`SAME_PASSWORD`、`NOT_AUTHENTICATED`、`INVALID_CREDENTIALS`、`CLOSURE_NOT_VERIFIED`。

### 12.3 Store 状态与不变量

`MockAuthStore` 内部账户记录使用稳定的 `accountId`，手机号只是可修改属性：

```typescript
interface MockAccountRecord {
  accountId: string;
  phone: string;
  password?: string;
  nickname: string;
  avatarGlyph: string;
}
```

- `accountId` 创建后不改变，也不从手机号推导；`MockUser.userId` 是它的公开投影。
- Store 保存 `currentAccountId`；`getSession()` 每次从当前账户记录重新投影，确保 `session.user` 始终是最新资料。
- 新增动作：`getAccountSecuritySnapshot`、`updateProfile`、`requestPhoneBindingCode`/`changePhoneBinding`、`requestPasswordSetupCode`/`setupPassword`、`changePassword`、`requestAccountClosureCode`、`verifyAccountClosure`、`cancelAccountClosure`、`closeAccount`。
- 密码不进入 `MockUser` 或 `AuthSession`，安全快照只暴露 `hasPassword`。

所有验证码统一使用带手机号、用途、验证码和消费状态的内部 Challenge：

```typescript
type MockCodePurpose = 'LOGIN' | 'REGISTRATION' | 'PHONE_BINDING' | 'PASSWORD_SETUP' | 'ACCOUNT_CLOSURE';

interface MockCodeChallenge {
  phone: string;
  purpose: MockCodePurpose;
  code: string;
  consumed: boolean;
}
```

每个用途最多保留一个有效 Challenge；同一用途的新请求替换旧请求，不同用途的 Challenge 可以并存。校验必须同时满足手机号、用途、验证码和 `consumed === false`；成功后立即消费，失败不消费。注册单独标记 `REGISTRATION`，避免复用登录用途。

注销授权使用内部 `AccountClosureAuthorization`（`verified`、`issuedAt`、`accountId`）：

- `verifyAccountClosure()` 先清旧授权，凭证成功后建立只属于当前账户的授权。
- `closeAccount()` 无凭证参数，只接受属于当前账户且已验证的授权；成功或失败都立即清除授权。
- 登出、重新登录、切换账户、成功修改账户安全信息、页面离开和最终确认取消，都会清除授权。
- 本轮不添加分钟级过期计时；授权仅在一次“验证—最终确认”交互生命周期内有效。

### 12.4 UI 刷新与页面

新增 `AuthUiState`，只负责维护 `authRevision` 和 `AppStorage`。`MockAuthStore` 不再直接依赖 ArkUI 或 revision。登录、注册、退出、资料保存、换绑、设密、改密和注销成功后由页面调用 `AuthUiState.bumpRevision()`。

新增路由页面：

- `ProfileEditPage`：昵称和“印、墨、朱、卷、砚、山”预设字形头像选择。
- `AccountSecurityPage`：换绑手机号、首次设密/修改密码、凭证验证和注销确认。

`UserSettingsPage` 的个人册页与安全行改为入口；未登录统一转登录页。`MinePage` 与 `UserSettingsPage` 的退出操作均使用确认弹窗。注销成功后删除账户、清理 Challenge/授权/会话并返回 Mine 或首页匿名态。

### 12.5 验收与实施顺序

1. 更新本计划书。
2. 新增并冻结 `AccountSettingsModels.ets`。
3. 先扩展 `MockAuthStore.test.ets`，覆盖稳定账户 ID、Session 最新投影、Challenge 一次性消费、用途/手机号隔离、注销授权生命周期和 logout/closeAccount 分离。
4. 重构 `MockAuthStore.ets`，运行 Auth 测试，再迁移 `AuthUiState`。
5. 实现 `ProfileEditPage`、`AccountSecurityPage`，接入用户设置、我的、登录和注册页面并注册路由。
6. 从 `SealPaperBackground` 移除四个 `L.svg` 节点，从 `PaperFrame` 移除四个定位括号；保留资源文件。
7. 执行 `git diff --check`、接口/路由/装饰引用检查、Auth 单元测试和项目级 `assembleApp`。不执行 `default@BuildArkTS`。

本轮不自动提交或推送，完成后交由开发者 A 审查。

### 12.6 相册头像上传增补

- `ProfileEditPage` 增加“从相册上传头像”入口，沿用项目已有 `PhotoViewPicker`，仅选择一张图片，不新增相册读写权限。
- 相册选择结果先作为页面临时预览，点击“落印保存”时与昵称、印章字形一起原子写入内部账户记录；取消选择、空结果或系统异常不修改账户、不刷新 `authRevision`。
- 内部 `MockAccountRecord` 增加可选 `avatarUri`；新增 `ProfileAvatarModels.ets`、`getCurrentAvatarUri()` 和 `updateProfileWithAvatar()`，不得修改已冻结的 `MockUser`、`AuthSession` 或 `ProfileUpdateRequest`。
- `MinePage`、`UserSettingsPage` 和个人册页优先显示相册图片，无图片时回退现有六种印章字形。
- 头像 URI 只在当前进程 Mock 账户记录中保留：退出登录后重新登录仍存在，注销账号时随账户删除；本轮不做裁剪、压缩、后端上传、文件复制或持久化。
