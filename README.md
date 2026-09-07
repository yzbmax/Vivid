# Vivid (微霏)

HarmonyOS NEXT 原生图像调色与立轴装裱工具。基于 ArkTS、Native C++ 与 Vulkan Compute 构建。

---

## 概述

Vivid 是面向 HarmonyOS NEXT 开发的原生摄影后制与画卷装裱应用。应用以纯端侧、全离线架构为基石，不申请网络访问权限，不集成任何第三方数据统计或广告 SDK，所有图像解码、3D LUT 滤镜渲染、直方图采样诊断与立轴海报合成均在设备内部完成。

视觉与交互层遵循「文书钤印 · 案卷批注」（Mask & Seal）设计规范，将数码后期的选片、校色、加框与归档映射为文书呈报、御批复核、天头题签与金石落印。

---

## 核心特性与技术实现

### 1. 3D LUT 胶片滤镜引擎（Native C++ / Vulkan Compute）
- 解析 16³ 与 33³ 规格的 `.cube` 查找表文件。16³ 规格在 Native 层通过三线性插值重采样升维至 33³。
- 渲染管线优先调度 Vulkan Compute 执行 GPU 并行计算；在无 Vulkan 支持或驱动异常环境下，自动平滑降级至 CPU 三线性插值多线程计算，确保跨设备渲染结果一致。
- 编辑器预览采用异步代次控制（Generation Token），快速切换预设时丢弃并释放过期帧的中间 PixelMap，避免内存堆积与界面卡顿。
- 支持 0%–100% 滤镜强度线性调节。

### 2. 直方图明暗采样与智能题跋生成
- 像素级采样亮度分布，构建 256 阶灰度直方图。
- 算法识别四类主导影调：
  - 双峰大光比（阴阳错落）
  - 高调空灵（极目高明）
  - 低调沉郁（玄冥深致）
  - 均衡温润（素宣中正）
- 极端曝光诊断：对高光溢出、暗部死黑或灰蒙低对比场景生成官署校勘便签，输出针对性曝光与对比度修正建议。
- EXIF 全要素融合：解析拍摄时间戳（转译干支与四季节气节律）、焦距、光圈、快门（清洗厂商专有单位如 `sec.`，规范化为紧凑分数格式）与感光度，动态生成古籍风骨的案卷批注。

### 3. 东方立轴【题跋长卷】装裱导出
- 基于 `OffscreenCanvasRenderingContext2D` 实现长卷立轴图层的离屏光栅化合成。
- 合成要素包括：
  - 天头装裱与干支纪年题签
  - 原画画心装裱（内衬红边与四角留白）
  - 传统五色谱带（提取画面主导色并计算欧氏色彩距离，匹配最接近的中国传统国色名称及色值）
  - 卷宗案卷批注与 EXIF 参数矩阵
  - 朱砂防伪钤印（「神、逸、妙、阅、甲」五品品第印）与底栏金石款识
- 三级容错导出机制：优先通过离屏 Canvas 渲染并存入临时缓存；渲染异常时降级至编辑工作台单层渲染；针对示例作品支持资源管理器字节回退，杜绝空文件报错。

### 4. 原始画幅完整呈现与双列动态高度瀑布流
- 废除固定长宽比或容器高度裁剪，卡片组件基于真实分辨率计算宽高比（`naturalRatio`），配合 `ImageFit.Contain` 渲染。相机水印、参数底栏及各类画框完整展示，无裁切遮挡。
- 卷宗归档页采用双列高度平衡瀑布流算法。根据各卡片真实高宽比计算累积列高，动态将新卡片追加至较矮一列，消除传统横排因宽高比差异导致的空隙。
- 详情页采用沉浸式布局：顶栏固定常驻，长卷内容在下方平滑滚动；底部常驻悬浮操作条；中间配备「展卷详阅 · 案卷批注」指引胶囊，轻触即可平滑下滚查看完整批注。

### 5. 调色配方流转与操作历史栈
- 调色配方（ColorRecipe）：将色彩微调参数（亮度、对比度、饱和度、色温）、当前 LUT 标识、滤镜强度及局部调整参数打包为结构化 JSON，支持一键复制到剪贴板与跨作品粘贴复用。
- 双向操作历史栈（EditHistoryManager）：维护撤销（Undo）与重做（Redo）状态栈，单步回溯调色记录。
- 触感反馈（HapticService）：参数滑块滑动至 0 刻度时触发触觉顿挫反馈；支持双击标签数值直接归零。

