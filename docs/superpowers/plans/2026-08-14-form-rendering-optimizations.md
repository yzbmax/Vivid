# Form Rendering Optimizations Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce avoidable ArkUI node and allocation work while preserving all current features, animations, navigation, validation, and visual output.

**Architecture:** Keep form state where it is because ArkUI already refreshes only UI nodes that depend on changed `@State` values. Replace stateless presentation-only custom components with global `@Builder` functions to avoid unnecessary `CustomNode` instances, while retaining the stateful Canvas background component. Hoist immutable agreement content to module scope so `build()` reuses stable arrays.

**Tech Stack:** ArkTS, ArkUI declarative components, Hypium, DevEco Studio Code Linter/Hvigor.

---

### Task 1: Establish a performance-rule baseline

**Files:**
- Inspect: `entry/src/main/ets/pages/LoginPage.ets`
- Inspect: `entry/src/main/ets/pages/RegisterPage.ets`
- Inspect: `entry/src/main/ets/components/MaskSeal.ets`

- [x] Confirm from the official `@State` documentation that unrelated UI descriptions are not re-rendered when state changes.
- [x] Run DevEco Code Linter with the repository's performance rules.
- [x] Reject form-component splitting because it would add `CustomNode` instances without reducing the existing state-dependent refresh scope.

### Task 2: Replace stateless custom nodes with builders

**Files:**
- Modify: `entry/src/main/ets/components/MaskSeal.ets`
- Inspect: all call sites under `entry/src/main/ets`

- [x] Convert `SealPageHeader`, `SealButton`, `FloatingInput`, and `SettingRow` to global `@Builder` functions using equivalent parameter objects.
- [x] Preserve every style modifier, callback, default value, and existing call-site behavior.
- [x] Keep `SealPaperBackground` as the user's stateful Canvas custom component and do not edit its implementation.

### Task 3: Reuse immutable agreement data

**Files:**
- Modify: `entry/src/main/ets/pages/UserAgreementPage.ets`
- Modify: `entry/src/main/ets/pages/PrivacyPolicyPage.ets`
- Inspect: `entry/src/main/ets/components/AgreementPage.ets`

- [x] Hoist each immutable section array to module scope and pass the stable reference into `AgreementPage`.
- [x] Confirm `AgreementPage` keeps its existing stable `ForEach` key function.

### Task 4: Verify the focused refactor

**Files:**
- Inspect: the four modified page files and `entry/src/main/ets/components/AgreementPage.ets`

- [x] Run the narrowest available ArkTS static/lint task for the entry module.
- [x] Run a source-only ArkTS compile check without packaging; ArkTS diagnostics are clean, but DevEco's sourcemap generator crashes afterward because its internal `rollupObject` is undefined.
- [x] Re-run DevEco Code Linter and compare the focused warnings with the baseline of six warnings.
- [x] Review the final diff and confirm the `SealPaperBackground` implementation and unrelated files were not modified by this optimization.
- [x] Report the verification limitation without claiming simulator or visual validation.
