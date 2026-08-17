# Mock 认证闭环设计

## 目标

完成开发者 A 的登录业务范围：验证码登录、演示账号密码登录、注册建立 Mock 会话、登录态“我的”页、用户设置资料展示和退出登录。实现只在当前应用进程内生效，不接真实短信、账号服务或持久化存储。

## 范围与非目标

包含：

- 固定演示验证码 `123456`；合法手机号请求后返回演示码，并由页面维护 60 秒倒计时。
- 演示密码账号 `13800138000 / Vivid123`。
- 验证码与请求手机号绑定校验。
- 注册字段校验、重复手机号校验、协议勾选和注册后自动登录。
- “我的”页和用户设置页根据会话展示未登录态或用户资料。
- 退出后留在当前页，恢复未登录态。

不包含：

- 真实验证码、网络请求、账号中心、找回密码和第三方登录。
- 明文密码持久化、跨进程恢复或云端同步。
- 修改作品、编辑页、首页和底部 Tab 框架。

## 共享契约

`AuthModels.ets` 在接口冻结基础上补充显式会话状态：

```typescript
export type AuthStatus = 'anonymous' | 'authenticated';

export interface AuthSession {
  status: AuthStatus;
  user?: MockUser;
}
```

`MockUser` 保持已冻结字段：`userId`、`maskedPhone`、`nickname`、`avatarGlyph`。

认证 Store 不暴露裸 `currentUser` 字段，统一提供：

```typescript
getSession(): AuthSession;
getCurrentUser(): MockUser | undefined;
```

Store 操作契约为：

```typescript
requestCode(phone: string): RequestCodeResult;
loginWithCode(phone: string, code: string): AuthResult;
loginWithPassword(phone: string, password: string): AuthResult;
register(phone: string, code: string, password: string): AuthResult;
logout(): void;
```

`RequestCodeResult` 至少包含 `success`，成功时返回 `demoCode`；`AuthResult` 至少包含 `success`、当前 `session` 和可供页面映射文案的错误码。

## Store 内部模型与数据流

`MockAuthStore` 内部维护三类进程内数据：

1. 密码账户表：预置演示账号；注册成功时追加账户。账户内部保存密码仅用于本轮 Mock 密码比较，不写入 Preferences 或日志。
2. 待验证验证码：保存最近一次 `{ phone, code }`。请求新手机号会覆盖旧记录；登录和注册必须同时匹配手机号与验证码。
3. 当前会话：初始为 `{ status: 'anonymous' }`，成功登录/注册后切换为 `{ status: 'authenticated', user }`，退出时清空为匿名态。

验证码登录保留原计划“合法手机号 + 固定验证码即可登录”的行为：手机号尚未存在密码账户时，只创建本进程临时会话，不写入密码账户表，因此之后仍可注册该手机号的密码账户。密码登录只比较密码账户表。

所有成功或退出操作递增 `authRevision`，通过 `AppStorage` 通知页面重新读取 `getSession()`。`authRevision` 是 UI 刷新辅助状态，真实认证状态仍以 Store 的 `AuthSession` 为准。

## 错误处理

页面继续使用现有 `AuthValidators` 展示格式错误；Store 返回业务错误码，页面映射为中文字段错误：

- `INVALID_PHONE`：`请输入有效的手机号`
- `CODE_NOT_REQUESTED`：`请先获取验证码`
- `CODE_PHONE_MISMATCH`：`验证码与手机号不匹配`
- `INVALID_CODE`：`验证码不正确`
- `INVALID_CREDENTIALS`：`手机号或密码不正确`
- `PHONE_ALREADY_REGISTERED`：`该手机号已注册`

不记录手机号、验证码或密码日志。页面将 Mock 数据明确标注为“演示数据”。

## 页面行为

### LoginPage

- 验证码/密码模式沿用现有切换 UI。
- 请求验证码成功后显示演示码和剩余秒数；倒计时只存在页面状态中，离开页面清理计时器。
- 提交成功调用 `router.back()` 返回来源页；返回失败时使用 Index 路由兜底。

### RegisterPage

- 复用手机号、验证码、密码、确认密码和协议字段。
- 提交前依次执行格式校验、验证码匹配、重复手机号检查。
- 成功建立会话并返回来源页；失败错误显示在对应字段。

### MinePage / UserSettingsPage

- 使用 `@StorageProp('authRevision')` 触发重建，渲染时从 `MockAuthStore.getSession()` 读取真实状态。
- 匿名态显示登录/注册入口；认证态显示脱敏手机号、昵称、头像字形和“演示数据”标记。
- 退出操作调用 Store 后停留当前页面，页面切换回匿名态。

## 测试设计

新增 `MockAuthStore.test.ets` 并加入现有 `entry/src/test/List.test.ets`：

- 验证码请求成功并绑定手机号。
- 更换手机号后复用旧验证码失败。
- 演示账号密码登录成功；错误账号或密码统一失败。
- 注册成功建立认证会话。
- 重复手机号返回 `PHONE_ALREADY_REGISTERED`。
- 退出后会话为匿名态。
- 用户手机号按 `138****5678` 形式脱敏展示。

## 验证与风险

- 只运行与本轮改动直接相关的单元测试和 `assembleApp`；不执行 `default@BuildArkTS`。
- 不连接真机时，不宣称系统键盘、路由返回和 UI 倒计时已完成真机验证。
- `authRevision` 与 `AuthSession` 暂时是 Store 状态和 UI 通知的双层结构；后续若认证功能扩展，再统一为可观察 `AuthState`，本轮不提前重构。
