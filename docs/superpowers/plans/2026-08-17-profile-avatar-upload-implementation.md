# 个人册页相册头像上传实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不修改已冻结公开认证契约的前提下，为个人册页增加系统相册头像选择、预览、保存和进程内账号级保留能力。

**Architecture:** 使用项目已有的 HarmonyOS `PhotoViewPicker`，只取得图片 URI，不申请相册权限、不复制图片文件。URI 存在 `MockAuthStore` 的内部账户记录中；新增独立头像资料请求/结果契约与原子更新方法，页面保存时一次性写入昵称、字形和 URI，公开 `MockUser`/`AuthSession` 继续只投影既有字段。

**Tech Stack:** ArkTS、ArkUI、`@kit.MediaLibraryKit` 的 `photoAccessHelper.PhotoViewPicker`、现有 MockAuthStore、Hypium、Hvigor `assembleApp`。

## Global Constraints

- 不修改、不重声明 `MockUser`、`AuthStatus`、`AuthSession`、`ProfileUpdateRequest`、`AccountSettingsResult`。
- 头像 URI 仅保存在当前进程的 Mock 账户记录中；退出登录保留，注销账号删除。
- 系统选择器只选一张图片；不新增相册权限、图片裁剪、压缩、后端上传或持久化复制。
- 选择取消、空结果或异常不更新账户、不调用 `AuthUiState.bumpRevision()`。
- 页面保存成功后只由页面调用一次 `AuthUiState.bumpRevision()`。
- 构建只执行项目级 `assembleApp`，不执行 `default@BuildArkTS`。
- 本轮不自动提交或推送。

---

### Task 1: 冻结头像上传契约并更新账户计划

**Files:**
- Modify: `docs/Vivid 登录作品与调色编辑Mock闭环实施计划.md`，在用户资料与登录安全增补后追加头像上传边界和新契约说明
- Create: `entry/src/main/ets/models/ProfileAvatarModels.ets`

**Interfaces:**
- Produces `ProfileAvatarUpdateRequest { nickname: string; avatarGlyph: string; avatarUri?: string }`。
- Produces `ProfileAvatarUpdateErrorCode = AccountSettingsErrorCode | 'INVALID_AVATAR_URI'`。
- Produces `ProfileAvatarUpdateResult { success: boolean; errorCode?: ProfileAvatarUpdateErrorCode }`。
- Keeps all existing models and error-code names unchanged.

- [ ] **Step 1: Write the failing model import check**

在 `entry/src/test/MockAuthStore.test.ets` 增加 `import { ProfileAvatarUpdateRequest } from '../main/ets/models/ProfileAvatarModels';`，并声明一个仅用于类型检查的请求：

```typescript
const avatarRequest: ProfileAvatarUpdateRequest = {
  nickname: '头像主人',
  avatarGlyph: '印',
  avatarUri: 'file://mock/avatar.jpg'
};
expect(avatarRequest.avatarUri).assertEqual('file://mock/avatar.jpg');
```

- [ ] **Step 2: Run the Auth test target to verify the new type is missing**

Run the existing entry Auth test command. Expected: compile failure because `ProfileAvatarModels.ets` and its exported types do not exist yet.

- [ ] **Step 3: Add the new standalone model file**

Create `ProfileAvatarModels.ets` with exactly:

```typescript
import { AccountSettingsErrorCode } from './AccountSettingsModels';

export interface ProfileAvatarUpdateRequest {
  nickname: string;
  avatarGlyph: string;
  avatarUri?: string;
}

export type ProfileAvatarUpdateErrorCode = AccountSettingsErrorCode | 'INVALID_AVATAR_URI';

export interface ProfileAvatarUpdateResult {
  success: boolean;
  errorCode?: ProfileAvatarUpdateErrorCode;
}
```

Use the existing `AccountSettingsModels.ets` file only as a dependency; do not add fields to its frozen interfaces.

- [ ] **Step 4: Append the confirmed product boundary to the plan document**

Document that URI selection is preview-only until save, logout preserves the account URI, closure deletes it, and no photo permission is added.

- [ ] **Step 5: Re-run the type check**

Run the Auth test target. Expected: the model import compiles; Store methods referenced by later tasks may still be absent, so keep this checkpoint limited to model compilation if the test harness reports unrelated missing methods.

---

### Task 2: Extend MockAuthStore atomically and add Store tests

