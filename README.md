# Vivid


## 当前能力

### 主框架与作品

- pages/Index 提供首页、作品、我的三个底部 Tab。
- 首页包含宣纸网格背景、品牌区、PhotoViewPicker 单图选取入口、快捷功能、近作和技艺列表。
- 作品页支持全部 / 已封印 / 草稿筛选、时间排序、作品卡片网格和详情路由。
- 作品列表与详情仍使用 MockWorks；调色复核页已接入图片预览、文字/边框合成和导出流程，但尚未接入云端保存。

### 图片导入与 LUT 滤镜

- 首页通过系统 PhotoViewPicker 选择单张图片，并将稳定的应用沙箱 URI 传入编辑页。
- 编辑页使用独立的预览 PixelMap，切换滤镜和生成缩略图不会释放或覆盖原图。
- 滤镜目录由 `FilterCatalog.ets` 统一注册，资源位于 `entry/src/main/resources/rawfile/filters/`。
- Native C++ 解析 16³ 与 33³ `.cube`；16³ LUT 会以三线性插值重采样到 33³。
- LUT 输出允许有限的扩展范围值，NaN 与 Infinity 仍会被拒绝；最终像素写回时统一截断到有效通道范围。
- 渲染优先使用 Vulkan Compute；GPU 输出异常或无变化时回退到 CPU LUT 渲染，保证滤镜效果可见。
- 预览与缩略图均使用异步代次控制，过期结果会被丢弃并释放；滤镜强度范围为 0–100%。
- “原图”和滤镜状态保留相同的控制区高度，切换滤镜不会改变预览画布布局。

### 编辑器文字、边框与导出

- `EditPage` 与预览区共用等比适配的照片内容矩形，横图、竖图和长宽比为 5:4 / 16:9 的图片不会溢出背景。
- 文字图层支持最多 8 层、实时输入、5 种字体和 8 种固定颜色；“保存”只确认当前文字内容，选择图层不会单独产生脏状态。
- 边框预览提供 6 种模板，边框绘制在照片内容矩形之外，不遮挡滤镜、贴纸和文字；导出时与当前滤镜、文字一起合成。
- 滤镜缩略图按预设逐项生成；缺失或不可用的 LUT 只隐藏对应预设，不阻塞编辑页进入。

### 登录与注册 Mock 闭环

- 登录支持验证码登录和密码登录。
- 注册使用独立的 REGISTRATION 验证码 Challenge，避免复用登录验证码。
- 验证码登录未注册手机号时创建无密码 Mock 账户。
- 每个账户拥有稳定的内部 accountId；换绑手机号不会创建新账户，MockUser.userId 保持不变。
- getSession() 每次从最新账户记录投影公开用户资料，避免资料修改后出现旧会话快照。
- 验证码 Challenge 绑定手机号、用途、验证码和消费状态；成功后一次性消费，失败不消费。
- AuthUiState 统一维护 authRevision，Store 不直接依赖 ArkUI 或 AppStorage。

### 个人册页与头像

- pages/ProfileEditPage 支持昵称编辑和六种预设印章字形：印、墨、朱、卷、砚、山。
- 支持通过系统 PhotoViewPicker 从相册选择一张头像图片，不新增相册权限。
- 相册头像保存前仅在页面预览，点击“落印保存”后与昵称、字形一起写入 Mock 账户。
- 图片 URI 只在当前进程内保留：退出登录后重新登录仍可读取，注销账号时随账户删除。
- MinePage、UserSettingsPage 和个人册页优先显示相册图片，没有图片时回退到印章字形。
- 登录页使用 Login.png，注册页使用 Register.png 替换原有的红圈文字图标。

### 登录安全与账号设置

