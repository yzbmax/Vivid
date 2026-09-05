# Mock Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成开发者 A 的 Mock 登录闭环：验证码/密码登录、注册建会话、登录态“我的”页、用户设置资料和退出登录。

**Architecture:** `MockAuthStore` 在进程内维护密码账户、最近一次手机号验证码和显式 `AuthSession`；页面只调用 Store，不访问内部数组。登录/退出通过 `AppStorage` 的 `authRevision` 触发 `MinePage` 与 `UserSettingsPage` 重读 Store，真实认证状态仍以 `AuthSession` 为准。

**Tech Stack:** HarmonyOS 6.1.1（API 24）、ArkTS、ArkUI、现有 `AuthValidators`、Mask & Seal 组件、Hypium 单元测试、Hvigor `assembleApp`。

## Global Constraints

- 不接真实短信、账号中心、网络请求、Preferences、云存储或第三方登录。
- 演示验证码固定为 `123456`；演示密码账号为 `13800138000 / Vivid123`。
- 验证码记录请求手机号；登录/注册同时校验手机号和验证码。
- 未注册手机号验证码登录只建立本进程临时会话，不加入密码账户表；注册仍可使用该手机号。
- Store 不记录手机号、验证码或密码日志；页面标注“演示数据”。
- 不修改 `EditModels.ets`、`WorkRecord.ets`、作品、首页、编辑页和底部 Tab 框架。
- 不新增第三方依赖，不升级 SDK，不修改构建系统。
- 构建验证只使用 `assembleApp`；禁止执行 `default@BuildArkTS`。
- 每次提交只暂存本任务相关文件，不自动推送。

---

### Task 1: Extend the frozen authentication contract

**Files:**
- Modify: `entry/src/main/ets/models/AuthModels.ets`

**Interfaces:**
- Produces `AuthStatus = 'anonymous' | 'authenticated'`.
- Produces `AuthSession { status: AuthStatus; user?: MockUser }`.
- Keeps the existing `MockUser` fields unchanged.

- [ ] **Step 1: Add explicit session types**

Append the following exports after `MockUser`; do not rename or remove any existing field:

```typescript
export type AuthStatus = 'anonymous' | 'authenticated';

export interface AuthSession {
  status: AuthStatus;
  user?: MockUser;
}
```

- [ ] **Step 2: Verify the contract text**

Run:

```powershell
Select-String -Path 'entry/src/main/ets/models/AuthModels.ets' -Pattern 'export type AuthStatus|export interface AuthSession|export interface MockUser'
git diff --check
```

Expected: exactly one match for each export and no diff-check error.

- [ ] **Step 3: Commit the contract change**

```powershell
git add -- 'entry/src/main/ets/models/AuthModels.ets'
git commit -m "feat(auth): add explicit mock session contract"
```

### Task 2: Write failing MockAuthStore tests

**Files:**
- Create: `entry/src/test/MockAuthStore.test.ets`
- Modify: `entry/src/test/List.test.ets`

**Interfaces:**
- Consumes the Task 1 `AuthSession` contract.
- Expects `MockAuthStore` to export `requestCode`, `loginWithCode`, `loginWithPassword`, `register`, `getSession`, `getCurrentUser`, and `logout`.
- Expects result fields `success`, `session`, optional `demoCode`, and optional `errorCode`.

- [ ] **Step 1: Add the failing test suite**

Create the Hypium suite below. Use distinct phone numbers in each test so tests do not depend on execution order; call `MockAuthStore.logout()` at the start of each case.

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MockAuthStore } from '../main/ets/models/MockAuthStore';

