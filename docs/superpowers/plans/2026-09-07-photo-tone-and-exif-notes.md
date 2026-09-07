# 照片直方图明暗分析与 EXIF 案卷批注生成器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 针对作品详情页与保存流程，实现基于**真实照片直方图明暗特征（5 大光影品格）**、**极端曝光诊断与修润建议**以及 **EXIF 拍摄时间与光学参数**的动态古风案卷批注生成系统，彻底替换死板固定的模板套话。

**Architecture:** 
1. `ImageToneModels.ets` 定义直方图指标、5 种明暗调性枚举（`ToneCategory`）、直方图统计（`ToneMetrics`）与官署校勘诊断（`AuditDiagnosis`）；
2. `ImageToneAnalyzer.ets` 提供纯数学样本直方图聚类、调性推导、极端异常判定（高光死白、暗部死黑、极端大光比、灰雾乏力）与参数调整建议计算，以及基于 `@kit.ImageKit` 的微缩略图极速采样实现；
3. `WorkDescriptionGenerator.ets` 升级为支持 `DescriptionContext`（时间岁时物候、镜头光圈快门、直方图明暗、极端校勘建议、调色参数），兼顾多层优雅降级与全向兼容；
4. `NotesCard.ets` 与 `WorkDetailPage.ets` 完成 UI 渲染整合，呈现调性印记与官署校勘便签。

**Tech Stack:** HarmonyOS ArkTS, ArkUI, `@kit.ImageKit`, Node.js 离线验证套件.

## Global Constraints
- 严格遵循 ArkTS 静态类型规范：禁止普通对象展开 `{ ...obj }`，禁止以任意匿名对象字面量越过类型约束；
- 遵循「炎国卷轴 · 文书钤印」设计语言（Serif 衬线题头、朱砂强调色、便签印记与典雅骈体文风）；
- 极端直方图诊断必须给出可操作的调色建议（明确指向调整参数名，如曝光、阴影、对比度及推荐增减量）；
- 所有图像分析在无法读取或异常时必须优雅降级（Graceful Fallback），严禁页面白屏或未捕获异常。

---

### Task 1: 直方图明暗模型与光影分析器 (ImageToneModels & ImageToneAnalyzer)

**Files:**
- Create: `entry/src/main/ets/models/ImageToneModels.ets`
- Create: `entry/src/main/ets/services/ImageToneAnalyzer.ets`
- Test: `tools/test-tone-analyzer.cjs`

- [ ] **Step 1: 编写直方图明暗与极端诊断的测试用例 (Red Phase)**
  - 编写 `tools/test-tone-analyzer.cjs`，测试纯样本输入下的：
    - 平均亮度、标准差、暗部/高光占比、双峰大光比（Bimodal）检测；
    - 5 种调性映射：`dappled_contrast`（阴阳错落）、`high_key`（极目高明）、`low_key`（玄冥深致）、`soft_subtle`（烟云冲和）、`rich_full`（气脉丰匀）；
    - 4 种极端直方图诊断及修改建议：高光溢出（降曝光）、暗部死黑（拉高阴影/亮度）、反差过硬（降对比）、灰雾发蒙（增对比）。
- [ ] **Step 2: 运行测试确认测试失败**
  - 命令：`node tools/test-tone-analyzer.cjs`
- [ ] **Step 3: 实现 ImageToneModels.ets 与 ImageToneAnalyzer.ets**
  - 定义清晰的 `ToneCategory`、`ToneMetrics`、`AuditDiagnosis` 契约；
  - 实现纯函数 `analyzeHistogramFromSamples(luminanceSamples: number[] | Uint8Array)`；
  - 实现异步读取沙箱图片 64x64 微缩略图的 `analyzeImageTone(imageUri: string)`。
- [ ] **Step 4: 运行测试确认 Task 1 PASS**
  - 命令：`node tools/test-tone-analyzer.cjs`

---

### Task 2: 拍摄时间、光学参数与题跋生成器全向融合 (WorkDescriptionGenerator)

**Files:**
- Modify: `entry/src/main/ets/models/WorkDescriptionGenerator.ets`
- Test: `tools/test-tone-analyzer.cjs` (追加题跋生成器测试用例)

- [ ] **Step 1: 在测试脚本中补充 WorkDescriptionGenerator 的组合逻辑测试 (Red Phase)**
  - 测试 EXIF 时间解析（如 "2025.11.29 16:18" -> "初冬申末，晚晴斜照"）；
  - 测试参数解析（如 "50mm f/1.8 1/500s" -> "五旬标头"、"大光圈虚实相生"、"疾光定格"）；
  - 测试直方图光影品格拼接；
  - 测试极端曝光校勘建议拼接；
  - 测试老签名兼容性：`generateWorkDescription(adjustments, width, height)` 依旧有效。
- [ ] **Step 2: 运行测试确认失败**
- [ ] **Step 3: 升级 WorkDescriptionGenerator.ets**
  - 导出 `DescriptionContext`；
  - 实现 `describeSolarTermAndTime`、`describeLensAndOptics`、`describeToneAndLight`、`generateAuditSuggestion`；
  - 实现支持上下文对象与参数重载的 `generateWorkDescription`。
- [ ] **Step 4: 运行测试确认 Task 2 PASS**

---

### Task 3: 案卷批注卡排版与详情页动态分析接入 (NotesCard & WorkDetailPage)

**Files:**
- Modify: `entry/src/main/ets/components/common/NotesCard.ets`
- Modify: `entry/src/main/ets/pages/WorkDetailPage.ets`
- Modify: `entry/src/main/ets/models/WorkRecord.ets`
- Test: `tools/test-tone-analyzer.cjs` (追加集成结构与组件接口测试)

- [ ] **Step 1: 在测试脚本中增加对 NotesCard、WorkRecord、WorkDetailPage 的集成契约校验**
- [ ] **Step 2: 升级 NotesCard.ets**
  - 增加可选属性 `toneLabel?: string`（展示古风调性签，如 `[ 调性 · 阴阳错落 ]`）；
  - 增加可选属性 `suggestion?: string`（展示朱砂引首符便签样式的「官署校勘」建议）；
  - 保持现有调用方完全向后兼容。
- [ ] **Step 3: 升级 WorkRecord.ets 与 WorkDetailPage.ets**
  - `WorkRecord` 增加 `toneLabel` 与 `auditSuggestion` 字段；
  - 在 `WorkDetailPage.ensureWorkDimensions()` 时，如果批注为空或为默认模板套话，并行触发 `ExifReaderService.extractWatermarkInfo` 与 `ImageToneAnalyzer.analyzeImageTone`；
  - 动态生成具有针对性的批注、调性标签与校勘建议，并同步更新回 `mockWorkStore`。
- [ ] **Step 4: 运行全量测试套件确认无回归且 100% 通过**
  - 命令：`node tools/test-tone-analyzer.cjs && node tools/test-work-resolution.cjs && node tools/test-colophon-export-flow.cjs`
