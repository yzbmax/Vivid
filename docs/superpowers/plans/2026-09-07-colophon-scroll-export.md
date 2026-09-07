# 长卷题跋 · 裱糊海报导出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为作品详情页实现「长卷题跋 · 裱糊海报导出」功能，自动提取中国传统五色谱，合成东方装裱立轴长图，并通过 SaveButton 安全控件免弹窗直存相册。

**Architecture:** 
1. `TraditionalColorCatalog` 提供 40+ 传统国色字典及颜色距离匹配算法；
2. `ColorPaletteExtractor` 采样图像并提取主色调；
3. `ColophonScrollRenderer` 负责长卷装裱排版与离屏 Canvas / 图像合成；
4. `ColophonExportDialog` 提供沉浸式长卷浮层预览、品级印章切换与 SaveButton 一键落印直存。

**Tech Stack:** HarmonyOS ArkTS, ArkUI, `@kit.ImageKit`, `@kit.PhotoAccessHelper`, SaveButton 安全控件, 离屏 Canvas.

## Global Constraints
- 严格遵循 ArkTS 静态类型规范：禁止普通对象展开 `{ ...obj }`，禁止匿名对象字面量作为类型；
- 在用户没有明确下达 git 指令前，严禁执行 git commit 或 git push；
- 遵循 WCAG 4.5:1 色彩对比度与 EdgeEffect.Spring 弹性滚动动效。

---

### Task 1: 中国传统色彩字典与主色提取算法 (TraditionalColorCatalog & ColorPaletteExtractor)

**Files:**
- Create: `entry/src/main/ets/models/ColophonModels.ets`
- Create: `entry/src/main/ets/models/TraditionalColorCatalog.ets`
- Create: `entry/src/main/ets/services/ColorPaletteExtractor.ets`
- Test: `tools/test-color-palette.cjs`

- [ ] **Step 1: 编写色谱测试用例 (Red Phase)**
- [ ] **Step 2: 运行测试确认失败**
- [ ] **Step 3: 实现 ColophonModels.ets、TraditionalColorCatalog.ets 与 ColorPaletteExtractor.ets**
- [ ] **Step 4: 运行测试确认 100% PASS**

---

### Task 2: 题跋长卷离屏渲染器 (ColophonScrollRenderer)

**Files:**
- Create: `entry/src/main/ets/services/ColophonScrollRenderer.ets`
- Test: `tools/test-colophon-renderer.cjs`

- [ ] **Step 1: 编写题跋长卷装裱排版与渲染计算测试用例**
- [ ] **Step 2: 运行测试确认失败**
- [ ] **Step 3: 实现 ColophonScrollRenderer.ets (动态计算天头、画心、隔水、色谱、题跋、印章布局)**
- [ ] **Step 4: 运行测试确认 100% PASS**

---

### Task 3: 题跋弹窗组件与 SaveButton 免弹窗直存 (ColophonExportDialog)

**Files:**
- Create: `entry/src/main/resources/base/media/icon_scroll.svg`
- Create: `entry/src/main/ets/components/common/ColophonExportDialog.ets`
- Modify: `entry/src/main/ets/pages/WorkDetailPage.ets`
- Test: `tools/test-colophon-export-flow.cjs`

- [ ] **Step 1: 编写组件规范与交互流测试用例**
- [ ] **Step 2: 运行测试确认失败**
- [ ] **Step 3: 创建 icon_scroll.svg 与 ColophonExportDialog.ets，并在 WorkDetailPage.ets 接入入口**
- [ ] **Step 4: 运行全量测试套件确认全部通过**
