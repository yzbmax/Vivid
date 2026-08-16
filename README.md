# Vivid

Vivid 是一个基于 HarmonyOS ArkTS 的「蒙版调色」前端界面原型（版本 `0.1.x`）。当前为**三分支合并后的集成分支（`codex/merge-prep`）**，把三个独立原型整合为单一 App：启动进入 `pages/Index` 底部三 Tab（首页 / 作品 / 我的），认证、设置与协议页保留为独立路由。

## 分支来源

| 模块 | 来源 | 集成方式 |
| --- | --- | --- |
| 作品列表 / 详情 / 设计令牌 | `origin/LXT` | 集成基线，`Index` 主框架与 `components/common/Theme.ets` 以此为唯一 |
| 首页（品牌页头 / 相册选图 / 快捷功能 / 近作 / 技艺） | `origin/ljh` | 迁入 `components/home/`，去 `@Entry`，避让机制统一为 LXT 的 `statusBarHeight` |
| 「我的」/ 登录 / 注册 / 设置 / 协议 | `origin/CentralOfUser` | 迁入 `components/mine/` + 独立路由页，`MaskSeal` 共享组件第一阶段保留 |

## 页面与路由

| 页面 | 路由 | 说明 |
| --- | --- | --- |
| 主框架 | `pages/Index` | 唯一 `@Entry` 启动页：底部 Tab 首页 / 作品 / 我的 |
| 首页 Tab | （Index 内） | `components/home/HomePage`，含相册选图入口 |
| 作品 Tab | （Index 内） | `components/works`，筛选 / 排序 / 详情跳转 |
| 我的 Tab | （Index 内） | `components/mine/MinePage`，登录/注册/设置/协议入口 |
| 作品详情 | `pages/WorkDetailPage` | 独立路由，mock 数据 |
| 登录 / 注册 | `pages/LoginPage` / `pages/RegisterPage` | 前端校验完整，服务未接入 |
| 用户设置 / 应用设置 | `pages/UserSettingsPage` / `pages/AppSettingsPage` | 不持久化 |
| 用户协议 / 隐私政策 | `pages/UserAgreementPage` / `pages/PrivacyPolicyPage` | 正文滚动展示 |

`main_pages.json` 共注册 8 个路由。

## 已实现能力

- **首页**：宣纸网格背景（Canvas）、品牌页头、相册选图（`PhotoViewPicker`，无需相册权限）及成功/取消/失败三态 Toast、快捷功能 2×4 网格、近作横滑、技艺列表。
- **作品**：全部 / 已封印 / 草稿筛选、时间正倒序、作品卡片网格 → 详情页。
- **我的**：未登录卡片、登录 / 注册入口、用户与应用设置、协议入口；登录支持验证码 / 密码模式切换与表单字段校验。
- **公共**：统一设计令牌 `components/common/Theme.ets`；`MaskSeal`（`MaskSealPalette` / `SealPageHeader` / `SealButton` / `FloatingInput` / `SettingRow`）阶段一保留供认证链路复用。
- **沉浸式**：`EntryAbility` 全屏，状态栏 / 导航条高度以 px 写入 `AppStorage.statusBarHeight` / `navBarHeight`，各 Tab 与 Tab 栏据此避让。

## 当前限制（原型边界，未假装已实现）

- 登录、注册、验证码服务尚未接入后端，不创建真实账号，提示“服务暂未接入”。
- 手机号、验证码、密码、昵称与设置项不持久化。
- 作品列表使用 `MockWorks`；作品详情为 mock，不支持真实编辑。
- 首页选图后仅 Toast 提示，`TODO` 保留“跳转编辑页”；AI 分割、蒙版编辑、真实保存 / 导出均未实现。
- `MaskSeal` 与 `Theme` 的设计令牌统一属第二阶段工作，本次未合并。

## 技术环境

- HarmonyOS / ArkTS，DevEco Studio 6.1.1
- `deviceTypes`: phone；包名 `com.example.vivid`
- 测试框架：`@ohos/hypium`、`@ohos/hamock`

## 构建与运行

1. 用 DevEco Studio 打开本仓库根目录。
2. 等待依赖与 SDK 索引完成。
3. 选择 HarmonyOS 手机模拟器或真机，运行 `entry` 模块 `default` target。
4. 启动后默认进入 `pages/Index`，检查三 Tab 切换、状态栏 / 导航条避让与各链路往返。

## 测试与验证

自动化测试入口：

- `entry/src/test/AuthValidators.test.ets`：手机号、验证码、密码、确认密码校验。
- `entry/src/test/List.test.ets`：测试套件入口（LocalUnit + AuthValidators）。
- `entry/src/ohosTest/ets/test/Ability.test.ets`：设备侧示例。

提交 / 合并前建议：`git diff --check`、DevEco Code Linter 定向检查，并在模拟器或真机完成手工验证。本仓库不将未实际执行的验证标记为通过。

## 目录概览

```text
entry/src/main/ets/
├── pages/                 # Index(三 Tab) + 详情 / 登录 / 注册 / 设置 / 协议路由
├── components/
│   ├── home/              # ljh 首页组件（HomePage + 7 个子区块）
│   ├── mine/              # MinePage（「我的」Tab）
│   ├── works/             # LXT 作品列表卡片 / 网格
│   ├── common/            # Theme(唯一令牌) / PaperBackground / 公共组件
│   ├── MaskSeal.ets       # COU 共享组件（阶段一保留）
│   └── AgreementPage.ets  # 协议正文展示组件
├── models/                # WorkRecord / MockWorks
├── utils/                 # AuthValidators 表单校验
├── entryability/          # 沉浸式全屏 + pages/Index
└── entrybackupability/
```

## 发布说明

当前处于前端原型阶段。正式发布前仍需补充真实服务接入、隐私与协议审阅、真机兼容性测试、签名配置与发布包验证。