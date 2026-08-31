# Vivid AI 主体识别与背景分离蒙版实施计划 V2

## 1. 目标

在现有 `EditPage` 中接入 HarmonyOS Core Vision Kit 主体分割能力，实现：

- 自动识别图片中的显著主体；
- 将主体与背景转换为逐像素软蒙版；
- 主体和背景分别进行亮度、对比度、饱和度、色温调节；
- 调色过程中不重复调用 AI；
- 预览与最终导出使用完全一致的区域混合算法；
- 尽量避免当前 DEMO 中出现的“识别鼠标时把鼠标周围桌面一起调色”的问题；
- 为后续手动修正、多主体选择、AI 精修预留接口。

本轮 V1 不做：

- 手动画笔修补蒙版；
- 多主体分别调色；
- 点击指定主体；
- 天空/人物/宠物等语义分类；
- 云端生成式 AI；
- 跨应用重启的完整草稿恢复。

---

# 2. 核心技术原则

本方案最重要的原则：

**Core Vision 的 `subjectRectangle` 只能用于调试、包围框展示和结果合法性校验，禁止作为最终主体调色范围。**

最终主体调色必须来自：

```typescript
SegmentationResult.fullSubject.mattingList
```

Core Vision 返回的 `mattingList` 是基于原图尺寸的一维主体蒙版：

```text
0       = 背景
255     = 主体
1 ~ 254 = 主体概率 / 软边缘
```

因此正确的主体区域应当跟随鼠标、人物、宠物等真实轮廓，而不是一个矩形框。

最终技术链路调整为：

```text
PhotoViewPicker
        ↓
图片解码 RGBA_8888
        ↓
SubjectSegmentationService
        ↓
Core Vision Kit
        ↓
RawMask
        ↓
MaskProcessor
        ↓
EditMask
        ↓
PreviewRenderWorker
        ↓
PreviewArea
        ↓
WorkSaveService
        ↓
最终导出
```

其中：

```text
RawMask
```

代表 Core Vision 原始 `mattingList`。

```text
EditMask
```

代表经过尺寸校验、置信度处理和必要清理后，真正供 Vivid 调色系统使用的蒙版。

---

# 3. AI 能力

使用：

```typescript
import { subjectSegmentation } from '@kit.CoreVisionKit';
```

系统能力：

```text
SystemCapability.AI.Vision.SubjectSegmentation
```

Core Vision Kit 在本项目中只负责：

```text
图片
 ↓
识别显著主体
 ↓
输出逐像素主体概率蒙版
```

它不负责：

- 亮度；
- 对比度；
- 饱和度；
- 色温；
- 主体/背景最终合成。

上述调色全部由 Vivid 自己的图像渲染器完成。

Core Vision 官方将该能力定义为“显著主体分割”，用于识别并分离区别于背景的前景物体或区域，并明确包含“单独编辑前景主体”等图像编辑场景。

---

# 4. AI 输入规格

AI 工作图统一转换为：

```text
RGBA_8888
```

Vivid 自己限制：

```text
最长边 ≤ 1920px
```

该 1920px 是 Vivid 的性能策略，不是 Core Vision SDK 限制。

目的：

- 控制 AI 输入耗时；
- 控制 PixelMap 内存；
- 避免直接对 4K / 8K 原图做主体识别；
- 保证不同设备体验相对稳定。

流程：

```text
原始图片
例如 4032 × 3024
        ↓
按比例缩放
        ↓
AI 工作图
1920 × 1440
        ↓
Core Vision
        ↓
RawMask
1920 × 1440
```

预览阶段根据实际显示区域再次缩放：

```text
Raw/Edit Mask
1920 × 1440
        ↓
双线性缩放
        ↓
Preview Mask
例如 900 × 675
```

最终保存时再将 EditMask 映射到最终导出尺寸。

---

# 5. SubjectSegmentationService

新增：

```text
SubjectSegmentationService
```

负责：

