---
name: mask-seal
description: 蒙版调色 App 的「炎国卷轴 · 文书钤印」界面设计风格规范（Mask & Seal）。当需要为蒙版调色项目设计、实现或评审界面，选用配色/字体/控件/动效，或复刻既有 6 屏样板样式时使用。内含完整设计令牌、页面骨架、控件语言、动效语言、文案约定与屏幕样板。
---

# 蒙版调色 · Mask & Seal 设计风格

> 本 skill 封装自 `docs/stitch_/stitch_/`（6 个 code.html 界面样板 + DESIGN.md）。核心思想：**把图片编辑、调色、保存的过程，比作古籍呈报与审批——"文书钤印、长卷批注"。**
> 参考素材位置：本 skill 的 `references/design-tokens/DESIGN.md`（令牌源文件）与 `references/screens/_1…_6/code.html`（可复用 HTML 样板）。

## 一、设计理念

- **核心理念**：文书钤印、长卷批注。用户是"呈报者"，App 是"复核的官署"。
- 界面元素均以古文书隐喻命名：**卷宗**（图片/作品）、**呈报**（处理）、**复核**（预览/比对）、**封缄/落印**（保存）、**印信**（服务/凭证）、**档存**（历史记录）、**主阁**（首页）、**卷宗编号**（元信息）。
- 全程**纸质感**：宣纸底、朱砂印、细网格衬线、卷轴展开动效。

## 二、设计令牌

### 2.1 色彩

| 令牌 | 值 | 用途 |
|---|---|---|
| `paper-base` | `#deddd7` | 宣纸灰，**全局背景** + 竖线网格底色 |
| `paper-surface` | `#f2f1ed` | 浅纸白，顶栏/浮层/输入卡表面 |
| `surface` / `surface-dim` / `surface-bright` | `#fff8f7` / `#ebd5d3` / `#fff8f7` | M3 主 surface 系 |
| `surface-container-lowest/low` | `#ffffff` / `#fff0ef` | 更低容器 |
| `surface-container` | `#ffe9e7` | 常规卡片容器 |
| `surface-container-high/highest` | `#f9e3e1` / `#f3dedc` | 高/最高容器 |
| `on-surface` / `on-surface-variant` | `#241918` / `#574140` | 正文墨色 / 次级文字 |
| `inverse-surface` / `inverse-on-surface` | `#3a2d2c` / `#ffedeb` | 反色面（卷轴木轴、深色操作条） |
| `outline` / `outline-variant` | `#8b716f` / `#debfbd` | 描边 / 弱描边 |
| `surface-tint` | `#a73837` | 主题色 tint（卷轴内衬红边） |
| `primary` | `#7b171b` | **深朱砂主色**（主按钮、标题强调、选中） |
| `on-primary` | `#ffffff` | 主色上文字 |
| `primary-container` | `#9b2f2f` | 主色容器（底部导航激活态） |
| `seal-red` | `#b23b2f` | **钤印红**（印章、滑块填充/滑块、tab 指示条） |
| `secondary` / `secondary-container` | `#5c5f5e` / `#e1e3e1` | 中性辅助 |
| `tertiary` | `#004645` | 青绿点缀（"存储空间"指标） |
| `error` / `error-container` | `#ba1a1a` / `#ffdad6` | 错误（"数据损坏"） |

**关键使用规则**：
- 主按钮 = `primary`（深朱砂），按压态换 `seal-red`；关键操作（调色"落印保存"）直接用 `seal-red`。
- 背景网格线用 `paper-base` 底 + 1px 半透明朱砂竖线（`rgba(123,23,27,0.05)`）或 `outline` 系（`rgba(139,113,111,0.1)`）。
- 激活/选中态高优先用 `primary-container`（底部导航）或 `seal-red`（滑块/tab/印章）。

### 2.2 字体

| 令牌 | 字体 | 字号/行高/字重 | 用途 |
|---|---|---|---|
| `headline-lg` | **Noto Serif SC** | 32px / 40px / 700 | 大标题 |
| `headline-md` | **Noto Serif SC** | 24px / 32px / 600 | 顶栏标题、区块标题 |
| `headline-lg-mobile` | Noto Serif SC | 28px / 36px / 700 | 移动端大标题 |
| `body-md` | **Noto Sans SC** | 16px / 24px / 400 | 正文 |
| `label-mono` | monospace | 13px / 16px / 500 · `letter-spacing: 0.05em` | 数据/标签（卷宗编号、指标、按钮小字） |

**规则**：标题一律衬线（Serif），正文无衬线，**数据/标签/按钮小字一律等宽 + 大写 + 宽字距**（常再叠加 `tracking-widest`、`uppercase`）。中文正文用系统无衬线（HarmonyOS 上为 HarmonyOS Sans SC）。图标用 **Material Symbols Outlined**。

### 2.3 间距 / 圆角 / 背景

