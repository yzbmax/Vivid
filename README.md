# Vivid

Vivid 是一个基于 HarmonyOS ArkTS 的「蒙版调色」前端界面原型。当前版本聚焦“我的”及其登录、注册、设置和协议页面，提供页面跳转、表单交互、前端校验与响应式布局示例。

## 当前实现

### 页面与路由

| 页面 | 路由 | 功能 |
| --- | --- | --- |
| 我的 | `pages/Mine` | 未登录卡片、登录/注册入口、用户设置、应用设置、协议入口 |
| 登录 | `pages/LoginPage` | 验证码登录、密码登录、手机号/验证码/密码校验 |
| 注册 | `pages/RegisterPage` | 手机号、验证码、密码、确认密码、协议勾选与校验 |
| 用户设置 | `pages/UserSettingsPage` | 未登录状态下的用户信息与登录安全入口 |
| 应用设置 | `pages/AppSettingsPage` | 外观、语言和本地说明入口 |
| 用户协议 | `pages/UserAgreementPage` | 协议正文滚动展示 |
| 隐私政策 | `pages/PrivacyPolicyPage` | 隐私说明滚动展示 |

### 已实现能力

- “我的”页面使用纸页网格背景、四角装饰和统一的页面标题样式。
- 登录页支持验证码登录与密码登录模式切换。
- 密码默认隐藏；登录页使用 `eye` / `eyeoff` 图标切换显示状态，输入框始终保持密码输入类型。
- 登录页键盘弹出时使用 `RESIZE_WITH_CARET`，自动调整滚动位置，使当前输入框和登录按钮保持可访问。
- 注册页已移除密码显示/隐藏功能，密码默认隐藏。
- 注册协议行使用受容器宽度约束的可换行文本，兼容窄屏比例；两个协议链接可分别跳转。
- 表单支持手机号、验证码、密码和确认密码的本地校验，并显示字段级错误信息。
- 未登录用户设置卡片可跳转到登录页。
- 页面返回、协议页面往返和重复点击入口均有对应的路由处理。
- 网格背景集中由 `SealPaperBackground` 绘制，通用标题、按钮、输入框和设置行复用统一样式。

## 当前限制

- 登录、注册和验证码服务尚未接入后端，不创建真实账号。
- 输入的手机号、验证码、密码、昵称和设置不会持久化保存。
- 验证码按钮目前只执行前端校验并提示服务未接入。
- 当前目标设备为 HarmonyOS 手机，真实安全键盘行为仍需在真机上补测。
- 本项目目前以界面原型和前端交互验证为主，不包含图片导入、主体分割或作品编辑服务。

## 技术环境

- HarmonyOS / ArkTS
- DevEco Studio 6.1.1 Release
- `targetSdkVersion`: `6.1.1(24)`
- `compatibleSdkVersion`: `6.1.1(24)`
- 测试框架：`@ohos/hypium`、`@ohos/hamock`
- 应用包名：`com.example.vivid`

## 构建与运行

1. 使用 DevEco Studio 打开项目根目录。
2. 等待依赖和 SDK 索引完成。
3. 选择 HarmonyOS 手机模拟器或已连接的真机。
4. 运行 `entry` 模块的 `default` target。
5. 启动后从“我的”页面进入登录、注册、设置和协议页面进行验证。

命令行构建可使用项目自带的 `hvigorw`。具体命令应以当前 DevEco Studio 和 SDK 安装路径为准。

## 测试与验证

详细的手工测试清单独立维护在 [`docs/Test/Vivid_前端测试清单.md`](docs/Test/Vivid_前端测试清单.md)，包含以下分类：

- 基础功能
- UI 与屏幕适配
- 导航与返回栈
- 页面状态
- 生命周期

当前仓库包含以下自动化测试入口：

- `entry/src/test/AuthValidators.test.ets`：手机号、验证码、密码和确认密码校验。
- `entry/src/test/LocalUnit.test.ets`：本地单元测试示例。
- `entry/src/ohosTest/ets/test/Ability.test.ets`：设备侧 Ability 测试示例。
- `entry/src/test/List.test.ets`、`entry/src/ohosTest/ets/test/List.test.ets`：测试套件入口。

提交前建议执行对应文件的 DevEco Code Linter 定向检查、`git diff --check`，并在模拟器或真机完成测试清单。本文档不将未实际执行的模拟器或真机验证标记为通过。

## 目录概览

```text
entry/src/main/ets/
├── components/       # 蒙版背景、标题、按钮、输入框和设置行
├── entryability/     # 应用入口 Ability
├── pages/            # 我的、登录、注册、设置和协议页面
└── utils/            # 表单校验工具

entry/src/main/resources/base/media/
├── L.svg             # 四角装饰
├── eye.svg           # 显示密码图标
└── eyeoff.svg        # 隐藏密码图标

docs/Test/
└── Vivid_前端测试清单.md
```

## 许可证与发布说明

当前项目处于前端原型阶段。正式发布前仍需补充真实服务接入、隐私与协议审阅、真机兼容性测试、签名配置和发布包验证。
