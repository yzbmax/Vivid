# 个人册页相册头像上传设计

日期：2026-08-17
范围：Vivid Mock 认证与用户设置闭环

## 1. 目标与边界

在 `ProfileEditPage` 增加从系统相册选择头像的入口。图片选择沿用当前项目的 `PhotoViewPicker` 方式，仅选择一张图片，不新增相册读写权限。

头像数据只保存在进程内 Mock 账户记录中：

- 退出登录后，账户记录与头像 URI 保留；重新登录同一账号仍可读取。
- 注销账号时，账户记录与头像 URI 一起删除。
- 选择器取消、没有返回图片或选择失败，不修改账户、不刷新 `authRevision`。
- 当前不做图片裁剪、压缩、上传后端、持久化文件复制或系统相册写回。

## 2. 契约与数据模型

现有冻结契约保持不变：`MockUser`、`AuthStatus`、`AuthSession`、`ProfileUpdateRequest` 和 `AccountSettingsResult` 不改名、不加字段。

内部 `MockAccountRecord` 增加可选 `avatarUri?: string`。新增独立契约：

```typescript
export interface ProfileAvatarUpdateRequest {
  nickname: string;
  avatarGlyph: string;
  avatarUri?: string;
}

export type ProfileAvatarUpdateErrorCode =
  | AccountSettingsErrorCode
  | 'INVALID_AVATAR_URI';

export interface ProfileAvatarUpdateResult {
  success: boolean;
  errorCode?: ProfileAvatarUpdateErrorCode;
}
```

新增 Store 能力：

- `getCurrentAvatarUri(): string | undefined`
- `updateProfileWithAvatar(request: ProfileAvatarUpdateRequest): ProfileAvatarUpdateResult`

`updateProfileWithAvatar()` 在一次调用内校验登录态、昵称、字形和图片 URI，全部通过后再同时写入账户记录；失败不得产生部分资料更新。URI 以非空字符串为有效条件，系统选择器返回的 URI 不做路径解析或持久化复制。

## 3. 页面交互与数据流

1. `ProfileEditPage` 进入时从 Store 读取当前用户资料和 `avatarUri`。
2. 页面显示图片头像；无 URI 时显示当前印章字形。
3. 点击“从相册上传头像”创建 `PhotoViewPicker`，设置图片类型、最多一张。
4. 选择成功后仅更新页面预览状态；显示“已选相册头像”提示，不立即写 Store。
5. 点击“落印保存”时调用 `updateProfileWithAvatar()`，成功后由页面调用 `AuthUiState.bumpRevision()` 并返回。
6. 取消选择、系统异常和空结果仅显示轻量提示或保持原状态。

`MinePage`、`UserSettingsPage` 通过 `getCurrentAvatarUri()` 优先显示图片，URI 为空时回退到现有字形渲染。由于 URI 不进入 `MockUser`/`AuthSession`，这些页面仍由 `authRevision` 驱动重新读取。

## 4. 错误处理

- 未登录：返回既有 `NOT_AUTHENTICATED`。
- URI 为空或仅空白：返回新增 `INVALID_AVATAR_URI`，不修改昵称、字形或 URI。
- 昵称和字形错误：复用既有 `INVALID_NICKNAME`、`INVALID_AVATAR_GLYPH`。
- 选择器取消或异常：不调用 Store 更新，不增加 `authRevision`。

## 5. 验证计划

Store 测试覆盖：

- 保存 URI 后当前账户可读取，昵称/字形/URI 同步更新。
- 失败校验不会产生部分更新。
- 登出后重新登录同一账号仍保留 URI。
- 注销后账户和 URI 均不可再读取。
- 未登录和空 URI 返回明确错误码。

静态与构建验证：

- 检查没有修改冻结的 `MockUser`、`AuthSession` 和 `ProfileUpdateRequest`。
- 检查不新增相册权限。
- 执行 `git diff --check`。
- 运行 Auth 单元测试。
- 运行项目级 `assembleApp`，不执行 `default@BuildArkTS`。

## 6. 不在本轮范围

- 系统相册权限申请、相册写入、图片裁剪和压缩。
- 后端上传、云端 URL、跨进程持久化和头像审核。
- 修改已冻结公开会话模型以携带图片字段。