- pages/AccountSecurityPage 支持换绑手机号、首次设置密码、修改密码和注销账号。
- Mock 换绑手机号只校验新手机号验证码；接入真实服务时需要重新评估旧手机号、密码或多因素验证。
- 无密码账户首次设密必须验证当前绑定手机号；已有密码后修改密码必须输入原密码。
- 注销根据账户是否有密码选择密码或手机号验证码验证，验证成功后还需要系统最终确认。
- 注销授权只绑定当前 accountId，取消确认、登出、换账号、账号安全信息成功变更或关闭失败都会失效。
- MinePage 与 UserSettingsPage 的退出登录都需要确认弹窗；退出登录不会删除账号。
- 注销成功会删除账户、清理 Challenge、清理授权并回到匿名态。

### 界面与资源

- 沿用 MaskSeal 组件和 Theme 设计令牌：宣纸背景、朱砂主色、衬线标题和文书式按钮。
- 已移除 SealPaperBackground 的四个 L.svg 角饰和 PaperFrame 的四个定位括号；资源文件仍保留。
- 登录、注册、用户设置、账号安全和个人册页均为独立路由。

## 页面与路由

| 页面 | 路由 | 说明 |
| --- | --- | --- |
| 主框架 | pages/Index | 首页 / 作品 / 我的三 Tab |
| 调色复核 | pages/EditPage | 图片预览、LUT 滤镜、文字/边框编辑、强度调节与导出 |
| 作品详情 | pages/WorkDetailPage | Mock 作品详情 |
| 登录 | pages/LoginPage | 验证码 / 密码登录 |
| 注册 | pages/RegisterPage | 注册验证码 + 密码注册 |
| 用户设置 | pages/UserSettingsPage | 个人册页与账号安全入口、退出确认 |
| 个人册页 | pages/ProfileEditPage | 昵称、印章字形、相册头像编辑 |
| 账号安全 | pages/AccountSecurityPage | 手机号、密码、注销流程 |
| 应用设置 | pages/AppSettingsPage | 原型设置页 |
| 用户协议 | pages/UserAgreementPage | 协议正文 |
| 隐私政策 | pages/PrivacyPolicyPage | 隐私政策正文 |

以上路由统一注册于 entry/src/main/resources/base/profile/main_pages.json。

## 认证与账户模型

公开认证契约位于 entry/src/main/ets/models/AuthModels.ets，保持以下模型稳定：

- MockUser
- AuthStatus
- AuthSession

账号设置相关契约位于：

- AccountSettingsModels.ets：资料、安全快照、手机号、密码、注销和错误码。
- ProfileAvatarModels.ets：相册头像 URI 的原子资料更新请求与结果。

核心业务实现位于 MockAuthStore.ets。密码不会进入 MockUser 或 AuthSession，安全页只通过 AccountSecuritySnapshot.hasPassword 得到账户是否已设密。

## 测试与验证

### 测试覆盖

entry/src/test/MockAuthStore.test.ets 覆盖：

- 验证码登录创建无密码账户、稳定账户 ID 和登出后重新登录。
- 注册重复手机号、密码登录统一凭证错误和 Session 最新资料投影。
- 昵称 trim().length、非法头像字形和密码规则。
- Challenge 的手机号、用途、验证码和一次性消费校验。
- 手机号换绑后账户 ID 不变；旧手机号验证码不能用于设密；不同用途验证码不能交叉使用。
- 首次设密、修改密码、原密码错误和相同密码。
- 注销授权的取消、登出、切换账户、重复验证码、账户删除和 logout() / closeAccount() 分离。
- 相册头像 URI 的保存、原子校验、匿名态拒绝、登出保留和注销删除。

其他测试入口：

- entry/src/test/AuthValidators.test.ets：手机号、验证码、密码和确认密码校验。
- entry/src/test/FilterState.test.ets：滤镜目录、选择状态与强度边界。
- entry/src/test/PreviewPipeline.test.ets：预览尺寸、渲染代次与 PixelMap 所有权。
- entry/src/test/ThumbnailPipeline.test.ets：滤镜缩略图生成与原图回退。
- entry/src/test/TextLayerState.test.ets：文字内容校验、图层上限、默认值、钳制与选择回退。
- entry/src/test/TextLayoutResolver.test.ets：文字布局比例、坐标反算与拖动边界。
- entry/src/test/EditorPreviewLayout.test.ets：照片内容矩形与边框预览几何。
- entry/src/test/PhotoPickerService.test.ets：选图结果、URI 解析与沙箱导入。
- entry/src/main/cpp/filter/tests/：Cube 解析、LUT 插值、FilterEngine 与 Vulkan 契约测试源码。
- entry/src/test/LocalUnit.test.ets：本地 Hypium 示例测试。
- entry/src/test/List.test.ets：本地测试套件入口。
- entry/src/ohosTest/ets/test/Ability.test.ets：设备侧示例测试。

