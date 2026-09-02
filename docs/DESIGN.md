# Terra Faction UI —— 界面样式设计文档（DESIGN）

> 文档版本：V1.0
> 创建日期：2026-08-13
> 资料来源：[terra-faction-ui](https://brandon030722.github.io/terra-faction-ui/)（Github Pages，2026-08-13 抓取）
> 站点性质：**泰拉阵营界面研究** —— "龙门、莱塔尼亚、卡西米尔、莱茵生命、拉特兰、叙拉古、谢拉格、伊比利亚、炎国、企鹅物流、黑钢国际与乌萨斯学生自治团十二套独立布局、控件和交互语法的泰拉阵营界面研究"。
> 文档用途：作为本项目（HarmonyOS 蒙版调色）界面风格与视觉语言的**设计参考**，记录该站 12 套独立风格的完整样式特征与设计令牌。

---

## 一、站点概述与设计意图

- **技术栈**：Next.js 系客户端渲染 SPA（单页路由 `/`），TailwindCSS v4 + Geist 字体，所有阵营在浏览器内通过右上角 **flyout 阵营切换器** 动态切换，不刷新页面。
- **核心主张**：同一个"审查/调度/复核"类事务界面，根据**阵营世界观**（国家、机构、行业）演化出 12 套完全不同的视觉语法——**没有两套使用相同的布局、配色与控件语言**。
- **界面通用任务**：每个阵营都围绕一个"**操作台/审阅台**"构建：顶部信息头（h1 场景标题 + 状态条）→ 主工作区（场景专属可视化）→ 底部控件架（`faction-control-rack`，内置"阵营控件实验台"入口）→ 右下/固定位置的**阵营专属控件**（signature dock）。
- **所有阵营共享**三件套：`main.showcase` 骨架、flyout 切换器、控件实验台（`faction-control-lab` 全屏遮罩）。

## 二、研究框架：五轴定义 + 应用深度

每个阵营由 `<main data-terra-faction="…" data-terra-task="…" data-terra-element="…" data-terra-interaction="…" data-terra-layout="…" data-terra-control="…">` 上的一组**研究轴**定义：

| 轴 | 含义 | 出现取值 |
|---|---|---|
| `task` | 任务类型 | `route` 调度 · `broadcast` 直播 · `dashboard` 审阅台 · `dossier` 卷宗 · `archive` 归档 · `report` 报告 |
| `element` | 主界面元素 | 各阵营独立命名（如 `ward-gate-permit`、`score-lower-third-lock`…） |
| `interaction` | 交互语法 | 如 `civic-gate-chamfer`（切角）、`broadcast-wedge-snap`（楔形咬合）、`stitched-route-settle`（缝合沉降）… |
| `layout` | 布局范式 | 如 `civic-gate-axis`（中轴）、`broadcast-zoning`（分区）、`horizontal-score-field`（横排乐谱）… |
| `control` | 阵营专属控件 | 如 `ward-gate-matrix`（闸门矩阵）、`drift-trim-wheel`（微调轮）… |

**应用深度（APPLICATION DEPTH）**：flyout 内可切换 `中等 (02)` / `极繁 (04)`，默认极繁。深度仅影响**细节密度**（如 `maximal-only` 命令条、增强的图表装饰层），不改变各阵营的核心视觉语法。

## 三、公共基础样式

### 3.1 字体体系

| 令牌 | 值 | 用途 |
|---|---|---|
| `--font-geist-sans` | `'Geist', sans-serif` | 拉丁字符 / 数字（控件实验台、数据） |
| `--font-geist-mono` | `'Geist Mono', sans-serif` | 等宽数据、小号标签、计数 |
| body 字体 | `Noto Sans SC, PingFang SC, Microsoft YaHei, system-ui, sans-serif` | 中文正文（页脚标签常用 `font: 700 .56rem / 1` 等宽小字 + `letter-spacing: .13em–.16em`） |

中英文混排策略：**中文用系统无衬线，数字/拉丁用 Geist 系列**；标签类文字普遍使用极小的等宽大写体（如 `micro-label`、`vertical-label`、`flyout-count`）。

### 3.2 页面骨架

- `body`：`background: #15171a`（深色画布，仅页缘可见），`min-width: 320px`，`color: #161a1e`。
- `main.showcase`：承载 12 套主题，每套主题由其 `data-terra-faction` 值在 `.showcase[data-terra-faction=…]` 上注入 `--focus`、`background`（页缘色）、`color`。
- 页脚：`study-footer`，展示该阵营的**交互证明条**（`interaction-proof` + `is-hover / is-focus / is-press / is-submit` 四态演示）与检查项（`*-checks`、`*-range`）。

### 3.3 阵营切换器（flyout）

- 定位：`position: fixed; top: 1rem; right: 1rem`，宽 17rem，`z-index: 80`。
- 触发器：深色玻璃拟态 `background: #1a1e22f5; backdrop-filter: blur(16px); border: 1px solid #ffffff38; border-radius: .35rem`，`box-shadow: 0 1.1rem 3.5rem #00000042`；三段网格 `4.25rem 1fr 2.75rem`（计数 `12 / 12` · 当前阵营中文名+拉丁名 · `＋`）。
- 展开面板 `#faction-switcher-panel .study-switcher`：`background: #1a1e22fa; blur(22px); width: min(37rem, 100vw - 2rem)`；12 个阵营按钮（`01–12` 序号 + 中文名 + 拉丁名）。
- **flyout 内各阵营的主题也会跟随**：如 `.showcase[data-terra-faction=…] .switcher-group button.is-active` 的选中色 = 各阵营主色（龙门 `#c7443a`、莱塔尼亚 `#c29a4b`、卡西米尔 `#2c62b4`、莱茵生命 `#a6c93f`、拉特兰 `#9b782b`…）。

### 3.4 焦点色与专属控件（signature dock）

- `--focus`：全局默认 `#fff`，每阵营以 chrome 规则覆盖（见 §4 总览表），作为按钮焦点环色。
- 阵营专属控件面板 `.signature-control-dock`：`position: fixed`，`width: min(42rem, 100vw - 2.4rem)`，`z-index: 94`，`filter: drop-shadow(0 1.1rem 1.6rem #0000003d)`；每阵营用 `.signature-<faction>` 覆盖 6 个主题令牌（`--signature-field / -surface / -ink / -rule / -signal / -signal-ink`）**和停靠位置**（左侧 / 底部居中 / 顶栏居中 / 中位…）。
- 专属控件内还有二级区 `signature-secondary`（如"临时通行证打孔"）+ 末尾"打开阵营控件实验台"按钮 `.signature-lab-open`。

### 3.5 控件实验台（control lab）

- `.faction-control-lab`：`position: fixed; inset: 0; z-index: 220` 的全屏遮罩，`place-items: center`，字体用 Geist。
- 每阵营以 `.control-lab-<faction>` 覆盖 `--lab-*` 令牌：`-field / -surface / -raised / -ink / -muted / -rule / -signal / -signal-ink / -critical / -owner / -corner / -arrive-*`。
- `--lab-corner`：该阵营实验台的圆角语言；`--lab-arrive-*`：实验台控件"入场/到位"动画的位移、缩放、旋转——**每个阵营的入场姿态都不同**（横移、竖落、斜偏、缩放…）。

---

## 四、十二阵营风格总览

| # | 阵营 | 标识符 | task | 场景标题 | 主背景 | 文字色 | `--focus` | 主色 signal | 布局范式 |
|---|---|---|---|---|---|---|---|---|---|
| 01 | 龙门 | `lungmen-municipal` | route | 龙门辖区通行调度 | `#c9d0d4` 浅青灰 | `#161a1e` | `#7b201b` | `#c7443a` 砖红 | civic-gate-axis 中轴通行 |
| 02 | 莱塔尼亚 | `leithanien-conservatory` | dashboard | 莱塔尼亚晚间排练次序 | `#2b1018` 暗酒红 | `#f1e3d3` 米白 | `#e2c77e` | `#c29a4b` 鎏金 | horizontal-score-field 横排乐谱 |
| 03 | 卡西米尔 | `kazimierz-broadcast` | broadcast | 卡西米尔赛事直播控制 | `#080b11` 近黑蓝 | `#f5f7fb` | `#8fb8ff` | `#2c62b4` 电蓝 | broadcast-zoning 直播分区 |
| 04 | 莱茵生命 | `rhine-lab` | dashboard | 莱茵生命观察阶段审阅台 | `#dfe6e5` 冷白 | `#17201f` | `#597100` | `#a6c93f` 荧绿 | laboratory-bench 实验台 |
| 05 | 拉特兰 | `laterano-notarial` | dossier | 拉特兰公证事项审议 | `#e7dfcf` 米纸色 | `#2b271f` | `#765716` | `#b58a32` 古金 | symmetrical-reading-paper 对称阅读纸 |
| 06 | 叙拉古 | `siracusa-dossier` | dossier | 叙拉古证据程序复核 | `#d7cab3` 牛皮纸 | `#2d221d` | `#7c2938` | `#742b38` 深栗红 | layered-evidence-desk 层叠证据台 |
| 07 | 谢拉格 | `kjerag-alpine` | route | 谢拉格高原安全路线 | `#cbd9db` 冰川蓝 | `#203136` | `#2d7772` | `#168a8a` 青绿 | elevation-ascent 海拔爬升 |
| 08 | 伊比利亚 | `iberia-nautical` | report | 伊比利亚航向复核报告 | `#081722` 深海蓝 | `#e9e5d9` 象牙白 | `#d1b56d` | `#c49a52` 铜金 | radial-chart-watch 径向航海仪表 |
| 09 | 炎国 | `yan-archival` | archive | 炎国跨署呈报复核 | `#deddd7` 宣纸灰 | `#252827` | `#9b2f2f` | `#b23b2f` 朱砂 | scroll-annotation-margin 卷轴批注 |
| 10 | 企鹅物流 | `penguin-logistics-street` | route | 企鹅物流城市交接调度 | `#081a2f` 深夜蓝 | `#f4f7fa` | `#f4f7fa` | `#f4f7fa` 冰白 | diagonal-handoff-lane 斜向交接道 |
| 11 | 黑钢国际 | `blacksteel-contract` | dashboard | 黑钢国际合约就绪台 | `#141517` 铁灰黑 | `#f0f1ec` | `#f0f1ec` | `#e6c900` 警示黄 | protected-equipment-rack 防护装备架 |
| 12 | 乌萨斯学生自治团 | `ursus-student` | archive | 乌萨斯学生自治团战时安置台 | `#b7b0a3` 补丁布灰 | `#191a18` | `#fff`（默认） | `#a33b2d` 暗红 | repaired-shared-document 缝补共享文件 |

> 表内"主背景"为阵营壳层（如 `.lungmen-shell`）基底色；页缘 `main.showcase` 底色见 §5 各节"chrome"。

### 视觉基调归纳

- **浅色阵营**（龙门 / 莱茵生命 / 拉特兰 / 叙拉古 / 谢拉格 / 炎国 / 乌萨斯）：纸张、青灰、冰川、宣纸质感；文字为深墨色，强调色通常取 **高饱和低明度**（砖红、荧绿、古金、栗红、青绿、朱砂、暗红）。
- **深色阵营**（莱塔尼亚 / 卡西米尔 / 伊比利亚 / 企鹅物流 / 黑钢国际）：夜色、舞台、深海、钢铁质感；文字为米白/冰白，强调色常取 **金属感高明度**（鎏金、电蓝、铜金、警示黄、冰白）。
- 背景普遍由 **2–3 层渐变叠加**构成：一条**斜向/纵向高光带**（占画面 60%–77%）+ **规律网格/条纹线**（间距 64–120px、1px 细线）+ 一个**径向柔光**。这套"斜带 + 网格 + 柔光"配方贯穿全部 12 阵营，是统一性来源。

---

## 五、各阵营样式详解

> 每个阵营按：场景 · 配色与背景 · 控件语言 · 专属控件 · 布局与组件 · 实验台主题 记录。
> "控件语言"指该阵营按钮/控件的形状、按压与选中反馈——**龙门、莱塔尼亚、卡西米尔、莱茵生命 4 家用参数化 `--study-control-*` 统一驱动，其余 8 家为各自定制样式**（详见 §6）。

### 01 龙门 LUNGMEN — `lungmen-municipal`

- **场景**：龙门辖区通行调度（Municipal Movement Office）；研究轴 `route / ward-gate-permit / civic-gate-chamfer / civic-gate-axis / ward-gate-matrix`。
- **配色与背景**：chrome `--focus:#7b201b; background:#c9d0d4`。壳层 `.lungmen-shell`：`linear-gradient(117deg, 透明→65%→#ffffff38)` 斜向反光带 + `repeating-linear-gradient(90deg, … #59636b1a … 79px/80px)` 等距竖线 + 基底 `#c9d0d4`；文字 `#161a1e`。
- **控件语言**（civic-gate-chamfer 切角）：`radius: 0`；`clip-path: polygon(0 0, calc(100% - 11px) 0, 100% 11px, 100% 100%, 0 100%)`（右上角切角）；按压 `translate(3px,1px) scale(1)`；常态边界 `inset .34rem 0 #2e625c`（左侧深绿条）+ `inset 0 -.18rem #c7443a`（底部砖红条）；选中态加粗为 `.5rem / .25rem`。
- **专属控件**：坊区闸门矩阵 `ward-gate-matrix`——放行闸门：`东闸 / 中央门 / 码头北门`；二级区 `ONE-WAY PERMIT 临时通行证打孔`（commit 提交）。
- **布局与组件**：civic-gate-axis 中轴式。`lm-topbar`（机构名+标题+值班时段 `18:00—22:00`、当前队列）；`lm-commandbar`（MAXIMAL ROUTE COMPOSITION 全域通行联动）；`lm-workspace` = 左侧 `lm-districts` 竖排区号导航（`03/07/09/12` 区，`vertical-label` 竖排标签）+ 中央 `lm-stage`（`civic-map` 城区地图：`sector-a/b/c`、`route-path path-one/two`、节点 `origin/check/destination`、`lm-checkpoint-matrix` 检查点矩阵、`lm-priority-lane` 优先通道）；底部 `lm-gate-permit` + `lm-queue` 待处理通行队列。
- **实验台**：`--lab-corner:0`；`--lab-owner:#2e625c`；入场 `--lab-arrive-x:-.9rem`（自左横移入场）。

### 02 莱塔尼亚 LEITHANIEN — `leithanien-conservatory`

- **场景**：莱塔尼亚晚间排练次序；研究轴 `dashboard / cue-ownership-ledger / cadence-control / horizontal-score-field / cadence-stepper`。
- **配色与背景**：chrome `--focus:#e2c77e; background:#2b1018`。壳层 `.leithanien-shell`：`radial-gradient(circle at 68% 43%, #c29a4b1a 0 16%)` 鎏金柔光 + `linear-gradient(90deg, 透明→70%→#4a2130b8)` 右侧暗紫红竖带 + 基底 `#2b1018`；文字 `#f1e3d3`。
- **控件语言**（cadence-control 节拍）：`radius: 999px 4px 999px 4px`（**圆角巨椭圆 × 小直角交替**，乐句切分感）；`clip: none`；按压 `scale(.97)`（无位移）；常态边界 `inset 0 0 0 1px #e2c77e` 金描边 + 左侧 `.34rem #4a2130` 暗紫红条；选中态 `inset .46rem 0 #c29a4b` 鎏金条 + 金描边。
- **专属控件**：演序节点 `cadence-stepper`——`引子 / 第一提示 / 中央换场 / 终止式`；二级区 `PAIRED CUE OWNERS 对应闭合`（pair）。
- **布局与组件**：horizontal-score-field 横排乐谱。`lt-header`（edition/date）；`lt-scorebar`（极繁专属，五线谱进度条）；`lt-stage` 内含 `sequence-field`（`staff-lines` 谱线、`measure-one…four` 小节、`tempo-instrument` 节拍器 + `instrument-ring/hand` 指针）、`lt-cue-matrix` 提示矩阵；`lt-program` 节目表；`wax-index` 蜡封索引；`lt-correspondence` 舞台往来记录。
- **实验台**：`--lab-corner: 999px .24rem 999px .24rem`；入场 `--lab-arrive-scale-x:.97`（横向微缩）。

### 03 卡西米尔 KAZIMIERZ — `kazimierz-broadcast`

- **场景**：卡西米尔赛事直播控制；研究轴 `broadcast / score-lower-third-lock / broadcast-wedge-snap / broadcast-zoning / side-ownership-switch`。
- **配色与背景**：chrome `--focus:#8fb8ff; background:#080b11`。壳层 `.kazimierz-shell`：`linear-gradient(135deg, 透明→64%→#2c62b414)` 斜向电蓝光带 + `repeating-linear-gradient(90deg, … #ffffff08 … 71px/72px)` + 基底 `#080b11`；文字 `#f5f7fb`。
- **控件语言**（broadcast-wedge-snap 楔形咬合）：`radius: 0`；`clip-path: polygon(0 0, calc(100% - 13px) 0, 100% 50%, calc(100% - 13px) 100%, 0 100%, 8px 50%)`（**左右两侧内凹楔形箭头**）；按压 `translate(4px,0) scale(.99)`；常态边界 `inset .32rem 0 #2c62b4` 电蓝条 + 底部 `-.16rem #f5f7fb` 白条；选中态 `.48rem / -.22rem`。
- **专属控件**：对局视角切换 `side-ownership-switch`——`左方视角 / 中线比较 / 右方视角`；二级区 `TOURNAMENT BRANCH 赛事分支锁`（branch）。
- **布局与组件**：broadcast-zoning 直播分区。`kz-score-banner`（`kz-identity`、`kz-side kz-side-blue/red` 双边对阵、`kz-match-state`、`kz-live-strip` 直播条）；`kz-stage` 内 `kz-arena`（`kz-field-grid` 场地网格、`kz-zone-blue/red` 分区、`kz-midline-analysis` 中线分析、`kz-marker marker-blue/neutral/red`）；`kz-live-metrics` 实时数据；`kz-lower-third` 下三横幅；`kz-period-rail` 局数轨；`kz-decision-lock` 判决定。
- **实验台**：`--lab-corner:0`；入场 `--lab-arrive-y:.9rem`（自下浮入）。

### 04 莱茵生命 RHINE LAB — `rhine-lab`

- **场景**：莱茵生命观察阶段审阅台；研究轴 `dashboard / specimen-chamber-review-gate / diagnostic-inset-calibration / laboratory-bench / tolerance-caliper`。
- **配色与背景**：chrome `--focus:#597100; background:#dfe6e5`。壳层 `.rhine-shell`：`linear-gradient(125deg, 透明→68%→#a6c93f17)` 荧绿斜带 + `repeating-linear-gradient(90deg, … #3f4b4d12 … 95px/96px)` + 基底 `#dfe6e5`；文字 `#17201f`。
- **控件语言**（diagnostic-inset-calibration 卡尺内嵌）：`radius: 2px`；`clip: none`；按压 `scale(.97)`；常态边界 `inset 0 0 0 1px #718083` 灰描边 + 左侧 `.28rem #a6c93f` 荧绿条；选中态 `inset 0 -.36rem #a6c93f`（**绿色下沉到整条底边**）。
- **专属控件**：样本容差卡尺 `tolerance-caliper`（stepper 卡尺）；二级区 `CONTAINMENT PREREQUISITE 隔离舱二段锁`（latch）。
- **布局与组件**：laboratory-bench 实验台。`rl-header`；`rl-calibration-strip`（极繁专属标定条）；`rl-bench` → `rl-diagnostic-stage`：`rl-instrument-field`（`rl-grid-plane` 网格平面、`rl-observation-ring` 观察环 + `rl-ring-core`、`rl-orbit orbit-one/two` 双轨道、`rl-phase-matrix` 相位矩阵）、`rl-provenance-capsule` 来源胶囊、`rl-tolerance-rail` 容差轨道；`rl-review-dock` 审阅坞 + `rl-specimen-tray` 样本托盘。
- **实验台**：`--lab-corner:2px`；入场 `--lab-arrive-y:.65rem`。

### 05 拉特兰 LATERANO — `laterano-notarial`

- **场景**：拉特兰公证事项审议；研究轴 `dossier / case-register-approval-ring / ceremonial-double-ring / symmetrical-reading-paper / witness-pair-toggle`。
- **配色与背景**：chrome `--focus:#765716; background:#e7dfcf`。壳层 `.laterano-shell`：`radial-gradient(circle at 50% 48%, #9b782b14 0 17rem)` 居中金色光环 + `repeating-linear-gradient(90deg, … #5247340d … 119px/120px)` + 基底 `#e7dfcf`；文字 `#2b271f`。
- **控件语言**：环形语义为主——专属控件使用 `la-ring ring-outer/inner` **双层圆环**；常规按钮为浅纸面 + 金褐色描边（`#947b5b` 系）。
- **专属控件**：双见证契约 `witness-pair-toggle`——`申请方声明 / 见证方记录`；二级区 `BOUNDED EXCEPTION 例外孔径`（disclosure）。
- **布局与组件**：symmetrical-reading-paper 对称阅读纸。`la-header`；`la-case-register` 案件登记；`la-reading-field` 内 `la-paper`（`la-paper-head` 带 `la-exception-corner` 例外角、`la-paper-body`）；`la-chronology` 时间线；`la-reading-copy` 复读稿；`la-witness-band` 见证带；`la-approval-instrument`（`la-ring ring-outer/inner`、`la-stage-dial` 审阅拨盘）。
- **实验台**：`--lab-corner:.7rem`；入场 `--lab-arrive-scale-x/y:.975`。

### 06 叙拉古 SIRACUSA — `siracusa-dossier`

- **场景**：叙拉古证据程序复核；研究轴 `dossier / layered-evidence-hinge / folded-docket-settle / layered-evidence-desk / docket-leaf-tabs`。
- **配色与背景**：chrome `--focus:#7c2938; background:#2b221e`。壳层 `.siracusa-shell`：双层 **1px 方格纸**（`linear-gradient(90deg, #4d34292e 1px, transparent)` 纵向 4.8rem + `linear-gradient(0deg, #422a1f24 1px, transparent)` 横向 4.8rem）+ `radial-gradient(circle at 86% 14%, #866c4c2e, transparent 24rem)` 牛皮纸柔光 + 基底 `#d7cab3`；文字 `#2d221d`。
- **控件语言**：纸页语言——专属控件为**多层"叶子"（leaf）堆叠**（`sr-leaf-1/2/3`，被质疑卷宗用 `is-contested` 标记）；叶签 `sr-docket-tabs` 分段切换（`证据/证词/时序/意见`）。
- **专属控件**：卷宗叶签 `docket-leaf-tabs`——`证据 / 证词 / 时序 / 意见`；二级区 `SOURCE RELATION 来源铰链`（disclosure）。
- **布局与组件**：layered-evidence-desk 层叠证据台。`sr-header`；`sr-evidence-desk`（`sr-leaf-1/2/3` 错位层叠、`sr-main-dossier` 主卷宗、`sr-reading-columns` 双栏阅读、`sr-evidence-hinge` 证据铰链 `is-within` 状态）；`sr-ruling-band` 裁决带。
- **实验台**：`--lab-corner:0`；入场 `--lab-arrive-y:.7rem; --lab-arrive-rotate:-.35deg`（**略带俯角沉降**）。

### 07 谢拉格 KJERAG — `kjerag-alpine`

- **场景**：谢拉格高原安全路线；研究轴 `route / altitude-weather-gate / stitched-route-settle / elevation-ascent / stitched-weather-gates`。
- **配色与背景**：chrome `--focus:#2d7772; background:#b9c9cc`。壳层 `.kjerag-shell`：`linear-gradient(138deg, 透明→44%→#3d555a14)` 斜向冰川光带 + `repeating-linear-gradient(90deg, … #40565a14 … 4rem)` + 基底 `#cbd9db`；文字 `#203136`。
- **控件语言**：山径语言——专属控件为"缝合"式**天气闸滑杆**（`stitched-weather-gates`，三参数 `能见度/侧风/积雪承载`）；路线用 `kj-contour contour-one/two` 等高线 + `kj-stop-1/2/3` 站点。
- **专属控件**：缝合天气闸 `stitched-weather-gates`——`能见度 / 侧风 / 积雪承载`；二级区 `ASCENT THRESHOLD 海拔结滑杆`（range）。
- **布局与组件**：elevation-ascent 海拔爬升。`kj-weather-lintel` 天气楣梁；`kj-ascent-stage` → `kj-route-field`（`kj-contour` 等高线、`kj-ascent-line` 爬升线、`kj-altitude-ribbon` 海拔缎带、`kj-passage-gate` 通道闸、`kj-stop-1/2/3` 站点）；`kj-safety-panel` 安全面板；`kj-departure-decision` 出发决策。
- **实验台**：`--lab-corner: .75rem .12rem .75rem .12rem`（锯齿圆角）；入场 `--lab-arrive-y:1rem`。

### 08 伊比利亚 IBERIA — `iberia-nautical`

- **场景**：伊比利亚航向复核报告；研究轴 `report / watch-heading-drift-ladder / porthole-bearing-contract / radial-chart-watch / drift-trim-wheel`。
- **配色与背景**：chrome `--focus:#d1b56d; background:#08141e`。壳层 `.iberia-shell`：`linear-gradient(124deg, 透明→63%→#b89a5712)` 铜金斜带 + `radial-gradient(circle at 60% 46%, #2f4c5bcc 0, #132938 38%, #081722 76%)` **深海多层径向**；文字 `#e9e5d9`。
- **控件语言**：航海仪表——专属控件 `drift-trim-wheel` **偏航微调轮**（stepper）；报告组件用 `ib-chart-ring ring-a/b/c` 同心圆环 + `ib-bearing-line planned/verified` 计划/实测航向线。
- **专属控件**：偏航微调轮 `drift-trim-wheel`（stepper 轮）；二级区 `WATCHKEEPING 值守环`（ring）。
- **布局与组件**：radial-chart-watch 径向航海仪表。`ib-header`；`ib-chart-watch`（`ib-watch-selectors`、`ib-chart-field`、`ring-a/b/c`、`ib-bearing-line`、`ib-heading-instrument` + `ib-heading-scale` 刻度盘）；`ib-watch-chronology` 值守时间线；`ib-drift-ladder` 漂移梯（`is-within` 容差带）；`ib-vessel-inset` 舰船插图；`ib-report-plaque` 报告铭牌。
- **实验台**：`--lab-corner: 999px 999px .42rem .42rem`（**顶部双圆、底部直角的甲板窗圆角**）；入场 `--lab-arrive-scale-x/y:.96`。

### 09 炎国 YAN — `yan-archival`

- **场景**：炎国跨署呈报复核；研究轴 `archive / record-rail-transfer-slip / folded-paper-seal-press / scroll-annotation-margin / seal-press`。
- **配色与背景**：chrome `--focus:#9b2f2f; background:#d6d4cd`。壳层 `.yan-shell`：`linear-gradient(90deg, #2d2f2f0f 1px, transparent)` 纵向 5.4rem 细线 + `radial-gradient(circle at 78% 18%, #5c5e5b14, transparent 24rem)` + 基底 `#deddd7`；文字 `#252827`。
- **控件语言**：文书铃印——专属控件 `seal-press` **案牍钤印**（盖章按压，latch）；卷宗 `yn-long-sheet` 长卷轴 + `yn-annotation-margin` 批注边栏。
- **专属控件**：案牍钤印 `seal-press`；二级区 `EDITORIAL MARGIN 批注边栏`（disclosure）。
- **布局与组件**：scroll-annotation-margin 卷轴批注。`yn-paper-head`；`yn-record-index` 卷宗索引；`yn-scroll-field`（`yn-long-sheet` 长卷、`yn-title-column` 题头栏、`yn-record-title`、`yn-reading-body` 正文、`yn-main-copy`、`yn-annotation-margin` 批注边栏）；`yn-transfer-slip` 移交签；`yn-control-band` 控制带；`yn-petition-fold` 呈文折。
- **实验台**：`--lab-corner:0`；入场 `--lab-arrive-x:.85rem`（自左横移）。

### 10 企鹅物流 PENGUIN — `penguin-logistics-street`

- **场景**：企鹅物流城市交接调度；研究轴 `route / waybill-handoff-condition-tags / ticketed-lane-snap / diagonal-handoff-lane / courier-relay-rail`。
- **配色与背景**：chrome `--focus:#f4f7fa; color:#f4f7fa; background:#081a2f`。壳层 `.penguin-shell`：`radial-gradient(circle at 82% 18%, #5d8eb52b, transparent 27rem)` 城市夜景光晕 + `linear-gradient(145deg, 透明→60%→#4b6f901f)` 斜向交接道 + 基底 `#081a2f`；文字 `#f4f7fa`；壳层为 `display:grid; grid-template-rows:auto minmax(29rem,1fr) auto`。
- **控件语言**：街巷物流——专属控件 `courier-relay-rail` **配送员接力轨**（当前配送/下位接力/目的地签收）；交接节点 `pg-handoff-nodes`、条件签 `pg-condition-tags`。
- **专属控件**：配送员接力轨 `courier-relay-rail`——`当前配送 / 下位接力 / 目的地签收`；二级区 `PARCEL CONDITIONS 包裹条件签`（tags）。
- **布局与组件**：diagonal-handoff-lane 斜向交接道。`pg-dispatch-head` 调度头；`pg-street-field`（`pg-city-grid` 街区网格、`pg-diagonal-lane` 斜向车道、`pg-waybill-stack` 运单堆、`pg-active-waybill` 活动运单、`pg-waybill-route` 运单路线、`pg-handoff-nodes` 交接节点）；`pg-condition-tags`；`pg-handoff-strip` 交接带。
- **实验台**：`--lab-corner:0`；入场 `--lab-arrive-x:1.1rem; --lab-arrive-rotate:.35deg`（右移+斜偏）。

### 11 黑钢国际 BLACKSTEEL — `blacksteel-contract`

- **场景**：黑钢国际合约就绪台；研究轴 `dashboard / assignment-rack-readiness-lock / industrial-chamfer-lock / protected-equipment-rack / equipment-bay-shutters`。
- **配色与背景**：chrome `--focus:#f0f1ec; color:#f0f1ec; background:#141517`。壳层 `.blacksteel-shell`：`linear-gradient(135deg, #ffffff05 0 24%, transparent 24% 74%, #e6c9000a 74%)` 工业斜切面（右上角暗黄提示）+ `repeating-linear-gradient(90deg, … #f0f1ec08 … 119px/120px)` + 基底 `#141517`；文字 `#f0f1ec`；壳层为 `display:grid; grid-template-rows:auto auto minmax(25rem,1fr) auto`。
- **控件语言**（industrial-chamfer-lock 工业切角）：装备舱 `bs-bay`（`bs-equipment-bay` 设备舱、`bs-people-bay` 人员舱）+ `bs-shutter` 卷帘闸；就绪扫描 `bs-readiness-scan` 通电状态（`is-ready`）。
- **专属控件**：装备舱就绪闸 `equipment-bay-shutters`——`通讯单元 / 运输箱 / 防护模块`；二级区 `DEPENDENCY INTERLOCK 部署前置互锁`（interlock）。
- **布局与组件**：protected-equipment-rack 防护装备架。`bs-assignment-lintel` 任务楣梁；`bs-assignment-rail` 任务轨；`bs-protected-rack`（`bs-bay`、`bs-scope-plate` 铭牌、`bs-equipment-bay`）；`bs-readiness-scan`；`bs-readiness-lock` 就绪锁；`bs-range` / `bs-interaction-proof` 状态证明。
- **实验台**：`--lab-corner:0`；`--lab-owner:#7656b5`（紫罗兰常驻所有者色）；入场 `--lab-arrive-y:.75rem`。

### 12 乌萨斯学生自治团 URSUS — `ursus-student`

- **场景**：乌萨斯学生自治团战时安置台；研究轴 `archive / repaired-roster-alert-window / repaired-paper-control / repaired-shared-document / shared-supply-tabs`。
- **配色与背景**：无 chrome 覆盖 → 使用默认 `--focus:#fff`；壳层 `.ursus-shell`：`linear-gradient(103deg, 透明→77%→#4b2d2a1f)` 斜向暖棕带 + `repeating-linear-gradient(0deg, … #2e2d2a12 … 2.65rem)` **横向缝补线**（间距约 2.65rem 的"缝线"）+ 基底 `#b7b0a3` 补丁布灰；文字 `#191a18`。
- **控件语言**：战时纸制品——`us-roster` 名单（`is-owned` 认领状态）、`us-supply-board` 物资板、`us-conflict-notes` 冲突备注、`us-alert-tape` 警示胶带（`us-alert-tape` 斜纹）。
- **专属控件**：共用物资责任条 `shared-supply-tabs`——`医务 / 热食 / 保暖 / 转移车`；二级区 `SAFE TRANSFER 转移通道锁`（corridor）。
- **布局与组件**：repaired-shared-document 缝补共享文件。`us-document-head` 文件头；`us-document-field`（`us-conflict-notes`、`us-roster`、`us-supply-board`、`us-transfer-line` 转移线——极繁专属）；`us-control-block` 控制块；`us-alert-tape`。
- **实验台**：`--lab-corner: .15rem .55rem .18rem .08rem`（手写感不规则圆角）；入场 `--lab-arrive-y:.6rem; --lab-arrive-rotate:.25deg`。

---

## 六、控件语法对照

### 6.1 参数化控件语言（`--study-control-*`，4 家）

这 4 家通过 CSS 变量驱动**同一个按钮基类**，仅改参数即获得完全不同的控件形态：

| 阵营 | `radius` | `clip-path` 形状 | 按压 | 常态边界 | 选中态 |
|---|---|---|---|---|---|
| 龙门 | `0` | 右上 **11px 切角** | `tx 3px, ty 1px` | 左侧 `#2e625c` 绿条 + 底 `#c7443a` 红条 | 绿条 `.5rem` + 红条 `.25rem` |
| 莱塔尼亚 | `999px 4px 999px 4px` | `none` | `scale(.97)` | 金描边 `#e2c77e` + 左 `#4a2130` 条 | 金条 `#c29a4b` `.46rem` |
| 卡西米尔 | `0` | 左右 **内凹楔形箭头**（13px） | `tx 4px` | 左 `#2c62b4` 蓝条 + 底白条 | 蓝条 `.48rem` |
| 莱茵生命 | `2px` | `none` | `scale(.97)` | 灰描边 `#718083` + 左 `#a6c93f` 绿条 | **整条绿色底边** `.36rem` |

统一过渡曲线：`translate .16s / scale .16s / box-shadow .22s / color .18s`。这 4 家示范了"**同一机制、不同参数 → 不同阵营气质**"的最小成本思路，最具工程复用价值。

### 6.2 定制控件（其余 8 家）

拉特兰（双环）、叙拉古（纸叶层叠）、谢拉格（缝合滑杆）、伊比利亚（仪表微调轮）、炎国（钤印）、企鹅物流（接力轨）、黑钢（工业切角+扫描通电）、乌萨斯（补丁标签）——控件形态完全围绕场景定制，各自定义了专属结构类（`la-ring`、`sr-leaf`、`kj-passage-gate`、`ib-chart-ring`、`yn-long-sheet`、`pg-waybill-stack`、`bs-shutter`、`us-alert-tape` 等）。

### 6.3 实验台入场动画（`--lab-arrive-*`）对照

| 阵营 | 入场姿态 |
|---|---|
| 龙门 | 自左横移 `x:-.9rem` |
| 莱塔尼亚 | 横向微缩 `scale-x:.97` |
| 卡西米尔 | 自下浮入 `y:.9rem` |
| 莱茵生命 | 自下浮入 `y:.65rem` |
| 拉特兰 | 等比微缩 `scale:.975` |
| 叙拉古 | 沉降 + 左倾 `y:.7rem; rotate:-.35deg` |
| 谢拉格 | 下落 `y:1rem` |
| 伊比利亚 | 等比微缩 `scale:.96` |
| 炎国 | 自左横移 `x:.85rem` |
| 企鹅物流 | 右移 + 右倾 `x:1.1rem; rotate:.35deg` |
| 黑钢国际 | 自下浮入 `y:.75rem` |
| 乌萨斯学生自治团 | 下落 + 右倾 `y:.6rem; rotate:.25deg` |

> 观察：**横移**用于"线性流程"阵营（龙门/炎国），**下落/浮入**用于"平台/审阅"阵营（卡西米尔/黑钢/谢拉格），**缩放**用于"乐谱/仪表"阵营（莱塔尼亚/拉特兰/伊比利亚），**带旋转的沉降**用于"纸页/街巷"阵营（叙拉古/企鹅/乌萨斯）。

---

## 七、可借鉴的设计模式

1. **一主题一套 CSS 变量（token 化主题）**：`--study-control-*`（控件）、`--signature-*`（专属面板）、`--lab-*`（实验台）三组变量以 `.shell / .signature-<faction> / .control-lab-<faction>` 类为载体注入，做到"换壳不改结构"。本项目（蒙版调色）可照此把亮度/对比度/饱和度/色温控件做成一套可主题化的控件变量。
2. **背景三层渐变配方**：斜向高光带（60%–77% 处）+ 规则网格/缝线（1px 细线、间距 64–120px）+ 径向柔光。任何页面只需更换三种渐变的颜色与角度即可获得完全不同的环境质感。
3. **浅底深字 vs 深底浅字二分**：浅色系阵营用"纸张/冰川"基色 + 高饱和低明度强调色；深色系阵营用"夜色/金属"基色 + 金属高明度强调色。强调色同时承担 `--focus` 焦点环、选中态、signal 色三重职责。
4. **互动证明条（interaction-proof）**：在页面底部统一展示 hover / focus / press / submit 四态，让"控件语言"可被直观校验——非常适合作为设计验收页的固定模块。
5. **"极繁/中等"应用深度开关**：同一套视觉语法通过 `data-terra-depth` 控制装饰层（命令条、图表描边、附加字段）的显隐，兼顾演示密度与可实现性。
6. **中文正文 + Geist 数字/等宽标签**：正文用系统中文字体，数据、计数、标签一律等宽小字（`.56rem–.62rem`）+ 宽字距大写，塑造"仪表/档案"质感。

---

*本文档由站点实际渲染样式（CSS 与计算样式）逆向整理，色值为抓取时值；站点若更新，需重新抓取核对。*