export default function mockAuthStoreTest() {
  describe('mockAuthStoreTest', () => {
    it('binds a demo code to the requested phone', 0, () => {
      MockAuthStore.logout();
      const requested = MockAuthStore.requestCode('13912345678');
      expect(requested.success).assertEqual(true);
      expect(requested.demoCode).assertEqual('123456');

      const switchedPhone = MockAuthStore.loginWithCode('13912345679', '123456');
      expect(switchedPhone.success).assertEqual(false);
      expect(switchedPhone.errorCode).assertEqual('CODE_PHONE_MISMATCH');
    });

    it('logs in with the seeded demo password account', 0, () => {
      MockAuthStore.logout();
      const result = MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      expect(result.success).assertEqual(true);
      expect(result.session.status).assertEqual('authenticated');
      expect(result.session.user?.maskedPhone).assertEqual('138****8000');
    });

    it('uses one generic error for invalid password credentials', 0, () => {
      MockAuthStore.logout();
      const result = MockAuthStore.loginWithPassword('13800138000', 'Wrong123');
      expect(result.success).assertEqual(false);
      expect(result.errorCode).assertEqual('INVALID_CREDENTIALS');
    });

    it('registers a password account and creates a session', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.requestCode('13912345670');
      const result = MockAuthStore.register('13912345670', '123456', 'abc12345');
      expect(result.success).assertEqual(true);
      expect(result.session.status).assertEqual('authenticated');
      expect(MockAuthStore.getCurrentUser()?.maskedPhone).assertEqual('139****5670');
    });

    it('rejects a duplicate registered phone', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.requestCode('13912345671');
      const first = MockAuthStore.register('13912345671', '123456', 'abc12345');
      expect(first.success).assertEqual(true);
      MockAuthStore.logout();
      MockAuthStore.requestCode('13912345671');
      const duplicate = MockAuthStore.register('13912345671', '123456', 'abc12345');
      expect(duplicate.success).assertEqual(false);
      expect(duplicate.errorCode).assertEqual('PHONE_ALREADY_REGISTERED');
    });

    it('returns an anonymous session after logout', 0, () => {
      MockAuthStore.logout();
      MockAuthStore.loginWithPassword('13800138000', 'Vivid123');
      MockAuthStore.logout();
      expect(MockAuthStore.getSession().status).assertEqual('anonymous');
      expect(MockAuthStore.getCurrentUser()).assertUndefined();
    });
  });
}
```

Append `import mockAuthStoreTest from './MockAuthStore.test';` and `mockAuthStoreTest();` to `entry/src/test/List.test.ets` after the existing validator suite.

- [ ] **Step 2: Run the test suite and verify the expected failure**

Run the repository's unit-test task for the entry module:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'; $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path; & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug test --no-daemon --no-incremental
```

Expected: a compile failure because `MockAuthStore.ets` does not exist yet; do not change the test to make this failure disappear.

- [ ] **Step 3: Commit the failing tests**

```powershell
git add -- 'entry/src/test/MockAuthStore.test.ets' 'entry/src/test/List.test.ets'
git commit -m "test(auth): specify mock session behavior"
```

### Task 3: Implement MockAuthStore

**Files:**
- Create: `entry/src/main/ets/models/MockAuthStore.ets`

**Interfaces:**
- Consumes `AuthSession`, `AuthStatus`, and `MockUser` from `AuthModels.ets`.
- Consumes `validatePhone` and `validatePassword` from `utils/AuthValidators.ets`.
- Produces the Store methods and result objects used by Tasks 2, 4, and 5.

- [ ] **Step 1: Implement the result and account types**

Define these exports and internal fields:

```typescript
export type AuthErrorCode = 'INVALID_PHONE' | 'INVALID_PASSWORD' | 'CODE_NOT_REQUESTED' |
  'CODE_PHONE_MISMATCH' | 'INVALID_CODE' | 'INVALID_CREDENTIALS' | 'PHONE_ALREADY_REGISTERED';

export interface RequestCodeResult {
  success: boolean;
  demoCode?: string;
  errorCode?: AuthErrorCode;
}

export interface AuthResult {
  success: boolean;
  session: AuthSession;
  errorCode?: AuthErrorCode;
}
```

Keep `MockUserAccount` private with `phone`, `password`, and the four `MockUser` display fields. Seed only `13800138000 / Vivid123`.