```text
AI 生命周期
Core Vision API 调用
PixelMap 输入
SDK Error 映射
SegmentationResult 解析
资源释放
超时 / 取消
```

页面不得直接处理 Core Vision 的返回结构。

建议提供统一接口：

```typescript
interface SegmentationOutput {
  rawMask: MaskData;
  subjectCount: number;
  subjectBounds: RectData;
}
```

公共类型：

```typescript
interface MaskData {
  width: number;
  height: number;
  weights: Uint8Array;
}

interface RectData {
  left: number;
  top: number;
  width: number;
  height: number;
}
```

Core Vision 原始：

```typescript
Int32Array
```

转换为：

```typescript
Uint8Array
```

降低内存占用。

---

# 6. Core Vision 配置

正式版本基础配置：

```typescript
{
  maxCount: 6,
  enableSubjectDetails: false,
  enableSubjectForegroundImage: false
}
```

使用：

```typescript
result.fullSubject.mattingList
```

作为全部显著主体的联合 RawMask。

不使用：

```typescript
result.fullSubject.subjectRectangle
```

作为蒙版。

`subjectRectangle` 只允许用于：

```text
Debug 可视化
结果合法性验证
日志
主体包围区域统计
```

禁止出现类似：

```typescript
if (
  x >= rect.left &&
  x <= rect.right &&
  y >= rect.top &&
  y <= rect.bottom
) {
  // subject
}
```

这样的最终调色逻辑。

因为这种实现实际上是在调一个矩形区域，不是调 AI 主体。

---

# 7. maxCount 验证策略

Core Vision 当前允许：

```text
maxCount = 1 ~ 20
默认 = 6
```

Vivid 第一阶段继续以：

```text
maxCount = 6
```

作为默认候选方案。

但是正式锁定参数前，必须额外做：

```text
maxCount = 1
vs
maxCount = 6
```

AB 测试。

重点测试：

```text
鼠标
耳机
杯子
键盘
人物
多人合照
宠物
商品
桌面杂物
```

判断：

```text
maxCount = 1
```

是否更适合“单一主要物体”。

以及：

```text
maxCount = 6
```

是否更适合“多人 / 多主体”。

如果后续发现商品类图片使用 `6` 容易把多个周边物体都划入主体，可增加：

```typescript
type SegmentationPolicy =
  'primarySubject' |
  'allSalientSubjects';
```

V1 暂时不在 UI 中暴露该选项。

---

# 8. RawMask 强制验证

这是本版本新增的关键步骤。

Core Vision 返回后必须首先验证：

```typescript
mattingList.length === width * height
```

同时检查：

```text
至少存在一个 > 0 权重
至少存在有效主体区域
subjectRectangle 合法
宽高大于 0
坐标没有越界
```

失败则进入：

```text
SegmentationStatus.error
```

禁止继续进入区域调色。

---

# 9. Debug Mask Viewer

在正式开发双区域编辑前，必须先实现一个 Debug 页面或 Debug 模式。

每次主体识别必须能够查看四种结果：

## A. Original

原始输入图片。

## B. Subject Rectangle

在原图上只绘制：

```text
红色 Bounding Box
```

该视图只证明 AI 判断出的主体大致位置。

## C. Raw Mask

直接将 `mattingList` 映射成灰度图：

```text
0   → 黑
128 → 灰
255 → 白
```

该视图不经过任何 MaskProcessor。

## D. Mask Overlay

在原图基础上：

```text
主体区域 → 半透明朱砂红
背景区域 → 半透明青绿色
```

按照真实 Mask 权重混合。

Debug 页面用于判断当前异常到底属于：

```text
1. 错误使用 subjectRectangle
2. mattingList 读取错误
3. Mask 尺寸映射错误
4. 宽高方向错误
5. fullSubject 合并了多个显著主体
6. Core Vision 本身分割不准确
```

在这一步通过之前，不进入正式调色功能开发。

---

# 10. MaskProcessor

新增：

```text
MaskProcessor
```