**Files:**
- Modify: `entry/src/main/ets/models/MockAuthStore.ets`
- Modify: `entry/src/test/MockAuthStore.test.ets`

**Interfaces:**
- Consumes `ProfileAvatarUpdateRequest` and `ProfileAvatarUpdateResult` from Task 1.
- Produces `MockAuthStore.getCurrentAvatarUri(): string | undefined`.
- Produces `MockAuthStore.updateProfileWithAvatar(request: ProfileAvatarUpdateRequest): ProfileAvatarUpdateResult`.
- Internal `MockAccountRecord` gains `avatarUri?: string`; `MockUser` and `AuthSession` remain unchanged.

- [ ] **Step 1: Add failing behavior tests**

Add tests that explicitly log in and cover the required invariants:

```typescript
it('saves and reloads a profile avatar URI without changing the public user contract', 0, () => {
  MockAuthStore.logout();
  MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
  const saved = MockAuthStore.updateProfileWithAvatar({
    nickname: '头像主人', avatarGlyph: '墨', avatarUri: 'file://mock/avatar.jpg'
  });
  expect(saved.success).assertEqual(true);
  expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/avatar.jpg');
  expect(MockAuthStore.getCurrentUser()?.nickname).assertEqual('头像主人');
  expect(MockAuthStore.getCurrentUser()?.avatarGlyph).assertEqual('墨');
  expect(MockAuthStore.getSession().user?.userId).assertEqual('MOCK-ACCOUNT-1');

  MockAuthStore.logout();
  MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
  expect(MockAuthStore.getCurrentAvatarUri()).assertEqual('file://mock/avatar.jpg');
});

it('rejects an empty avatar URI without partially updating the profile', 0, () => {
  const before = MockAuthStore.getCurrentUser();
  const result = MockAuthStore.updateProfileWithAvatar({
    nickname: '不应保存', avatarGlyph: '朱', avatarUri: '   '
  });
  expect(result.success).assertEqual(false);
  expect(result.errorCode).assertEqual('INVALID_AVATAR_URI');
  expect(MockAuthStore.getCurrentUser()?.nickname).assertEqual(before?.nickname);
  expect(MockAuthStore.getCurrentUser()?.avatarGlyph).assertEqual(before?.avatarGlyph);
});
```

Also add tests that logout preserves the URI and successful account closure makes `getCurrentAvatarUri()` return `undefined`.

- [ ] **Step 2: Run the Auth tests to confirm the new behavior fails**

Run the existing entry Auth test command. Expected: compile failure for the missing Store API, before changing Store implementation.

- [ ] **Step 3: Add internal avatar URI storage and atomic Store method**

In `MockAccountRecord`, add `avatarUri?: string`. Add `getCurrentAvatarUri()` by reading the current internal account. Implement `updateProfileWithAvatar()` in this order:

1. Require `currentAccount()`; return `NOT_AUTHENTICATED` on failure.
2. Trim and validate nickname exactly as `updateProfile()` does.
3. Validate the six allowed glyphs exactly as `updateProfile()` does.
4. If `avatarUri` is provided, trim it and reject an empty result with `INVALID_AVATAR_URI`.
5. Only after every check passes, assign nickname, glyph, and optional URI together; when `avatarUri` is `undefined`, retain the account's existing URI; clear closure authorization.
6. Return success without touching AppStorage or `authRevision`.

Keep `updateProfile()` as a compatibility wrapper for callers that do not use photos; it must preserve existing behavior and delegate without changing the frozen request type.

- [ ] **Step 4: Verify logout and closure lifecycle**

Ensure `logout()` only clears the current account/challenges/closure authorization and leaves the account record, including `avatarUri`, intact. Ensure `closeAccount()` removes the account record so a later `getCurrentAvatarUri()` is `undefined`.

- [ ] **Step 5: Run the Auth tests and confirm they pass**

Run the entry Auth test command. Expected: `BUILD SUCCESSFUL` with no Hypium assertion errors.

---

