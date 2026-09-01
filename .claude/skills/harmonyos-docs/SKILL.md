---
name: harmonyos-docs
description: HarmonyOS NEXT 开发者文档速查。当构建、调试、优化 HarmonyOS 应用，或询问 ArkTS / ArkUI / Stage 模型 / DevEco Studio / 签名发布 / Kit API / 状态管理 / 生命周期 / 路由 / 性能等问题时加载。内含本地概念速查 + 8685 条官方文档索引 + 在线抓取脚本。
---

# HarmonyOS NEXT 开发者文档

> 本 skill = 本地概念/速查/反模式 + 官方文档索引（guides 4662 + API references 4023）+ 在线抓取。
> 官方文档站点：`https://developer.huawei.com/consumer/cn/doc/home`
> 本地索引：`references/catalog-guides.md` / `references/catalog-references.md`

## 一、何时加载本 skill

满足任一条件即加载：
- 提到 HarmonyOS / HarmonyOS NEXT / ArkTS / ArkUI / Stage 模型 / UIAbility / AbilityKit
- 提到 DevEco Studio / hvigor / ohpm / 签名 / HAP / HAR / HSP / AppGallery Connect
- 询问 ArkTS 装饰器（`@State` / `@Prop` / `@Link` / `@ObservedV2` / `@ComponentV2` 等）
- 询问系统 Kit（Media / File / Network / Notification / Location / Security / Graphics …）
- 询问性能优化、主线程卡顿、`LazyForEach`、`@Reusable`、TaskPool / Worker
- 询问应用生命周期、Want、Context、路由、Navigation vs Router

## 二、查文档的流程

1. **先查本地 ref**：`references/ref-*.md` 覆盖了最高频的主题（见第三节索引）。命中就直接用，不必联网。
2. **本地不够，查索引**：在 `references/catalog-guides.md`（开发指南）或 `references/catalog-references.md`（API 参考）里 grep 关键词。每行格式 `- [标题](category/slug)`，`slug` 就是抓取脚本的参数。
3. **仍未命中，抓取原文**：运行 `scripts/fetch-doc.sh <slug>`（或 PowerShell `scripts/fetch-doc.ps1 <slug>`），得到临时文件路径后 Read。
4. **给用户浏览器链接**：`https://developer.huawei.com/consumer/cn/doc/{slug}`（中文）或 `…/en/doc/{slug}`（英文）。

## 三、本地预置参考索引

| 文件 | 内容 | 何时用 |
|---|---|---|
| `ref-arkts-syntax.md` | ArkTS 与 TypeScript 差异、禁用语法清单、`StringEnum`/`union`/`struct` 模式 | 写 ArkTS 代码、遇到 TS 语法报错时 |
| `ref-state-mgmt.md` | V1 / V2 装饰器对比、选型决策树、反模式清单 | 状态管理、装饰器选型、数据流设计时 |
| `ref-ui-components.md` | 容器/基础/弹层组件速查（构造参数 + 关键属性） | 选组件、查属性、搭 UI 时 |
| `ref-navigation.md` | Navigation vs Router 能力对比 | 路由选型、页面跳转、页面栈操作时 |
| `ref-app-lifecycle.md` | UIAbility 完整生命周期 + WindowStage + 常见 FAQ | 启动流程、前后台切换、多 Ability 协同 |
| `ref-devtools.md` | DevEco 工程/配置/hvigor 构建/签名/调试/发布/模拟器 | 工程搭建、签名发布、调试排查时 |
| `ref-system-capabilities.md` | Kit 分类 + 高频 API 签名 + slug | 选 Kit、查某个能力的入口 API 时 |
| `ref-performance.md` | ArkTS 高性能编程、`LazyForEach`、`@Reusable`、TaskPool、图片解码 | 卡顿优化、列表性能、启动耗时 |

## 四、在线文档 URL 模式

```
中文：https://developer.huawei.com/consumer/cn/doc/{slug}
英文：https://developer.huawei.com/consumer/en/doc/{slug}
抓取：https://developer.huawei.com/consumer/cn/doc/{slug}.md   ← 返回 markdown
```

例：`harmonyos-guides/arkts-get-started` → `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started`

## 五、抓取脚本用法

**Bash（macOS / Linux）：**
```bash
bash .claude/skills/harmonyos-docs/scripts/fetch-doc.sh harmonyos-guides/arkts-get-started
# 或指定英文：
bash .claude/skills/harmonyos-docs/scripts/fetch-doc.sh harmonyos-guides/arkts-get-started en
```