架构：

```text
Core Vision mattingList
        ↓
RawMask
        ↓
MaskProcessor
        ↓
EditMask
```

职责：

```text
尺寸校验
权重归一
低置信度噪声抑制
软边缘保护
Mask 尺寸转换
生成预览 Mask
```

V1 不对蒙版做粗暴二值化。

禁止：

```typescript
mask >= 128 ? 255 : 0
```

因为这样会破坏：

```text
头发
动物毛发
衣服边缘
半透明边缘
曲线物体
```

Core Vision 已经提供连续 0～255 权重，应保留软边缘。

---

# 11. 置信度映射

当前 DEMO 出现“主体周围区域轻微跟着改变”的情况下，需要区分：

```text
真正主体：
220 ~ 255

主体边缘：
80 ~ 220

AI 不确定的周围区域：
10 ~ 60

真正背景：
0 ~ 10
```

可加入可调的置信度重映射曲线。

例如：

```text
RawMask
    ↓
Normalize 0~1
    ↓
Confidence Curve
    ↓
EditMask
```

效果目标：

```text
很低概率区域
→ 更接近 0

中高概率区域
→ 保留软边缘

高概率主体
→ 接近 255
```

但 V1 不允许直接写死一个未经测试的强阈值。

建议参数集中管理：

```typescript
interface MaskTuningConfig {
  lowConfidence: number;
  highConfidence: number;
}
```

并通过测试集确定最终值。

默认原则：

```text
抑制低置信污染
≠
强行裁掉主体边缘
```

---

# 12. 禁止固定腐蚀作为默认方案

V1 不默认执行：

```text
Mask Erode
固定向内缩
```

因为虽然它可以减少鼠标周围背景污染，却很容易损坏：

```text
发丝
宠物毛发
衣服边缘
耳机线
植物叶片
细小物体
```

如果后续测试证明有必要，可以让 MaskProcessor 支持：

```text
轻量形态学处理
```

但必须作为独立可关闭策略，而不是写死在主流程中。

---

# 13. 区域调色数据模型

```typescript
type RegionKey = 'subject' | 'background';

interface AdjustParams {
  brightness: number;
  contrast: number;
  saturation: number;
  temperature: number;
}

interface RegionAdjustments {
  subject: AdjustParams;
  background: AdjustParams;
}
```

蒙版：

```typescript
interface MaskData {
  width: number;
  height: number;
  weights: Uint8Array;
}
```

持久化引用：

```typescript
interface MaskRef {
  uri: string;
  width: number;
  height: number;
  version: 1;
}
```

识别状态：

```typescript
type SegmentationStatus =
  'idle'
  | 'preparing'
  | 'segmenting'
  | 'processingMask'
  | 'ready'
  | 'error';
```

---

# 14. 区域像素合成算法

固定处理顺序：

```text
饱和度
→
对比度
→
亮度
→
色温
```

参数映射：

```text
亮度：
brightness / 100 × 0.25

对比度：
1 + contrast / 100 × 0.9

饱和度：
1 + saturation / 100 × 0.8

色温：
temperature / 100 × 0.12
```

色温：

```text
正值：
增加红通道
降低蓝通道

负值：
降低红通道
增加蓝通道
```

每个像素先计算：

```text
subjectAdjusted

backgroundAdjusted
```

然后：

```text
w = EditMask[pixelIndex] / 255

output =
subjectAdjusted × w
+
backgroundAdjusted × (1 - w)
```

例如：

```text
Mask = 255

100% 使用主体参数
```

```text
Mask = 0

100% 使用背景参数
```

```text
Mask = 128

约 50% 主体
+
50% 背景
```

这样可以保持自然的边缘过渡。

---

# 15. Alpha 规则

必须保留原图 Alpha。

双区域调色不得修改透明度。

当：

```text
subject 参数全部为 0

且

background 参数全部为 0
```

结果必须：

```text
逐字节等于输入图
```

该项加入单元测试。