- [ ] **Step 2: Implement code request and session accessors**

`requestCode(phone)` rejects an invalid phone with `INVALID_PHONE`; otherwise stores the exact phone and `123456`, then returns `{ success: true, demoCode: '123456' }`. `getSession()` returns a copy of the current session. `getCurrentUser()` returns the session user or `undefined`; callers cannot mutate the Store's internal object.

- [ ] **Step 3: Implement code and password login**

`loginWithCode(phone, code)` must check, in order: no pending request (`CODE_NOT_REQUESTED`), different phone (`CODE_PHONE_MISMATCH`), wrong code (`INVALID_CODE`), then authenticate. Existing password accounts reuse their display user; unknown valid phones receive a temporary display user without entering the password account table.

`loginWithPassword(phone, password)` compares only the password account table and returns `INVALID_CREDENTIALS` for every mismatch, without distinguishing missing account from wrong password.

- [ ] **Step 4: Implement registration and logout**

`register(phone, code, password)` checks phone format, password format, duplicate account phone, pending code, phone binding, and code value. On success append one account, authenticate it, and clear the pending code. `logout()` resets the session to anonymous and clears pending code.

- [ ] **Step 5: Implement revision notification**

After successful authentication and logout, increment a private revision and call `AppStorage.setOrCreate('authRevision', revision)`. Do not put phone, password, or code into AppStorage.

- [ ] **Step 6: Run Store tests to verify green**

Run the same `test` command from Task 2. Expected: the new `MockAuthStore` tests and existing validator tests pass; any failure must be fixed in production code, not in test expectations.

- [ ] **Step 7: Commit the Store**

```powershell
git add -- 'entry/src/main/ets/models/MockAuthStore.ets'
git commit -m "feat(auth): add mock session store"
```

### Task 4: Connect LoginPage

**Files:**
- Modify: `entry/src/main/ets/pages/LoginPage.ets`

**Interfaces:**
- Consumes `MockAuthStore`, `AuthErrorCode`, and existing validators.
- Produces successful code/password login followed by router back to the source page.

- [ ] **Step 1: Add page state for demo-code display and countdown**

Add `@State demoCode: string = ''`, `@State codeCountdown: number = 0`, and a page-local timer handle. Add a `startCodeCountdown()` helper that decrements once per second, clears itself at zero, and is cleared in `aboutToDisappear()`.

- [ ] **Step 2: Wire requestCode to the Store**

Keep the existing `validatePhone` field error. On valid phone call `MockAuthStore.requestCode(this.phone)`, display `演示验证码：123456`, set countdown to 60, and disable the request button while countdown is positive. Do not store countdown in `MockAuthStore`.

- [ ] **Step 3: Wire submit to code/password login**

Retain mode-specific format validation. For code mode call `loginWithCode`; for password mode call `loginWithPassword`. Map `CODE_NOT_REQUESTED`, `CODE_PHONE_MISMATCH`, `INVALID_CODE`, and `INVALID_CREDENTIALS` to the agreed Chinese field messages. On success call the existing `goBack()` method and show no success Toast.

- [ ] **Step 4: Render the demo marker and countdown**

Place the demo-code text under the code field only when `demoCode` is non-empty. Change the request button label to `重发 ${codeCountdown}s` while disabled and `获取验证码` otherwise. Keep all existing Mask & Seal styling.

- [ ] **Step 5: Run the targeted tests and inspect the diff**

Run the `test` command from Task 2 and `git diff --check`. Expected: Store and validator tests pass; no unrelated files change.

- [ ] **Step 6: Commit the LoginPage wiring**

```powershell
git add -- 'entry/src/main/ets/pages/LoginPage.ets'
git commit -m "feat(auth): connect login flows"
```

### Task 5: Connect RegisterPage

**Files:**
- Modify: `entry/src/main/ets/pages/RegisterPage.ets`

**Interfaces:**
- Consumes `MockAuthStore.register` and `MockAuthStore.requestCode`.
- Produces registration success, duplicate-phone errors, and automatic session creation.

