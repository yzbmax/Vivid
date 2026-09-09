# AGENTS 规则

本仓库为 Vivid（HarmonyOS 蒙版调色原型）三分支合并后的集成分支。

## 文件删除规则

- 删除任何文件前，先确认没有代码仍在引用它（grep 核实 import / 资源引用）。
- 一次只删除一个明确路径的文件，不做批量删除。
- 每个删除动作独立提交，提交信息中写明被删文件路径与原因。

## ArkUI 图像加载与沙箱文件规范

- **URI 协议规范**：ArkUI `<Image>` 组件加载应用沙箱（`filesDir` / `cacheDir`）内的本地文件时，**必须带有 `file://` 协议前缀**（例如 `file:///data/storage/el2/...`）。严禁直接向 `<Image>` 传入裸文件绝对路径 `/data/...`，否则 ArkUI 会静默丢弃并导致白屏。
- **标准文件扩展名**：所有持久化或缓存的图片必须带有真实格式后缀（`.jpg` / `.png` / `.webp`），严禁使用 `.image` 或无扩展名，确保 ArkUI 底层解码引擎能正确分配解码器。
- **统一路径规整与兜底**：UI 卡片与展示组件必须通过统一工具（如 `resolveWorkImageSource` / `fixAndNormalizePath`）对图片源做规范化，并具备优雅回退策略（`previewImageUri > sourceImageUri > 内置画作资源`），避免因缓存清理产生空白卡片。

## Canvas 装裱与相机水印排版规范

- **画幅自适应与防撞检测**：绘制底栏相机水印、参数与 Logo 时，必须在绘制前预估左右两侧内容所需宽度。
- **竖屏双行折叠策略**：当画布处于窄画幅（竖屏）且单行所需宽度超出可用范围时，必须自动利用充足的纵向高度切换为双行紧凑平衡排版：
  - 左侧：上行为设备型号，下行为品牌徽标（省去横向分割竖线）；
  - 右侧：上行为拍摄参数，下行为拍摄时间。
- **参数文本规整**：EXIF 格式化时必须清洗相机厂商自带的单位字符串（如 `sec.` 或 `sec`），统一规范为紧凑标准的快门时间（如 `1/1000s`），杜绝拼出 `1/1000 sec.s`。

## ArkUI 滚动容器嵌套与自适应瀑布流规范

- **严禁在未定高 `Scroll` 中直接嵌套 `WaterFlow` / `List` / `Grid`**：当页面外层使用纵向主 `Scroll`（如全卷轴统一滑动体验）时，严禁在内部放置未限制绝对高度的 `WaterFlow`。ArkUI 对无限高度子容器的视口度量异常，会导致 `columnsGap` 间距归零碰撞、右侧卡片截断越界以及卡片上下重叠。
- **全卷轴瀑布流推荐模式**：在单页纵向 `Scroll` 结构中，作品双列自适应瀑布流必须采用 `Row({ space: Theme.GUTTER })` 嵌套双 `Column({ space: Theme.GUTTER })`（均配置 `.layoutWeight(1)`），并结合长宽比进行单次遍历的贪心高度平衡分流。
- **卡片画幅安全钳制与规范圆角**：自适应原本画幅的卡片容器必须设置规范圆角（`Theme.RADIUS_DEFAULT`）与 `.clip(true)`；在根据图片原始尺寸计算 `aspectRatio` 时，必须钳制在安全区间（如 `[0.5, 2.0]`），严防极端长条画幅挤占破坏整体排版。

## Native / ArkTS 跨语言状态同步与高频交互渲染规范

- **真实源单向同步，严禁 ArkTS 维护本地假缓存**：
  - 当 C++ 底层具备 LRU 淘汰或动态内存回收时，ArkTS 端**严禁**维护脱节的静态或局部数组（如 `loadedFilterIds: string[]`）来自行判断资源是否在内存中。
  - 必须通过 NAPI 导出的真源查询接口（如 `FilterNativeBridge.hasLut(id)`）直连 C++ 内存表。
  - 渲染管线入口必须具备自愈机制：如果资产未在 C++ 驻留，必须在毫秒级内自动静默重新加载，严禁直接发起未就绪资产的 `render` 请求导致 Promise 异常挂起和 UI 冻结。
- **高频交互请求合流（Request Conflation / Coalescing）**：
  - 滤镜快速连续点击、参数滑块高频拖拽等场景，必须在调度层（如 `PreviewPipeline`）实现**请求合流**。
  - 排队深度必须严格限制在 $\le 1$：当底层正在渲染时，新进请求只更新 `pendingTask`，先前排队的过时请求立即以 `undefined` 提前完结，绝不允许数十个高分辨率渲染任务在 Worker/C++ 线程池中无序堆积。
- **PixelMap 安全换图双缓冲时序（Swap First, Release Later）**：
  - ArkUI `<Image>` 依赖 `@State` 响应式驱动绘制。换图时必须**先**将新生成的 PixelMap 赋值给 `@State previewPixelMap`，让 UI 绑定新句柄，**随后**再调用上一帧旧 PixelMap 的 `release()` 方法。
  - 严禁在给 UI 赋值前提前释放旧句柄，避免 ArkUI 在当前渲染帧重绘已释放显存表面导致野指针、白屏或图形管线挂起。
- **Native 热循环零堆分配（Zero-Alloc Native Loop）**：
  - 在高频执行的 Native 渲染代码中（如 Vulkan/CPU 滤镜核心循环），严禁每帧使用 `std::vector<uint8_t>` 或 `malloc` 反复分配数兆字节图像缓冲区。
  - 必须使用类成员持久化复用缓冲区（如 `fallbackCheckBuffer_`），仅在尺寸增长时按需 `resize`，彻底消除海量大内存分配释放产生的系统碎片与卡顿。
- **ArkTS 严格模式泛型与高阶闭包显式返回类型（arkts-no-implicit-return-types）**：
  - 传递给高阶函数（如 `keepLatest`、`new Promise`、事件回调）的所有匿名箭头函数与闭包，必须显式声明返回类型（如 `(): Promise<image.PixelMap> => { ... }`、`(): void => { ... }`），严禁依赖隐式推导。

## 华为应用市场审核与上架合规规范

- 开发、重构与提审必须遵循 `.agents/skills/huawei-app-review/SKILL.md`（华为应用市场审核指南 Skill）。
- **隐私弹窗与零调用铁律**：首次启动必须有明确“同意”与“拒绝”，用户同意前绝不调用设备标识或三方 SDK；拒绝后绝不退出或循环弹窗。
- **权限最小化与优雅降级**：必须在具体业务触发时动态申请，严禁启动时一揽子索权；`reason` 必须精准说明使用场景；拒绝后保留主功能可用性。
- **Release 构建要求**：提审包必须关闭调试模式（`debuggable: false`），开启混淆，验证通过 IPv6 环境。