---

# 16. PreviewRenderWorker

AI 与调色必须彻底解耦。

正确流程：

```text
AI
↓
一次性得到 EditMask
↓
缓存
```

之后：

```text
拖动亮度
拖动饱和度
切换主体
切换背景
```

都不得重新调用：

```text
doSegmentation()
```

Worker 会话初始化时缓存：

```text
Preview RGBA
Preview Mask
宽高
```

之后滑块变化只发送：

```typescript
interface RenderRequest {
  generation: number;
  adjustments: RegionAdjustments;
}
```

---

# 17. 预览代次控制

每次修改：

```text
generation++
```

例如：

```text
100
101
102
103
```

Worker 即使先完成了：

```text
101
```

如果当前已经：

```text
generation = 103
```

则：

```text
101 结果直接丢弃
```

防止旧帧覆盖最新滑块状态。

Worker 需要支持：

```text
任务合并
过期任务丢弃
最新任务优先
```

---

# 18. 预览分辨率

拖动滑块时禁止无条件按照 AI 1920px 工作图处理。

使用：

```text
实际 PreviewArea 尺寸
```

生成预览 Buffer。

例如：

```text
屏幕实际显示：
900 × 675
```

则：

```text
Preview RGBA
900 × 675

Preview Mask
900 × 675
```

Worker 只处理：

```text
607,500 pixels
```

最终保存时才进入高分辨率渲染。

目标是：

```text
拖动滑块
→
快速反馈

松手
→
最终稳定帧

保存
→
高质量完整渲染
```

---

# 19. EditPage 职责

`EditPage` 只负责：

```text
页面状态
会话管理
选择图片
触发 AI
切换区域
接收 Worker 预览
保存
错误状态
```

禁止 `EditPage`：

```text
直接解析 mattingList
实现 Pixel 循环
实现 Mask 缩放
重复实现保存逻辑
处理 Core Vision SDK 细节
```

---

# 20. UI 状态

选图完成后：

```text
正在准备 AI 能力…
```

然后：

```text
正在识别主体…
```

随后：

```text
正在优化主体边缘…
```

完成后：

```text
主体已识别
```

播放一次约：

```text
0.6s
```

Mask & Seal 风格盖章反馈。

之后解锁：

```text
主体
背景
```

两个 Tab。

---

# 21. 主体 / 背景 Tab

位于调整面板上方：

```text
主体 | 背景
```

使用现有：

```text
Mask & Seal
朱砂指示条
```

切换区域时：

```text
不重新调用 AI
不重建蒙版
不丢失另一区域参数
```

例如：

```text
主体：
亮度 +20

背景：
亮度 -15
```

来回切换仍保持各自状态。

---

# 22. PreviewMode

```typescript
type PreviewMode =
  | 'effect'
  | 'original'
  | 'mask';
```

## effect

显示最终区域调色结果。

## original

用户按住“原图”时：

```text
显示未处理原图
```

松开：

```text
恢复 effect
```

## mask

用户按住“查看分区”：

```text
原图作为底图

主体：
朱砂红半透明覆盖

背景：
青绿色半透明覆盖
```

必须使用真正的 `EditMask` 权重。

不能使用 `subjectRectangle`。

`original` 和 `mask`：

```text
互斥
```

---

# 23. AI 失败 UX

失败时禁止继续主体 / 背景调色。

显示：

```text
主体识别失败
```

提供：

```text
重新识别
更换图片
```

需要区分内部错误：

```text
AI 初始化失败
SDK 超时
运行异常
无主体
RawMask 长度错误
Mask 空数据
Bounding Box 无效
图片解码失败
MaskProcessor 失败
操作取消
```

UI 不必全部显示技术错误，只用于日志与诊断。

---

# 24. 图片主体过小

Core Vision 官方限制之一是：

```text
主体占原图不足约 0.5%
可能不会被识别为主体
```

因此当：

```text
subjectCount == 0
```

或 RawMask 没有有效主体时：