### Auth 单元测试

在 Windows PowerShell 中运行：

    $env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
    $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
    & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug test --no-daemon --no-incremental

预期结果：BUILD SUCCESSFUL，且 Hypium 无断言错误。

### 项目级构建验证

按项目约定使用 assembleApp 验证 ArkTS 编译、资源处理、路由和应用打包链路：

    $env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
    $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
    & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' -p product=default -p buildMode=debug assembleApp --no-daemon --no-incremental

本项目不执行 default@BuildArkTS。当前工程未配置签名 profile，构建时会跳过签名；这不代表已生成可发布的签名 HAP。

### 提交前检查

    git diff --check
    git status --short --branch

还应检查新增路由、冻结契约、资源引用和 L.svg / 四角装饰残留。未连接真机或模拟器时，不将系统相册实际交互、视觉布局和运行时 URI 访问描述为已验证。

## 技术环境

- HarmonyOS / ArkTS / ArkUI
- DevEco Studio 6.1.1
- @ohos/hypium 1.0.25
- @ohos/hamock
- 设备类型：phone
- 包名：com.example.vivid

## 目录概览

    entry/src/main/ets/
    ├── pages/
    │   ├── Index.ets                 # 三 Tab 主框架
    │   ├── LoginPage.ets             # 登录
    │   ├── RegisterPage.ets          # 注册
    │   ├── ProfileEditPage.ets       # 昵称、字形、相册头像
    │   ├── AccountSecurityPage.ets   # 手机号、密码、注销
    │   └── UserSettingsPage.ets      # 用户设置入口
    ├── components/
    │   ├── home/                     # 首页与 PhotoViewPicker 入口
    │   ├── mine/                     # 我的 Tab
    │   ├── works/                    # 作品列表与卡片
    │   ├── common/                   # Theme、PaperFrame、公共组件
    │   ├── editor/                   # 预览区、滤镜面板与编辑控件
    │   └── MaskSeal.ets              # Mask & Seal 共享组件
    ├── features/editor/filter/       # 滤镜目录、状态、控制器与 Native 桥接
    ├── models/
    │   ├── AuthModels.ets            # 冻结公开认证契约
    │   ├── AccountSettingsModels.ets # 账号设置契约
    │   ├── ProfileAvatarModels.ets   # 相册头像契约
    │   ├── MockAuthStore.ets         # 进程内 Mock 认证与账号业务
    │   └── AuthUiState.ets            # authRevision / AppStorage 刷新边界
    ├── utils/AuthValidators.ets      # 表单校验
    └── entryability/                 # 沉浸式窗口与启动页

    entry/src/main/cpp/
    ├── filter/                       # Cube 解析、CPU/Vulkan LUT 渲染与测试
    └── napi/                         # ArkTS Native 接口与 PixelMap 边界

## 原型限制

- 无真实后端账号中心、短信服务、持久化存储或生产级安全策略。
- 换绑手机号当前只校验新手机号验证码，注销授权没有分钟级过期计时。
- 头像只保存系统返回的 URI，不做裁剪、压缩、云端上传或文件复制。
- 作品云端保存、AI 分割和蒙版导出尚未实现；当前导出仅覆盖编辑器中的滤镜、文字与边框合成。
- 仍需在真机补充字体加载、键盘可见性、相册运行时交互和最终导出视觉验证，并完成隐私协议审阅、签名配置和发布包验证。