### Task 3: Add PhotoViewPicker flow and profile-page preview/save

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileEditPage.ets`

**Interfaces:**
- Consumes `photoAccessHelper.PhotoViewPicker`, `ProfileAvatarUpdateRequest`, `ProfileAvatarUpdateResult`.
- Uses `MockAuthStore.getCurrentAvatarUri()` and `updateProfileWithAvatar()`.
- Keeps `AuthUiState.bumpRevision()` as the only UI refresh write after successful save.

- [ ] **Step 1: Add page state and picker helper**

Import `photoAccessHelper` from `@kit.MediaLibraryKit`; add `@State avatarUri: string = ''` and a `private async chooseAvatar(): Promise<void>` helper. Configure:

```typescript
const picker = new photoAccessHelper.PhotoViewPicker();
const options = new photoAccessHelper.PhotoSelectOptions();
options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
options.maxSelectNumber = 1;
const result = await picker.select(options);
if (result.photoUris.length > 0) {
  this.avatarUri = result.photoUris[0];
  this.profileError = '';
}
```

On empty result, cancellation, or exception, leave `avatarUri` unchanged and do not call the Store.

- [ ] **Step 2: Load and render the existing URI**

Update `refreshProfile()` to load `MockAuthStore.getCurrentAvatarUri() ?? ''`. Render `Image(this.avatarUri)` in the avatar preview when non-empty; otherwise render the existing glyph. Keep the six glyph selector as the fallback/alternative.

- [ ] **Step 3: Add the upload action in Mask & Seal style**

Add a secondary `SealButton` labeled `从相册上传头像` beneath the preview. Keep the existing “落印保存” primary action and explain in helper text that the choice is saved with the profile.

- [ ] **Step 4: Save the complete profile atomically**

Change `save()` to trim the nickname and call `updateProfileWithAvatar({ nickname, avatarGlyph, avatarUri: this.avatarUri || undefined })`. On failure map `INVALID_AVATAR_URI` to a field error. On success call `AuthUiState.bumpRevision()` exactly once, show the existing success toast, and navigate back.

- [ ] **Step 5: Run `assembleApp` for page compilation**

Run the project-level `assembleApp` command. Expected: ArkTS compilation succeeds; do not invoke `default@BuildArkTS`.

---

### Task 4: Display saved photo avatars in Mine and UserSettings

**Files:**
- Modify: `entry/src/main/ets/components/mine/MinePage.ets`
- Modify: `entry/src/main/ets/pages/UserSettingsPage.ets`

**Interfaces:**
- Consumes `MockAuthStore.getCurrentAvatarUri()` and existing `authRevision` storage refresh.
- Does not change `MockUser`, `AuthSession`, or Store refresh ownership.

- [ ] **Step 1: Add photo-first avatar rendering**

In each page, read `const avatarUri = MockAuthStore.getCurrentAvatarUri()`. Render `Image(avatarUri)` when authenticated and non-empty; otherwise retain the existing glyph `Text` fallback.

- [ ] **Step 2: Keep logout and anonymous behavior unchanged**

Do not show a stale photo after logout. The existing `AuthUiState.bumpRevision()` after confirmed logout must cause the page to rebuild and show the anonymous fallback.

- [ ] **Step 3: Run `assembleApp`**

Run the project-level `assembleApp` command and inspect the ArkTS output for type or route errors.

---

### Task 5: Final verification and handoff

**Files:**
- Verify: all files modified by Tasks 1–4
- Verify: `docs/superpowers/specs/2026-08-17-profile-avatar-upload-design.md`
- Verify: `docs/superpowers/plans/2026-08-17-profile-avatar-upload-implementation.md`

- [ ] **Step 1: Check frozen contracts and permissions**

Run:

```powershell
rg -n "interface MockUser|interface AuthSession|interface ProfileUpdateRequest|READ_IMAGE|WRITE_IMAGE|ohos.permission" entry/src/main/ets entry/src/main/module.json5
```

Expected: no changes to the frozen interfaces and no new photo permission declarations.

- [ ] **Step 2: Run formatting/reference checks**

Run `git diff --check` and confirm no whitespace errors. Confirm new model imports resolve and no unrelated files changed.

- [ ] **Step 3: Run Auth unit tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug test --no-daemon --no-incremental
```

Expected: `BUILD SUCCESSFUL` and no Hypium assertion errors.

- [ ] **Step 4: Run the required project build**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' -p product=default -p buildMode=debug assembleApp --no-daemon --no-incremental
```

Expected: `BUILD SUCCESSFUL`; existing unsigned-project warnings may remain. Do not run `default@BuildArkTS`.

- [ ] **Step 5: Review final diff and hand off**

Confirm no files are staged, no commit or push was created, and report that device/emulator visual selection was not exercised in this environment.