- [ ] **Step 1: Add the same page-local demo-code countdown state**

Mirror the LoginPage timer lifecycle without moving timer state into the Store.

- [ ] **Step 2: Wire registration code request**

Replace the placeholder Toast with Store request handling, demo-code text, and the disabled 60-second button state.

- [ ] **Step 3: Wire submit to registration**

Run existing phone/code/password/confirmation/agreement checks first. If they pass, call `MockAuthStore.register(this.phone, this.code, this.password)`. Map `PHONE_ALREADY_REGISTERED` to `该手机号已注册`; map code errors to the code field. On success call `goBack()`.

- [ ] **Step 4: Run tests and commit**

Run the entry `test` task and `git diff --check`. Then commit only this page:

```powershell
git add -- 'entry/src/main/ets/pages/RegisterPage.ets'
git commit -m "feat(auth): connect registration flow"
```

### Task 6: Render authenticated Mine and Settings states

**Files:**
- Modify: `entry/src/main/ets/components/mine/MinePage.ets`
- Modify: `entry/src/main/ets/pages/UserSettingsPage.ets`

**Interfaces:**
- Consumes `AuthSession`, `MockAuthStore.getSession()`, `MockAuthStore.logout()`, and `authRevision` AppStorage notification.
- Produces authenticated user cards, masked phone display, demo markers, and in-place logout.

- [ ] **Step 1: Add revision subscriptions**

Add `@StorageProp('authRevision') authRevision: number = 0` to both components. Reference the property during `build()` and read `MockAuthStore.getSession()` for the actual render state.

- [ ] **Step 2: Implement MinePage anonymous/authenticated branches**

Keep the existing anonymous login/register card. For `authenticated`, render the session user's `avatarGlyph`, `nickname`, masked phone, and `演示数据`, hide login/register buttons, and show a logout button. Logout calls the Store and leaves the page mounted.

- [ ] **Step 3: Implement UserSettingsPage session-aware content**

Replace the fixed “未登录” profile card with the same session-aware user display. Anonymous users retain the login entry; authenticated users see the masked account and logout action. Remove copy claiming settings never save; state that this is process-local demo data.

- [ ] **Step 4: Run tests and inspect only the two page diffs**

Run the entry `test` task and `git diff --check`. Expected: existing tests and Store tests pass; no changes to `Index.ets` or unrelated settings pages.

- [ ] **Step 5: Commit the user-state pages**

```powershell
git add -- 'entry/src/main/ets/components/mine/MinePage.ets' 'entry/src/main/ets/pages/UserSettingsPage.ets'
git commit -m "feat(auth): render authenticated user state"
```

### Task 7: Integrate and verify the A-scope package

**Files:**
- Modify: `entry/src/test/List.test.ets` only if the test registration was not committed in Task 2.

- [ ] **Step 1: Review the complete diff and references**

Run:

```powershell
git status --short
git diff HEAD~6..HEAD --check
rg -n 'AuthModels|MockAuthStore|authRevision|default@BuildArkTS' entry/src/main entry/src/test
```

Expected: only the planned auth files are changed; no `default@BuildArkTS` invocation appears in implementation scripts or new docs.

- [ ] **Step 2: Run the focused unit-test task**

Run the entry `test` command from Task 2 and record the actual pass/fail output. If it fails, stop and fix the relevant task before building.

- [ ] **Step 3: Run the requested application assembly**

Use the project's Hvigor wrapper with the `assembleApp` task:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'; $env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path; & 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug assembleApp --no-daemon --no-incremental
```

Expected: the assemble task completes without the prior `default@BuildArkTS` login/sourcemap failure. Do not generate or claim a HAP artifact.

- [ ] **Step 4: Final status check**

Run `git status --short`, `git branch --show-current`, and `git log --oneline -8`. Report the exact commits, whether `XYW` is ahead of `origin/XYW`, and any device-only verification still outstanding. Do not push automatically.
