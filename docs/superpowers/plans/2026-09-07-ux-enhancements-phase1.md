# 微霏（Vivid）修图体验全方位升级方案（第一阶段）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为微霏（Vivid）引入旗舰级交互手感与专业修图工作流：触感微震动反馈、双击滑块归零、全局长按原图对比浮标、调色配方跨照片复制粘贴、单步撤销与重做历史栈。

**Architecture:** 纯端侧轻量化设计，解耦独立服务与状态机（`HapticService`、`ColorRecipeStore`、`EditHistoryManager`），零外部网络依赖，严格保证内存与渲染性能，完全符合 ArkTS 与 HarmonyOS NEXT 规范。

**Tech Stack:** ArkTS, ArkUI, `@kit.SensorServiceKit` (vibrator), AppStorage, 矢量 SVG 图标.

---

## 全局约束与规范
- 样式必须严格符合「炎国卷轴 · 文书钤印」（Mask & Seal）美学规范；
- 震动调用必须具备防崩溃与降级机制（模拟器与无马达设备静默忽略）；
- 历史栈与配方存储必须纯轻量数据结构（仅记录数值参数与滤镜 ID，杜绝拷贝位图）；
- 动效与色彩对比度必须 100% 保持现有测试通过（WCAG 4.5:1 与 Spring 动效）。

---

### Task 1: 触感反馈与滑块归零优化 (`HapticService` & Double-tap reset)

**Files:**
- Create: `entry/src/main/ets/services/HapticService.ets`
- Modify: `entry/src/main/module.json5`
- Modify: `entry/src/main/ets/components/editor/AdjustPanel.ets`
- Modify: `entry/src/main/ets/components/editor/FilterPanel.ets`
- Test: `tools/test-haptic-and-reset.cjs`

**Interfaces:**
- `HapticService.triggerTick()`: 滑块经过 0 刻度、吸附或快速切换时的轻微顿挫震动
- `HapticService.triggerImpact()`: 双击归零、落印或完成操作的确认震动
- `AdjustPanel`: 数值双击重置为 0，经过 0 刻度时调用 `triggerTick()`
- `FilterPanel`: 滤镜强度双击重置为 1.0 (100%)

- [ ] **Step 1: 编写失败测试用例**
- [ ] **Step 2: 声明权限并在 HapticService 中实现防崩震动封装**
- [ ] **Step 3: 在 AdjustPanel 与 FilterPanel 接入 0 刻度震动与双击归零**
- [ ] **Step 4: 运行测试并验证通过**

---

### Task 2: 全局长按对比浮标 (`GlobalCompareOverlay`)

**Files:**
- Modify: `entry/src/main/ets/components/editor/PreviewArea.ets`
- Modify: `entry/src/main/ets/pages/EditPage.ets`
- Test: `tools/test-compare-overlay.cjs`

**Interfaces:**
- 移除 `PreviewArea` 画布全域 touch 触发对比（解决误触闪烁问题）；
- 在预览区右上角增加精美半透明朱砂印章样式的「对比」微型悬浮按钮；
- 按下（`TouchType.Down`）触发 `isComparing = true`，松手或移出（`TouchType.Up / TouchType.Cancel`）触发 `isComparing = false`；
- 原图显示时带有优雅的文人印章微章提示（“原图”）。

- [ ] **Step 1: 编写失败测试用例**
- [ ] **Step 2: 在 PreviewArea 增加悬浮对比按钮并解绑画布全域 touch**
- [ ] **Step 3: 运行测试并验证通过**

---

### Task 3: 调色配方「复制 / 粘贴」 (`ColorRecipeStore`)

**Files:**
- Create: `entry/src/main/ets/models/ColorRecipe.ets`
- Create: `entry/src/main/ets/services/ColorRecipeStore.ets`
- Modify: `entry/src/main/ets/pages/EditPage.ets`
- Modify: `entry/src/main/ets/pages/WorkDetailPage.ets`
- Test: `tools/test-recipe-store.cjs`

**Interfaces:**
- `ColorRecipeStore.copyRecipe(name: string, adjustments: AdjustParams, filterId: string, filterStrength: number, regionAdjustments?: RegionAdjustParams): void`
- `ColorRecipeStore.hasRecipe(): boolean`
- `ColorRecipeStore.pasteRecipe(): ColorRecipe | undefined`
- `EditPage`: 增加“复制配方”与“粘贴配方”快捷按钮与应用逻辑
- `WorkDetailPage`: 卷宗详情操作区增加“复制此卷配方”

- [ ] **Step 1: 编写失败测试用例**
- [ ] **Step 2: 实现 ColorRecipe 数据模型与 ColorRecipeStore 本地持久化**
- [ ] **Step 3: 在 EditPage 与 WorkDetailPage 接入配方复制/粘贴**
- [ ] **Step 4: 运行测试并验证通过**

---

### Task 4: 单步撤销 / 重做历史栈 (`EditHistoryManager`)

**Files:**
- Create: `entry/src/main/ets/models/EditHistoryManager.ets`
- Create: `entry/src/main/resources/base/media/icon_undo.svg`
- Create: `entry/src/main/resources/base/media/icon_redo.svg`
- Modify: `entry/src/main/ets/pages/EditPage.ets`
- Test: `tools/test-undo-redo.cjs`

**Interfaces:**
- `EditHistoryManager`: 最大深度 15 步，支持 `push`、`undo`、`redo`、`canUndo`、`canRedo`
- `EditPage` 顶部栏左侧（返回键旁）增加撤销与重做图标按钮，状态动态联动
- 在滑块调节结束（`SliderChangeMode.End`）及滤镜切换时自动记入历史栈

- [ ] **Step 1: 编写失败测试用例**
- [ ] **Step 2: 创建 icon_undo.svg 与 icon_redo.svg 并实现 EditHistoryManager**
- [ ] **Step 3: 在 EditPage 顶部栏接入撤销与重做操作并与状态同步**
- [ ] **Step 4: 运行全量测试并验证通过**