| 令牌 | 值 | 用途 |
|---|---|---|
| `grid-unit` | `5.4rem` | 背景竖线网格间距 |
| `annotation-margin` | `4rem` | 右侧"批注栏"占位宽度（竖排标签场景） |
| `gutter` | `1rem` | 横向页边距 |
| `margin-mobile` | `1.25rem` | 移动端页边距 |
| 圆角 | `DEFAULT .25rem / lg .5rem / xl .75rem / full 9999px` | 直角偏方，仅卡片/头像/药丸用圆角 |

**全局 body**（所有样板共用）：
```css
body {
  background-color: #deddd7;
  background-image: linear-gradient(to right, rgba(123,23,27,0.05) 1px, transparent 1px);
  background-size: 5.4rem 100%;
  overscroll-behavior: none;
}
.radial-glow { /* 固定全屏，pointer-events:none */
  background: radial-gradient(circle at top, rgba(155,47,47,0.05) 0%, transparent 70%);
}
```
安全区：`viewport-fit=cover` + `.pt-safe` / `.pb-safe`（`env(safe-area-inset-*)`）；隐藏滚动条。

## 三、页面骨架（三件套 + 落款）

1. **固定顶栏**：`bg-paper-surface/80 backdrop-blur-xl pt-safe`，高 `h-14`；标题绝对居中（`font-headline-md`，纯文字/英文 UPPERCASE）；右侧头像圆钮 `w-8 h-8 rounded-full bg-primary` 内 `person` 图标；可带返回箭头（`arrow_back_ios_new`）。
2. **固定底部导航**：4 项 `卷轴 / 调色 / 印信 / 档存`（图标 `format_paint / palette / verified_user|approval_delegation / history_edu|inventory_2` + 10px 等宽大写标签）；激活项 `text-primary-container font-bold`；图标用 `w-20` 竖排布局。
3. **卷宗落款 pill**：底导航上方居中一条 `px-3 py-0.5 border border-primary/10 bg-primary/5`，文字 `font-label-mono text-[10px] text-primary/60 uppercase tracking-widest`——文案 `炎国跨署呈报复核 · 卷宗第肆零玖号`（每屏可换编号）。
4. **编辑类屏幕的底部操作条**：`fixed bottom bg-paper-surface/95 backdrop-blur-md border-t border-outline-variant/30`，高 `h-16`，左侧辅助钮（`layers` / `restart_alt`），右侧主操作按钮（`bg-seal-red` 斜向高光扫过动效 + 落印文案）。

## 四、控件语言（Seal Press · 钤印按压）

> 所有控件**偏方直角**，反馈以"盖章/按压"为隐喻：按下=钤印落下。

- **主按钮**：`bg-primary text-on-primary py-4 font-headline-md text-[18px] tracking-widest`，居中图标+文字；`hover:bg-seal-red`、`active:scale-[0.98]`；可叠加"白闪"覆盖层（`bg-white/10` group-hover 显现）。按钮文案用**动词化卷宗语**（呈验 / 落印 / 落印保存 / 返回主阁 / 分发令 / 执行置换）。
- **次按钮（ghost）**：`bg-transparent text-primary border border-primary/20 uppercase font-label-mono`；hover `bg-primary/5`。
- **分段控件（字号 S/M/L）**：`flex-1 py-1.5 border`；激活 `border-primary text-primary bg-primary/5`，未激活 `border-outline/30 text-on-surface/60`。
- **滑块**（核心控件，见 `_5` Color Analysis）：
  - 轨道：`relative w-full h-8`，基线 `h-[1px] bg-outline-variant`；
  - 填充：`h-[2px] bg-seal-red`，宽度=数值百分比；
  - **滑块头 = 朱砂方块**：`w-4 h-4 bg-seal-red` 内含 `w-1.5 h-1.5 bg-surface` 内芯（微印章感），`active:scale-110`；
  - 值标签：`font-label-mono text-primary font-bold` 右侧右对齐，格式 `+15 / +08 / -12 / +22`（带符号两位）。
  - 变体（`_3` 留白滑块）：滑块头为 `w-3 h-4 bg-inverse-surface border border-primary/20` 的"石块"。
- **Tab**：`font-headline-md pb-2`，激活文字 `text-on-surface` + 底部指示条 `absolute h-[3px] bg-seal-red scale-x-100 origin-left transition-transform duration-300`；未激活 `text-on-surface-variant/50` 指示条 `scale-x-0`。参见 `_5` 主体/背景。
- **输入框**：
  - 下划线式（`_3` 设备签）：`bg-transparent border-b border-on-surface/20 focus:border-primary`；
  - 卡片式（`_2` 登录）：`border border-outline-variant rounded-md py-3 pl-10`，左侧图标随 focus 变 `primary`，**标签浮在框上**（`absolute -top-3 left-2 bg-paper-surface px-1`）。
