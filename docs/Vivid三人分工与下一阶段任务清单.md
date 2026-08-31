# Vivid 三人分工与下一阶段任务清单

> 更新日期：2026-08-24
> 前提：登录门禁、选图、编辑页基础调色、作品页展示已跑通。
> 协作规范：见 `.agents/skills/trio-merge/SKILL.md`。

---

## 一、文件所有权边界

| 开发者 | 角色 | 独占目录/文件 |
|---|---|---|
| **A** | 草稿与续编 | `pages/EditPage.ets`（草稿部分）、`models/DraftStore.ets`、`models/PendingEditIntentStore.ets`、`components/home/*` |
| **B** | 作品仓库与导出 | `services/WorkSaveService.ets`、`services/WorkFileService.ets`、`services/PhotoExportService.ets`、`pages/WorksPage.ets`、`pages/WorkDetailPage.ets`、`components/works/*` |
| **C** | 调色增强与预设 | `pages/EditPage.ets`（预设/羽化部分）、`utils/MaskProcessor.ets`、`utils/RegionRenderer.ets`、`models/EditModels.ets`、`workers/*` |
| **共享** | 公共契约与配置 | `models/SharedContracts.ets`、`build-profile.json5`、`oh-package.json5`、路由注册处 |

> **规则：** 每个非共享文件只能由其所有者修改。如需改动他人文件，在 PR 中说明原因并通知对方，不得静默修改。`EditPage.ets` 由 A 和 C 共同负责但分区不同——A 只动草稿保存/恢复逻辑，C 只动预设和蒙版羽化 UI；两人改动区域用注释标记分隔，避免同行冲突。

---

## 二、任务清单

### A — 草稿保存与续编

- [ ] 实现 `DraftStore`：将编辑参数 + 源图 URI 序列化到应用沙箱 Preferences
- [ ] 编辑页退出时弹出"暂存草稿 / 放弃"选项
- [ ] 首页显示草稿入口卡片（有草稿时）
- [ ] 点击草稿卡片恢复到编辑页并回填参数
- [ ] 草稿上限 1 条，新草稿覆盖旧草稿
- [ ] 单元测试：DraftStore 读写、序列化/反序列化、覆盖逻辑

**依赖：** 无前置依赖，可立即开始。

---

### B — 统一数据源与相册导出

- [ ] 创建 `WorkRepository`，合并 `EditWorkStore` 和 `MockWorkStore` 为单一数据源
- [ ] 编辑页"落印保存"写入 `WorkRepository`
- [ ] 作品页和详情页从 `WorkRepository` 读取
- [ ] 实现真实作品删除（当前 WorksPage 有 TODO）
- [ ] 接入 PhotoExportService：读取 AppSettingsStore 的格式/画质设置
- [ ] 正式保存时渲染最终 PixelMap 并写入系统相册
- [ ] 导出失败有明确错误提示，不静默吞掉
- [ ] 单元测试：WorkRepository CRUD、导出参数读取

**依赖：** 无前置依赖，可立即开始。这是最高优先级任务。

---

### C — 一键预设与蒙版羽化

- [ ] 在 `EditModels.ets` 中定义 `PresetPreset[]` 数据结构（名称 + 四参数预设值）
- [ ] 内置 6 组预设：原片、通透、复古、黑白胶片、暖阳、冷调
- [ ] 编辑页工具栏新增"预设"Tab，点击即应用预设参数
- [ ] 用户可在预设基础上继续微调滑块
- [ ] 在 `MaskProcessor.ets` 中增加羽化强度参数（高斯模糊蒙版边缘）
- [ ] 编辑页背景/主体切换区新增羽化滑块（0-100）
- [ ] Worker 渲染链路传入羽化参数
- [ ] 单元测试：预设值应用后 AdjustParams 正确、羽化参数传递

**依赖：** 无前置依赖，可立即开始。

---

## 三、共享契约

三人在开工前共同确认以下接口定义，写入 `models/SharedContracts.ets` 后冻结：

```typescript
// 所有跨模块传递的数据结构在此定义，一旦冻结不再修改
export interface WorkRecord {
  id: string;
  title: string;
  imageUri: string;
  adjustParams: AdjustParams;
  createdAt: number;
  updatedAt: number;
}

export interface DraftRecord {
  imageUri: string;
  adjustParams: AdjustParams;
  savedAt: number;
}
```

如果后续需要扩展字段，只能在末尾追加可选字段，不能删除或重命名已有字段。

---

## 四、里程碑与合并顺序

| 阶段 | 内容 | 合并顺序 |
|---|---|---|
| 第 1 周 | B 完成 WorkRepository 统一数据源 → A 完成草稿存储层 → C 完成 EditModels 预设结构 | B → A → C |
| 第 2 周 | 三人各自完成 UI 层 | A → B → C |
| 第 3 周 | B 完成相册导出、C 完成羽化渲染、A 完成草稿恢复流程 | B → C → A |
| 第 4 周 | 集成回归 + 真机验收 | 全员 |

每周五定一次合并顺序，先合的人 rebase 主分支，后合的人基于最新主分支 rebase 自己的分支再合入。