### 6. 端侧隐私合规与 SaveButton 零权限保存
- 深度适配华为系统安全控件 `SaveButton`。用户点击保存按钮即可直接写入相册公共目录，无需声明或申请全局相册读写权限（`ohos.permission.WRITE_IMAGEVIDEO`）。
- 首选项持久化管理（PreferencesHelper）：基于 `@kit.ArkData` preferences 实现读写与异步刷盘（`flush`）。具备上下文自愈检测，首次安装冷启动时弹出合规指引，用户确认后状态持久化存盘，后续冷启动绝不重复弹窗。
- 【卷宗案牍志】创作看板：从本地沙箱实时统计已归档卷宗总量、草稿数、主导影调聚类与设色冷暖风骨，全程无云端同步依赖。

---

## 设计系统：Mask & Seal 规范

Vivid 界面遵循「炎国卷轴 · 文书钤印」视觉语言，核心隐喻对应如下：

| 领域对象 | 对应隐喻 | 界面用途 |
|---|---|---|
| 摄影作品 / 导入图片 | 卷宗 (Archive) | 列表项、详情展示主体 |
| 图像滤镜与参数调节 | 呈报 (Submit) | 编辑工坊调节行为 |
| 预览与比对效果 | 复核 (Audit) | 长按对比、官署校勘 |
| 存盘与相册导出 | 封缄 / 落印 (Seal) | 保存作品、相册输出 |
| 系统服务与沙箱存储 | 印信 (Credential) | 证书凭据、本地存储说明 |
| 历史创作数据统计 | 档存 (Records) | 卷宗案牍志看板 |

### 设计令牌（Design Tokens）

| 令牌常量 | 色值 / 尺寸 | 用途说明 |
|---|---|---|
| `Theme.PAPER_BASE` | `#DEDDD7` | 宣纸灰。全局页面底色，叠印细网格背景 |
| `Theme.PAPER_SURFACE` | `#F2F1ED` | 浅纸白。卡片、模态层与输入面板表面 |
| `Theme.PRIMARY` | `#7B171B` | 深朱砂。核心主按钮、强调标题、选中状态 |
| `Theme.SEAL_RED` | `#B23B2F` | 钤印红。印章印鉴、滑块游标、指示条 |
| `Theme.ON_SURFACE` | `#241918` | 正文墨色。标题与主要正文字体颜色 |
| `Theme.ON_SURFACE_VARIANT` | `#574140` | 次级文字。注释说明、时间戳、等宽标签文字 |
| `Theme.FONT_SERIF` | `Noto Serif SC, Noto Serif` | 衬线体。用于页面顶栏、卡片标题及古典题跋 |
| `Theme.FONT_MONO` | `monospace` | 等宽体。用于卷宗编号、指标数值与光学参数 |

---

## 系统架构

```
+-------------------------------------------------------------------------+
|                       表现层 (ArkUI / Mask & Seal)                       |
|  Index (三Tab) | HomePage (主阁) | WorksPage (瀑布流) | MinePage (案牍志)  |
|  EditPage (调色工坊) | WorkDetailPage (长卷展阅) | ColophonExportDialog  |
+-------------------------------------------------------------------------+
                                     |
+------------------------------------+------------------------------------+
|                         领域模型与状态管理层                                |
|  WorkRepository (卷宗持久化仓库)     |  DraftStore (断点草稿管理)           |
|  ImageToneModels (直方图与影调模型)   |  ArchiveStats (案牍创作统计聚类)     |
|  ColorRecipe (调色配方数据契约)      |  WorkUiState (响应式事件总线)        |
+------------------------------------+------------------------------------+
                                     |
+------------------------------------+------------------------------------+
|                           服务与核心计算层                               |
|  ColophonScrollRenderer (立轴光栅化)  |  ImageToneAnalyzer (直方图采样分析)  |
|  ExifReaderService (EXIF参数清洗)    |  ColorRecipeStore (配方序列化流转)   |
|  HapticService (触觉反馈服务)        |  PhotoExportService (相册保存服务)   |
+------------------------------------+------------------------------------+
                                     |
+------------------------------------+------------------------------------+
|                    Native 计算核心 (C++20 / NAPI)                       |
|  NAPI 跨语言桥接层   |  3D LUT (.cube) 解析器                             |
|  Vulkan Compute GPU 滤镜引擎         |  CPU 三线性插值多线程渲染器           |
+------------------------------------+------------------------------------+
                                     |
+------------------------------------+------------------------------------+
|                      HarmonyOS 系统基础能力 (Kits)                       |
|  @kit.MediaLibraryKit (PhotoViewPicker / SaveButton)                    |
|  @kit.ArkData (preferences 物理刷盘)                                    |
|  @kit.ArkUI (OffscreenCanvas / 沉浸式窗口 / EdgeEffect.Spring)          |
|  @kit.AbilityKit (UIAbility 生命周期 / 上下文管理)                        |
+-------------------------------------------------------------------------+
```

