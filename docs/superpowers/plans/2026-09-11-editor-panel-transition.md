# 底部编辑栏两档高度收敛与物理弹簧平滑过渡实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 解决独立调色编辑页 (`EditPage.ets`) 切换 7 种功能 Tab 时底栏高度大幅突变、生硬顶撞画芯的体验痛点，建立“两档阶梯收敛 + 物理弹簧阻尼动画”的专业级影像编辑交互体系。

**Architecture:** 
1. 将 7 个工具的高度混乱收敛为两档：轻量调节档（138vp：调节、滤镜、区域）与综合配置档（248vp：边框、贴纸、文字）；
2. 外层动效容器通过 ArkUI `curves.springMotion(0.35, 0.82)` 驱动高度弹性缩放与 `.clip(true)` 防溢出；
3. 内部面板配合轻量淡入淡出（Crossfade），上方画芯随 `layoutWeight(1)` 伴随弹簧平滑推拉变焦。

**Tech Stack:** HarmonyOS ArkTS, ArkUI Declarative UI, `@ohos.curves` / `curves.springMotion`, Node.js.

**Spec:** docs/superpowers/specs/2026-09-11-editor-panel-transition-design.md

## Global Constraints
- 遵循 ArkTS 严格强类型约束，严禁使用 `any` 或 `as any`；
- 遵循 ArkUI 响应式状态管理规范与组件化原则；
- 严禁影响现有的滤镜渲染、EXIF 提取、边框绘制、贴纸拖拽等核心图像能力；
- 确保所有测试通过，无语法错误与运行时报警。

---

### Task 1: 建立编辑器高度规范与解析纯函数

**Files:**
- Modify: `entry/src/main/ets/models/EditModels.ets`
- Create: `tools/test-editor-panel-transition.cjs`

- [ ] **Step 1: 编写失败的专项测试用例**
- [ ] **Step 2: 运行测试验证失败**
- [ ] **Step 3: 在 EditModels.ets 中定义常量与纯函数**
- [ ] **Step 4: 重新运行测试验证通过**

### Task 2: 面板内部尺寸优化契约适配

**Files:**
- Modify: `entry/src/main/ets/components/editor/FilterPanel.ets`
- Modify: `entry/src/main/ets/components/editor/AdjustPanel.ets`
- Modify: `entry/src/main/ets/components/editor/BorderPanel.ets`
- Modify: `entry/src/main/ets/components/editor/StickerPanel.ets`
- Modify: `entry/src/main/ets/components/editor/TextPanel.ets`

- [ ] **Step 1: 调整 FilterPanel 尺寸适配 138vp**
- [ ] **Step 2: 调整 AdjustPanel 呼吸间距居中适配 138vp**
- [ ] **Step 3: 规整 BorderPanel 控件总高与边距适配 248vp**
- [ ] **Step 4: 规整 StickerPanel 选中/未选中态占位适配 248vp**
- [ ] **Step 5: 规整 TextPanel 最大高度与内部滚动适配 248vp**

### Task 3: EditPage 挂载弹簧动效容器与内容过渡

**Files:**
- Modify: `entry/src/main/ets/pages/EditPage.ets`

- [ ] **Step 1: 引入 curves 模块并声明状态变量**
- [ ] **Step 2: 包裹动效容器挂载 springMotion 动画与 clip 裁剪**
- [ ] **Step 3: 绑定 onToolSelect 高度联动与内容渐变**
- [ ] **Step 4: 运行全量测试验证**
