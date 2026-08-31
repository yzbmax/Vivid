---
name: trio-merge
description: Vivid 三人并行开发协作规范。当需要为蒙版调色项目分配任务、创建分支、提交代码、合并 PR 或解决文件所有权争议时使用。核心原则：按目录边界分工、共享类型冻结、小步合入、固定合并顺序，确保三人同时开发不产生合并冲突。
---

# Vivid · Trio Merge 协作规范

## 核心原则

1. **目录所有权**：每个源码文件只有一个所有者（见下方分工表）。修改他人文件必须在 PR 描述中声明理由。
2. **共享类型冻结**：跨模块的数据结构统一放在 `models/SharedContracts.ets`，三人开工前共同确认后不再修改。扩展只能在末尾追加可选字段。
3. **小步合入**：每个功能点一个 PR，尽快合入主分支，不让分支漂移超过 3 天。
4. **固定合并顺序**：每周确定一次 A→B→C 或其他顺序。先合者直接合入，后合者必须 rebase 最新主分支后再合入。

## 文件所有权表

| 开发者 | 独占范围 |
|---|---|
| A（草稿/续编） | `models/DraftStore.ets`、`models/PendingEditIntentStore.ets`、`components/home/*`、`EditPage.ets` 中草稿保存/恢复区块 |
| B（作品/导出） | `services/WorkSaveService.ets`、`services/WorkFileService.ets`、`services/PhotoExportService.ets`、`pages/WorksPage.ets`、`pages/WorkDetailPage.ets`、`components/works/*` |
| C（调色/预设） | `models/EditModels.ets`、`utils/MaskProcessor.ets`、`utils/RegionRenderer.ets`、`workers/*`、`EditPage.ets` 中预设/羽化区块 |
| 共享 | `models/SharedContracts.ets`（冻结）、`build-profile.json5`、`oh-package.json5`、路由注册 |

## EditPage 分区规则

`EditPage.ets` 由 A 和 C 共同维护但负责不同功能区块。用以下注释标记分隔：

```
// ===== A: Draft save & restore =====
...草稿相关代码...
// ===== End A =====

// ===== C: Preset & Feather =====
...预设和羽化相关代码...
// ===== End C =====
```

两人都不得修改对方标记内的代码。如果需要调用对方区块的函数，通过共享接口或事件回调解耦。

## 分支规范

```
codex/a-draft-store
codex/b-work-repo
codex/b-photo-export
codex/c-presets
codex/c-mask-feather
codex/shared-contracts   # 仅用于首次创建 SharedContracts.ets
```

分支命名格式：`codex/{开发者字母}-{简短功能名}`。

## 冲突处理

遇到合并冲突时按优先级判断：

1. **共享配置文件冲突**（build-profile / oh-package）：以主分支为准，重新追加自己的改动，不合入对方的改动。
2. **EditPage 同行冲突**：检查是否越界修改了对方分区，如果是则撤回自己的越界改动。
3. **SharedContracts 冲突**：不应发生。如果发生说明有人违反了冻结约定，需要三人同步讨论后统一修改。
4. **其他文件冲突**：联系该文件所有者协调解决。

## Git 安全约束

- 不使用 `git reset --hard`、`git checkout --` 等破坏性操作。
- 删除文件必须一次只删一个明确路径，且需 grep 确认无引用。
- 每次 Git 写操作前确认当前分支和工作区状态。