显示：

```text
没有识别到明显主体
```

而不是：

```text
AI 服务异常
```

两者属于不同错误。

---

# 25. 蒙版文件

保存：

```text
filesDir/
└── works/
    └── {workId}/
        └── subject-mask.bin
```

文件内容：

```text
Uint8Array
```

同时保存：

```text
width
height
version
```

通过：

```typescript
MaskRef
```

引用。

---

# 26. WorkRecord

旧：

```typescript
adjustments
```

替换为：

```typescript
regionAdjustments
subjectMask
lastRegion
```

例如：

```typescript
interface WorkRecord {
  id: string;
  regionAdjustments: RegionAdjustments;
  subjectMask?: MaskRef;
  lastRegion: RegionKey;
}
```

`MockWorkStore.create()` 必须接受并保留调用方已经生成的：

```text
workId
```

禁止 Store 再重新生成 ID。

否则：

```text
WorkRecord ID
```

和：

```text
works/{workId}/subject-mask.bin
```

会失去对应关系。

---

# 27. 会话续编

V1 当前只承诺：

```text
同一应用进程内续编
```

可以直接复用：

```text
Mask
RegionAdjustments
```

不重复识别。

如果：

```text
Mask 文件缺失
Mask 文件损坏
尺寸不一致
版本不支持
```

则：

```text
要求重新识别
```

当前版本不把这种能力描述成完整“跨重启草稿”。

真正的跨应用重启草稿恢复另开本地持久化任务实现。

---

# 28. WorkSaveService

所有正式保存统一通过：

```text
WorkSaveService
```

流程：

```text
确认最新 RegionAdjustments
        ↓
读取 EditMask
        ↓
加载最终输出尺寸图片
        ↓
区域高质量渲染
        ↓
图片编码
        ↓
写入相册
        ↓
更新 WorkRecord
```

禁止：

```text
EditPage 自己保存一次

详情页再实现一套保存

作品页再实现另一套导出
```

统一使用同一套 renderer。

---

# 29. AI 识别与导出解耦

最终保存禁止再次无条件运行 AI。

应直接复用：

```text
subject-mask.bin
```

AI 只在以下情况重新运行：

```text
用户更换图片
Mask 不存在
Mask 损坏
Mask 版本不兼容
用户主动重新识别
```

---

# 30. 页面资源生命周期

页面离开、换图或销毁时：

```text
sessionGeneration++
```

让旧任务自动失效。

释放：

```text
Worker
PixelMap
ImageSource
ArrayBuffer
文件句柄
AI Service
```

避免编辑多张照片后内存持续上涨。

---

# 31. 第一阶段必须完成的技术验证

正式接入 EditPage 前先完成：

```text
Core Vision Debug Demo
```

至少验证：

```text
鼠标
键盘
耳机
杯子
商品
单人
多人
宠物
植物
复杂背景人物
逆光主体
主体与背景近似色
```

每类至少准备若干图片。

必须能同时查看：

```text
Original
Bounding Box
RawMask
Mask Overlay
```

---

# 32. 问题判断标准

如果鼠标周围环境一起改变：

## 情况 A

RawMask 很准确，但调色结果变成矩形。

结论：

```text
Renderer / Bounding Box 使用错误
```

## 情况 B

RawMask 很准确，但 Overlay 偏移。

结论：

```text
Mask 尺寸或坐标映射错误
```

## 情况 C

RawMask 本身已经把桌面涂成灰白。

结论：

```text
Core Vision 低置信区域污染
```

进入：

```text
MaskProcessor 调优
```

## 情况 D

RawMask 将键盘、鼠标、杯子一起判断为主体。

结论：

```text
fullSubject / maxCount 策略问题
```

对比：

```text
maxCount 1
maxCount 6
```

## 情况 E

主体与周边全部高权重。

结论：

```text
Core Vision 原始模型能力边界
```

不能通过 Renderer 修复，需要后续考虑：