**PowerShell（Windows）：**
```powershell
.\.claude\skills\harmonyos-docs\scripts\fetch-doc.ps1 harmonyos-guides/arkts-get-started
```

脚本输出临时文件路径，用 `Read` 读取即可。脚本只做下载，不解析；模型自行 Read 后按需摘取。

## 六、概念速查

### 6.1 状态管理选型

| 场景 | 推荐 |
|---|---|
| 新开发的应用 | **V2**（`@ComponentV2` + `@Local`/`@Param`/`@Event`/`@ObservedV2`/`@Trace`） |
| 已有 V1 且无深度观察需求 | 保留 V1 即可，不必迁移 |
| 需要深度观察 / 属性级更新 | 必须 V2 |
| V1↔V2 混用 | 允许但避免同一组件内混；详见 `v1v2-mixing` slug |

### 6.2 路由选型

- **首选 Navigation**：支持一次开发多端部署、双栏自适应、共享元素动画、路由拦截、页面栈对象。
- **Router (`@ohos.router`)**：仅兼容老项目；新项目不建议。

### 6.3 应用模型

- **Stage 模型**（推荐）：UIAbility + ExtensionAbility + Context + Want，应用/组件分离。
- **FA 模型**（已废弃）：FeatureAbility / ParticleAbility，仅维护老项目。

### 6.4 组件 / 页面 / 应用 三级状态边界

| 范围 | V1 装饰器 | V2 装饰器 | 跨页面？ |
|---|---|---|---|
| 组件内 | `@State` | `@Local` / `@Param` / `@Once` | 否 |
| 父子 | `@Prop`（单） / `@Link`（双） | `@Param` / `@Param`+`@Event` | 否 |
| 跨层级 | `@Provide` / `@Consume` | `@Provider` / `@Consumer` | 否（同页面） |
| 跨页面 | `LocalStorage` + `@LocalStorageLink` | `@ObservedV2` 全局实例 | 是 |
| 全局 | `AppStorage` + `@StorageLink` | `AppStorageV2` | 是（整个进程） |
| 持久化 | `PersistentStorage` | `PersistenceV2` | 跨进程 |

## 七、常见陷阱

1. **ArkTS 禁用 `any`**：所有变量/参数必须有类型；函数返回值也必须显式声明。
2. **闭包 `this` 陷阱**：事件回调必须用箭头函数 `() => {...}`，禁用 `.bind(this)` 的成员函数写法。
3. **主线程阻塞**：生命周期回调（`onCreate` / `onForeground` / `onWindowStageCreate`）只能做轻量操作；耗时任务走 `TaskPool` 或 `Worker`。
4. **`@ObservedV2` 必须搭配 `@Trace`**：只装饰 class 不会让属性被观察，属性必须单独标 `@Trace`。
5. **Navigation 路由栈**：`pushPath` 和 `pushDestination` 不同——前者用 `NavPathStack`，后者用别名 + `NavDestination`。
6. **`onBackground` 时间短**：别在里面存数据库 / 做大 IO；用 `onWindowStageWillDestroy` 或提前 `request.frame`。
7. **资源引用用 `$r`**：`$r('app.string.title')` 而非硬编码字符串，否则多语言失效。
8. **装饰器有 V1/V2 之分**：`@Component` 配 V1，`@ComponentV2` 配 V2，不能混用。
9. **`@Prop` 是深拷贝，`@Param` 是引用**：从 V1 迁 V2 时注意对象共享语义变化。
10. **`animateTo` 在部分 V2 场景下异常**：具体见 `arkts-new-local` slug 的已知问题小节。

## 八、使用指引

1. **先读本地 ref**，再查索引，再抓取。不要上来就联网。
2. **回答时带上 slug**：`参考 harmonyos-guides/xxx 或 harmonyos-references/yyy`，方便用户跳转。
3. **代码示例要符合 ArkTS 规范**：不用 `any`、显式类型、箭头函数、`$r` 引用资源。
4. **状态管理示例优先给 V2**，除非用户明确要求 V1 或维护老项目。
5. **路由示例优先给 Navigation**；Router 仅在兼容场景下给出并明确标注。
6. **抓取失败时**：华为站点偶尔需要鉴权（企业文档）或返回 404（slug 变更）；fallback 是直接给用户浏览器链接让其自查。
7. **跨端 / 跨设备能力**（折叠屏、平板、PC）：查 `catalog-guides.md` 中"一次开发多端部署"分类。