---

## 工程目录结构

```text
Vivid/
├── entry/src/main/
│   ├── cpp/
│   │   ├── filter/                  # 3D LUT 解析、CPU插值与 Vulkan Compute 实现
│   │   │   ├── cube_reader.cpp      # .cube 文件语法解析器
│   │   │   ├── filter_engine.cpp    # 滤镜调度引擎 (GPU/CPU 切换)
│   │   │   └── vulkan_lut_pipeline.cpp # Vulkan 计算着色器管线
│   │   └── napi/                    # ArkTS 与 C++ 数据转换及 PixelMap 映射
│   ├── ets/
│   │   ├── components/              # ArkUI 组件实现
│   │   │   ├── common/              # PaperFrame, PageHeader, NotesCard, Theme
│   │   │   ├── editor/              # 预览画布、滤镜胶卷、参数面板、边框与文字
│   │   │   ├── home/                # 首页各功能区块
│   │   │   ├── mine/                # 卷宗案牍志创作看板
│   │   │   └── works/               # WorkCard (自然比例), WorkGrid (双列瀑布流)
│   │   ├── models/                  # 数据契约与仓储模型
│   │   │   ├── ArchiveStats.ets     # 创作统计与影调分类聚类模型
│   │   │   ├── ColophonModels.ets   # 题跋长卷配置与五色谱数据模型
│   │   │   ├── ColorRecipe.ets      # 调色配方数据契约
│   │   │   ├── ImageToneModels.ets  # 直方图数据与极端明暗诊断模型
│   │   │   ├── TraditionalColorCatalog.ets # 中国传统五色谱字典 (近百种标准色值)
│   │   │   ├── WorkRecord.ets       # 卷宗主模型
│   │   │   └── WorkRepository.ets   # 卷宗沙箱存储仓库
│   │   ├── pages/                   # 独立路由页面
│   │   │   ├── Index.ets            # 三 Tab 框架与冷启动隐私检测
│   │   │   ├── EditPage.ets         # 核心图像调色与多层编辑工作台
│   │   │   ├── WorkDetailPage.ets   # 作品装裱长卷详情页
│   │   │   └── WorksPage.ets        # 全部卷宗归档页
│   │   ├── services/                # 业务核心服务
│   │   │   ├── ColophonScrollRenderer.ets # 题跋立轴全卷合成光栅化渲染器
│   │   │   ├── ColorRecipeStore.ets # 配方复制与跨作品应用服务
│   │   │   ├── ExifReaderService.ets # EXIF 光学参数提取与清洗
│   │   │   ├── HapticService.ets    # 触感震动反馈服务
│   │   │   ├── ImageToneAnalyzer.ets # 图像直方图采样与曝光诊断引擎
│   │   │   ├── PhotoExportService.ets # 结合 SaveButton 的相册保存服务
│   │   │   └── WorkSaveService.ets  # 卷宗入库与图片文件落盘
│   │   └── utils/                   # 工具函数
│   │       ├── PreferencesHelper.ets # 首选项多实例异步持久化管理
│   │       └── WorkImageUtils.ets   # 图像物理分辨率探测与 URI 协议规范化
│   └── resources/                   # 字体、预设 LUT、矢量图标及多语言配置
└── tools/                           # 自动化单元测试与规范校验脚本
```