- **选择卡片（印章选择 `_3`）**：`grid-cols-4 aspect-square`；激活 `border-2 border-seal-red` 内嵌印章红字；未激活 `border border-outline/20` 灰字；"制印"用虚线框 `border-dashed` + `add` 图标。
- **图片框**：预览区普遍用**四角括号**（`absolute w-2 h-2 border-t border-l border-on-surface/40` 四角）+ 内衬红边（`border border-surface-tint/20`）营造"卷宗装裱"感；`aspect-[3/4]` / `aspect-[4/5]` 比例。

## 五、动效语言

| 动效 | 关键帧 | 用途 |
|---|---|---|
| **stamp-in**（盖章） | `opacity 0→1; scale 1.5→0.9→1; rotate 5deg→0`，0.6s `cubic-bezier(.175,.885,.32,1.275)` | 成功图标/印章落下（`_4`） |
| **fade-up**（浮上） | `opacity→1; translateY(0)`，0.5s ease-out | 文案/按钮错峰出现（`_4` 0.2s/0.3s/0.8s 延迟） |
| **unfold-scroll**（卷轴展开） | `opacity 0; scaleY(0)→1`，0.8s `cubic-bezier(.2,0,0,1)`，`transform-origin: top center` | 归档作品卷轴展开（`_4`） |

其余微动效：滑块 `active:scale-110`、主按钮 `active:scale-[0.98]`、图片 `group-hover:scale-105`、tab 指示条 `scale-x` 过渡、按钮扫光（`linear-gradient(45deg, transparent 25%, rgba(255,255,255,.1) 50%, transparent 75%)` + `background-position` 过渡）。

## 六、文案与命名约定

- **界面词表**：卷宗（作品）、呈报/复核（处理）、封缄/落印（保存）、印信（服务）、档存（历史）、主阁（首页）、款识铃印（水印）、呈验（登录提交）、遗失密钥/密函/凭据（密码）、制印（新建印章）。
- **编号与日期**：中文数字——`卷宗第肆零玖号`（0409）、`ID: 0409-A`；日期用干支年——`庚子年 拾月 廿四`、`甲辰年 七月 廿一`；`贰寸 (3.5×5.3cm)` 尺寸写法。
- **状态标签**：`已封缄`（已保存）、`草稿`、`数据损坏`（`text-error`）、`已归档印记`。
- **指标**：`累计封缄`（保存数）、`存储空间 %`。

## 七、参考屏幕样板

| 屏 | 文件 | 内容 |
|---|---|---|
| _1 印信 | `references/screens/_1/code.html` | 证件照智能生成（选底色 + 执行置换 + 扣除印信积分） |
| _2 登录 | `references/screens/_2/code.html` | 卷宗查验登录（印信/手机号、密函/验证码、呈验按钮、角标纸卡） |
| _3 钤印 | `references/screens/_3/code.html` | Seal Lab 款识铃印（水印预览 + 设备签/留白滑块/字号分段/印章选择 + 落印） |
| _4 档存 | `references/screens/_4/code.html` | 呈报已复核成功页（stamp-in/fade-up/unfold-scroll 动效 + 卷轴木轴 + 御批印 + 返回主阁/分发令） |
| _5 调色 | `references/screens/_5/code.html` | Color Analysis 核心调色（LUM/CON/SAT/TMP 朱砂滑块 + 主体/背景 Tab + 按住对比 + 落印保存） |
| _6 首页 | `references/screens/_6/code.html` | Canvas Hub 卷轴（呈交新卷宗卡 + 近期归档横向滑 + 累计封缄/存储指标） |

> `_5` 是**调色核心屏**（与 PRD 亮度/对比度/饱和度/色温四滑块直接对应），`_3` 覆盖水印钤印，`_4` 是保存成功反馈，`_1/_6` 是入口与归档。

## 八、使用指引

1. **先读样板再动手**：实现任一界面时，先打开 `references/screens/` 对应 `code.html`，复用其 Tailwind 结构与 class，而不是重新发明。
2. **令牌必须一致**：颜色/字体/间距一律取 §二 令牌表，禁止引入令牌外的色值；Tailwind 配置即 `code.html` 内 `tailwind.config` 的 `theme.extend` 内容。
3. **HarmonyOS 迁移**：HTML/Tailwind 样板需转写成 ArkUI 时——颜色/字号取令牌；衬线标题映射到 Noto Serif SC（或 `HarmonyOS Sans SC` 加粗），等宽标签映射 `HarmonyOS Sans Mono`；控件动效用 ArkUI 的 `animation`/`transition` 复刻（stamp-in→scale+rotate、unfold-scroll→scaleY）。
4. **文案风格**：所有按钮、标签、状态沿用 §六 卷宗词表，保持"呈报复核"语境。
5. 设计令牌源文件见 `references/design-tokens/DESIGN.md`；若需更新风格，同步改它和 `code.html` 的 `tailwind.config`。