```text
手动修正
其他分割能力
交互式主体选择
```

---

# 33. 单元测试

覆盖：

- `mattingList → Uint8Array` 转换；
- Mask 长度校验；
- 全零 Mask；
- 0 / 128 / 255 权重；
- RawMask → EditMask；
- 低置信区域抑制；
- 软边缘不被二值化；
- Mask 双线性缩放；
- Mask 宽高映射；
- 双区域参数独立修改；
- 参数钳制；
- 当前区域重置；
- 全部区域重置；
- 零参数恒等；
- 色温方向；
- Alpha 保持；
- Generation 旧帧丢弃；
- Work ID 与 Mask 目录一致；
- Mask 文件损坏；
- Mask version 校验。

---

# 34. Service 测试

为：

```text
SubjectSegmentationService
```

注入假的：

```typescript
SegmentationAdapter
```

覆盖：

```text
正常结果
Timeout 200
参数异常
SDK 运行异常
空主体
取消
重试
Mask 长度错误
无有效权重
非法 Bounding Box
release
```

确保 AI 生命周期正确释放。

---

# 35. 集成测试

验证：

```text
选图
↓
编辑控件锁定
↓
主体识别
↓
MaskProcessor
↓
解锁
```

以及：

```text
主体 / 背景切换
不得重新调用 AI
```

快速拖动：

```text
旧 Render 结果不得覆盖新结果
```

查看蒙版：

```text
必须与实际调色区域一致
```

正式保存：

```text
必须和最后一次有效预览参数一致
```

连续点击保存：

```text
只能执行一次
```

---

# 36. 真机测试集

必须覆盖：

```text
单人
多人
儿童
宠物
商品
鼠标
键盘
杯子
耳机
透明 / 半透明物品
头发
毛发
植物
逆光
低光
复杂背景
主体背景近似色
小主体
高分辨率照片
```

建议：

```text
不少于 100 张
```

照片。

同时保存：

```text
原图
RawMask
EditMask
最终 Overlay
```

供团队比较。

---

# 37. 性能目标

作为项目目标而非 SDK 保证：

```text
1080p 级 AI 工作图：
主体分割 P95 ≤ 3s
```

```text
滑块参数变化 → Preview：
P95 ≤ 100ms
```

```text
连续编辑：
无明显旧帧回跳
```

```text
编辑峰值内存：
目标 ≤ 200MB
```

如果 100ms 无法达到：

优先降低：

```text
Preview Render Resolution
```

而不是降低最终导出质量。

---

# 38. 验收红线

以下任何一项存在，都不能认为“主体识别功能已经完成”：

```text
直接使用 Bounding Box 调色

RawMask 无法可视化

不知道调色使用的是 RawMask 还是 Rectangle

Mask 宽高未经校验

缩放后 Mask 与图片错位

拖动滑块重新调用 AI

零参数仍改变原图

主体边缘被强制二值化成锯齿

AI 失败后仍允许区域调色
```

---

# 39. 推荐开发顺序

### Phase 1：AI 最小验证

完成：

```text
PhotoPicker
→
PixelMap
→
Core Vision
→
RawMask
```

加入 Debug 四视图。

此阶段不做正式调色 UI。

### Phase 2：MaskProcessor

完成：

```text
RawMask
→
EditMask
```

解决：

```text
尺寸
低置信污染
软边缘
缩放
```

### Phase 3：Renderer

实现：

```text
主体参数
背景参数
Mask Weighted Blend
```

验证：

```text
0 / 128 / 255
```

三个基础权重。

### Phase 4：Worker Preview

实现：

```text
缓存
代次
任务合并
快速滑块
```

### Phase 5：EditPage

接入：

```text
主体 / 背景 Tab
原图对比
Mask 查看
AI 状态
错误 UI
```

### Phase 6：保存

实现：

```text
Mask 文件
WorkSaveService
最终高质量区域渲染
相册写入
```

### Phase 7：真机验收

运行：