---

## 开发与构建环境

### 前置要求
- 操作系统：macOS / Windows / Linux
- 开发环境：Huawei DevEco Studio 6.0+ 或 6.24+
- SDK 版本：HarmonyOS NEXT Developer Beta (API 12+)
- 运行环境：纯鸿蒙系统手机或配套模拟器
- Node.js：v18.0.0 或更高版本 (测试执行依赖)

### 构建与测试指令
```bash
# 1. 克隆仓库
git clone git@github.com:yzbmax/Vivid.git
cd Vivid

# 2. 安装项目依赖
ohpm install

# 3. 执行全量单元测试与动效规范校验
for f in tools/test-*.cjs; do node "$f" || exit 1; done
node tools/verify-edge-effect.cjs
```

通过 DevEco Studio 打开工程目录，完成本地签名配置后，选择运行目标设备直接部署。

---

## 自动化测试体系

项目采用测试驱动开发（TDD）模式，测试脚本位于 `tools/` 目录，无需启动真机即可秒级完成关键业务与算法验证：

| 测试脚本 | 验证范围 |
|---|---|
| `test-archive-stats.cjs` | 案牍指标聚合、汉字大写编号转译、主导影调聚类与设色风骨计算 |
| `test-colophon-export-flow.cjs` | 题跋装裱弹窗生命周期、沙箱临时副本生成与相册导出链路 |
| `test-colophon-renderer.cjs` | 题跋长卷离屏 Canvas 排版、五色谱带提取与朱砂方印绘制 |
| `test-color-palette.cjs` | 传统色谱提取、欧氏色彩距离计算与最近邻国色匹配 |
| `test-compare-overlay.cjs` | 原图与调色图实时对比蒙版几何定位与触控防抖 |
| `test-editor-composition.cjs` | 编辑器多图层合成、边界限制、代次控制与 PixelMap 释放 |
| `test-haptic-and-reset.cjs` | 触感震动反馈参数传递与滑块双击复位逻辑 |
| `test-privacy-flow.cjs` | 隐私政策首次冷启动检测、Preferences 上下文自愈与写盘持久化 |
| `test-recipe-store.cjs` | 调色配方数据契约完整性、序列化与剪贴板存取流转 |
| `test-save-flow.cjs` | SaveButton 安全控件集成规范与免弹窗导出降级机制 |
| `test-text-logic.cjs` | 文字图层多行排版、Unicode 码点计算、旋转拖拽夹紧算法 |
| `test-tone-analyzer.cjs` | 直方图分布判定、大光比识别与极端明暗官署校勘诊断 |
| `test-undo-redo.cjs` | 编辑器单步撤销与重做双向历史栈状态一致性 |
| `test-work-resolution.cjs` | 真实物理分辨率探测、WorkCard 原本比例与自适应瀑布流 |
| `verify-edge-effect.cjs` | 全局 20 处滚动容器（垂直长卷与水平选择栏）弹性边界反馈（EdgeEffect.Spring）覆盖校验 |

---

## 代码规范与开发约定

1. **ArkUI 图像加载与沙箱文件规范**：
   - `<Image>` 组件加载沙箱文件（`filesDir` / `cacheDir`）必须携带 `file://` 协议前缀，严禁传入裸绝对路径 `/data/...`。
   - 持久化图片必须包含真实扩展名（`.jpg` / `.png` / `.webp`），禁止无扩展名写入。
   - 所有展示组件统一通过 `resolveWorkImageSource` 处理图片来源，包含完整的三级回退策略（`previewImageUri > sourceImageUri > 内置画作资源`）。
2. **ArkTS 强类型约束**：
   - 严禁在非必要场景使用 `any`，所有异步服务及数据转换均提供完整接口契约。
3. **Canvas 装裱防撞与双行折叠**：
   - 绘制底栏相机水印与 EXIF 参数时，预估左右两侧所需宽度；窄画幅超出可用宽度时，自动折叠为双行紧凑排版。

---

## 许可证

本项目依据 [Apache License 2.0](LICENSE) 许可协议开源。
```
Copyright 2026 Vivid Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
