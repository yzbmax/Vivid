# 通用摄影水印边框套件（4 大通用版式）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Vivid 中实现 4 款高品质、与具体品牌彻底解耦的通用摄影水印边框模板（居中阶梯全参、画中画弥散卡片、同调画报·瞬间、极简键值标尺），支持全品牌相机与手机自适应装配、画面主色动态联动取色与全链路离屏/实时渲染。

**Architecture:** 
- **数据契约层**：扩展 `WatermarkConfig`，补充通用 GPS 坐标、人文副标、顶部题签等可选字段；
- **几何与元数据层**：在 `BorderCatalog` 注册模板元数据，在 `BorderLayoutResolver` 统一计算外扩画布尺寸、照片放置区域 `photoRect` 与安全留白；
- **Canvas 渲染引擎**：在 `BorderPainter` 实现 4 款通用模板的高精度排版、防撞检测与多品牌 Logo 去重适配；
- **动态联动与预览合成**：在 `BorderCompositionService` 和 `PreviewArea` 中实现画面主色提取调和与画中画高斯弥散双端一致性渲染；
- **UI 呈现层**：在 `BorderTemplatePickerModal` 与 `BorderPanel` 提供高质量微缩效果卡片。

**Tech Stack:** HarmonyOS ArkTS, ArkUI, CanvasRenderingContext2D, OffscreenCanvasRenderingContext2D, Node.js 测试驱动。

**Spec:** 由用户提供的 5 款精选水印边框（居中悬浮徕卡全参、富士弥散卡片、OPPO决定性瞬间画报、哈苏极简键值对、索尼弥散卡片）归纳提炼的通用摄影美学设计规范。

## Global Constraints
- 遵循 ArkTS 严格模式与强类型约束（严禁使用 `any`，闭包与箭头函数必须有显式返回类型）。
- 遵循 Vivid 画幅自适应与防撞检测规范（严禁文字出界碰撞，竖屏窄画幅具备优雅降级策略）。
- 版式与品牌彻底解耦：所有模板必须支持任意相机/手机品牌 Logo 或关闭 Logo，机型与参数支持自由编辑与 EXIF 自动填充。
- 画面色彩联动：【同调画报】边框底色默认自动萃取画面基调色，并支持用户在调色时实时联动与手动覆盖。

---

### Task 1: 扩展水印通用数据契约与模板元数据注册

**Files:**
- Modify: `entry/src/main/ets/models/SharedContracts.ets`
- Modify: `entry/src/main/ets/features/editor/border/BorderCatalog.ets`
- Modify: `entry/src/main/ets/features/editor/border/BorderState.ets`
- Test: `tools/test-universal-watermark-borders.cjs`

- [ ] **Step 1: 编写契约与元数据测试用例**
- [ ] **Step 2: 运行测试并验证失败**
- [ ] **Step 3: 编写契约与元数据实现**
- [ ] **Step 4: 运行测试并验证通过**
- [ ] **Step 5: 提交契约与元数据改动**

---

### Task 2: 边框几何解析器实现（BorderLayoutResolver）

**Files:**
- Modify: `entry/src/main/ets/features/editor/border/BorderLayoutResolver.ets`
- Test: `tools/test-universal-watermark-borders.cjs`

- [ ] **Step 1: 编写几何计算单元测试**
- [ ] **Step 2: 运行测试并验证失败**
- [ ] **Step 3: 编写几何计算函数**
- [ ] **Step 4: 运行测试并验证通过**
- [ ] **Step 5: 提交几何解析器改动**

---

### Task 3: Canvas 高精度排版与绘制引擎实现（BorderPainter）

**Files:**
- Modify: `entry/src/main/ets/features/editor/border/BorderPainter.ets`
- Test: `tools/test-universal-watermark-borders.cjs`

- [ ] **Step 1: 编写绘制逻辑与防碰撞断言测试**
- [ ] **Step 2: 运行测试并验证失败**
- [ ] **Step 3: 编写绘制引擎代码**
- [ ] **Step 4: 运行测试并验证通过**
- [ ] **Step 5: 提交绘制引擎改动**

---

### Task 4: 色彩动态联动提取与双端合成集成（BorderCompositionService & PreviewArea）

**Files:**
- Modify: `entry/src/main/ets/services/BorderCompositionService.ets`
- Modify: `entry/src/main/ets/components/editor/PreviewArea.ets`
- Test: `tools/test-universal-watermark-borders.cjs`

- [ ] **Step 1: 编写合成服务与色彩联动测试**
- [ ] **Step 2: 运行测试并验证失败**
- [ ] **Step 3: 编写色彩联动与合成逻辑**
- [ ] **Step 4: 运行测试并验证通过**
- [ ] **Step 5: 提交色彩联动与合成改动**

---

### Task 5: UI 面板与全屏模版选择器视觉微缩卡片（BorderPanel & PickerModal）

**Files:**
- Modify: `entry/src/main/ets/components/editor/BorderPanel.ets`
- Modify: `entry/src/main/ets/components/editor/BorderTemplatePickerModal.ets`
- Test: `tools/test-universal-watermark-borders.cjs`

- [ ] **Step 1: 编写 UI 渲染组件完整性测试**
- [ ] **Step 2: 运行测试并验证失败**
- [ ] **Step 3: 编写 UI 缩略组件与交互逻辑**
- [ ] **Step 4: 运行测试并验证通过**
- [ ] **Step 5: 提交 UI 呈现改动**

---

### Task 6: 全链路回归验证与端到端压测验收

**Files:**
- Test: `tools/test-universal-watermark-borders.cjs`
- Test: `tools/test-mint-postcard-watermarks.cjs`
- Test: `tools/test-watermark-anti-collision-stress.cjs`
- Test: `tools/test-watermark-logo-deduplication.cjs`

- [ ] **Step 1: 运行全套边框与水印自动化测试集**
- [ ] **Step 2: 静态代码检查与 ArkTS 严格模式核查**
- [ ] **Step 3: 最终成果提交**