```text
100+ 图片测试集
性能测试
内存测试
ArkTS 编译
debug build
```

---

# 40. 最终架构

```text
                    ┌───────────────────────┐
                    │    PhotoViewPicker    │
                    └───────────┬───────────┘
                                ↓
                    ┌───────────────────────┐
                    │ Image Decode / Resize │
                    │      RGBA_8888        │
                    └───────────┬───────────┘
                                ↓
                    ┌───────────────────────┐
                    │ SubjectSegmentation   │
                    │       Service         │
                    └───────────┬───────────┘
                                ↓
                      Core Vision Kit AI
                                ↓
                    ┌───────────────────────┐
                    │       RawMask         │
                    │    mattingList        │
                    └───────────┬───────────┘
                                ↓
                    ┌───────────────────────┐
                    │     MaskProcessor     │
                    │ confidence / resize   │
                    └───────────┬───────────┘
                                ↓
                    ┌───────────────────────┐
                    │       EditMask        │
                    └───────────┬───────────┘
                                ↓
              ┌─────────────────┴─────────────────┐
              ↓                                   ↓
     Subject Adjustments                 Background Adjustments
              ↓                                   ↓
              └─────────────────┬─────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │   Region Renderer     │
                    │ Mask Weighted Blend   │
                    └───────────┬───────────┘
                                ↓
              ┌─────────────────┴─────────────────┐
              ↓                                   ↓
        Preview Worker                      WorkSaveService
              ↓                                   ↓
         PreviewArea                         Final Export
```

---

# 41. 最终技术判断

本版本不把：

```text
“Core Vision 成功返回结果”
```

等同于：

```text
“主体识别功能完成”
```

真正完成必须满足：

```text
AI 能正确输出 RawMask
+
RawMask 可以被验证
+
MaskProcessor 可以生成稳定 EditMask
+
Renderer 只根据 EditMask 调色
+
主体和背景边界实际符合视觉结果
```

`subjectRectangle` 只是 AI 输出的辅助几何信息。

真正决定哪个像素属于主体、主体占多少权重的唯一核心数据，应为：

```typescript
fullSubject.mattingList
```

整个 Vivid 主体 / 背景独立调色系统都应围绕：

```text
逐像素 Soft Mask
```

设计，而不是围绕矩形框设计。

---

# 42. 隐私与合规

Vivid 本身：

```text
不新增自己的图片上传接口
不向开发者服务器上传原图
不向开发者服务器上传 Mask
不向开发者服务器上传最终结果
```

接入 Core Vision Kit 前，在隐私政策中说明图片被用于主体识别。

根据华为 Core Vision Kit 当前个人数据处理说明，主体分割会处理开发者提供的图片，用于检测和分离区别于背景的前景物体或区域；相关图片标注为“不留存”，同时要求开发者向最终用户完成相应告知。

产品文案不要擅自扩展为未经确认的：

```text
100% 纯端侧 AI
图片绝不离开设备
```

应按照华为官方能力和隐私处理说明进行准确描述。

---

# 43. Definition of Done

本任务只有同时满足以下条件才算完成：

```text
Core Vision 真机调用成功

使用 mattingList 而不是 Rectangle 作为主体 Mask

RawMask Debug Viewer 可用

鼠标等物体不存在明显矩形调色区域

Mask 与图片没有位置漂移

低置信度背景污染已控制在可接受范围

主体软边缘得到保留

主体 / 背景参数真正独立

切换区域不会重复识别

快速拖动不会发生旧帧覆盖

最终保存与预览使用同一算法

资源能够正确释放

100+ 测试图片完成真机验收
```

如果 Core Vision 原始 RawMask 在部分场景仍存在明显高置信度误分割，应记录为模型能力边界，而不是继续用 Rectangle、强阈值或硬腐蚀掩盖问题。

此时下一阶段再评估：

```text
手动 Mask 修正
点击指定主体
多主体选择
更高精度分割模型
```

而不是污染当前 V1 主架构。