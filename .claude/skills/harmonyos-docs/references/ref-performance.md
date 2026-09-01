# ArkTS 高性能编程 & 卡顿优化

> 主入口 slug：`harmonyos-guides/arkts-high-performance-programming`

## 一、核心原则

1. **主线程只做 UI**：所有耗时操作（IO/计算/网络/解码）必须走子线程。
2. **精准刷新**：让 ArkUI 只重建真正变化的组件，避免整树 diff。
3. **减少对象创建**：循环/滚动中避免 new 闭包、避免临时数组。
4. **懒加载**：列表、图片、模块全部按需加载。

## 二、状态管理优化

### 2.1 V2 优先（精准更新）

V1 `@State` 触发整个组件 `build()` 重跑；V2 `@Local` 只更新引用该变量的节点。

```typescript
// 差：V1 整组件重建
@Component
struct Bad {
  @State count: number = 0
  build() { Column() { Text(`${this.count}`); /* ...其他 20 个组件 */ } }
}

// 好：V2 精准更新
@ComponentV2
struct Good {
  @Local count: number = 0
  build() { Column() { Text(`${this.count}`); /* ...其他 20 个组件 */ } }
}
```

### 2.2 `@Trace` 控制观察粒度

只标需要观察的属性，避免深度扫描：

```typescript
@ObservedV2
class Model {
  @Trace name: string = ''           // 观察
  cache: ArrayBuffer                 // 不观察（大对象）
}
```

### 2.3 避免 `@Monitor` 滥用

`@Monitor` 是 V2 版的 `@Watch`，每次变化都会触发回调。高频变化（动画、滚动位置）不要 `@Monitor`，改用 `displaySync` 帧回调。

## 三、列表性能（长列表）

### 3.1 必须用 `LazyForEach` + `IDataSource`

```typescript
class MyDataSource implements IDataSource {
  private data: Item[] = []
  private listeners: DataChangeListener[] = []
  totalCount(): number { return this.data.length }
  getData(index: number): Item { return this.data[index] }
  registerDataChangeListener(l: DataChangeListener) { this.listeners.push(l) }
  unregisterDataChangeListener(l: DataChangeListener) { /* remove */ }
  // ...reloadData / notifyDataAdd / notifyDataChange 等
}

@Component
struct LongList {
  @State ds = new MyDataSource()
  build() {
    List() {
      LazyForEach(this.ds, (item: Item) => {
        ListItem() { ItemView({ item }) }
      }, (item: Item) => item.id.toString())  // 必须 keyGenerator
    }
  }
}
```

### 3.2 `ListItemGroup` + 缓存控制

```typescript
List() {
  LazyForEach(this.ds, (item: Item) => {
    ListItem() { ItemView({ item }) }
  }, (item: Item) => item.id.toString())
}
.cachedCount(50)   // 屏外缓存数（默认 1，长列表建议 50-200）
```

### 3.3 `@Reusable` 组件复用

避免反复创建/销毁复杂 item：

```typescript
@Reusable
struct ItemView {
  @Param item: Item
  aboutToReuse(params: Record<string, Object>) {
    this.item = params.item as Item
  }
  build() { /* ... */ }
}
```

## 四、图片性能

1. **Web 图用 `Image` 自带解码缓存**：设置 `.objectFit(ImageFit.Cover)` + 明确宽高，避免反复 decode。
2. **本地图走 `PixelMap`**：用 `image.createImageSource(file).createPixelMap({ desiredSize: { width, height } })` 指定解码尺寸，**不要全尺寸解码再缩**。
3. **`Interpolation`**：缩略图用 `.interpolation(ImageInterpolation.None)`（默认），大图放大用 `.Low`。
4. **动画帧**：GIF / 动图用 `AnimatedImage`，避免逐帧手动 decode。

## 五、线程模型

### 5.1 TaskPool（推荐，自动调度）

```typescript
import { taskpool } from '@kit.ArkTs';

@Concurrent
function heavyCompute(data: Uint8Array): Uint8Array {
  // 不能在 @Concurrent 中访问外部闭包
  return data.map(v => v * 2);
}

// UI 线程调用
const task = new taskpool.Task(heavyCompute, data);
taskpool.execute(task).then(result => { /* 更新 UI */ });
```

**`@Concurrent` 限制**：
- 不能访问外部闭包变量
- 参数必须是 `Sendable`（基础类型 / `Sendable` class）
- 不能调用非 Sendable 的 API

### 5.2 Worker（长生命周期，独立线程）

适用：持续运行的解码器 / 物理引擎 / 音频处理。

```typescript
// UI 线程
const worker = new worker.ThreadWorker('entry/ets/workers/MyWorker.ets');
worker.postMessage({ cmd: 'decode', data });
worker.onmessage = (e) => { /* 处理结果 */ };
```

### 5.3 选择规则

| 场景 | 选择 |
|---|---|
| 单次耗时任务（几秒内） | TaskPool |
| 持续运行（解码循环） | Worker |
| 需要操作 UI 上下文 | 都不能，必须回到主线程 |
| 多个同类任务并行 | TaskPool（自动负载均衡） |

## 六、启动性能

1. **AppStartup**：把初始化任务注册为 `StartupTask`，框架按依赖顺序并行执行。
   - slug: `harmonyos-guides/app-startup`
2. **应用预加载**：系统会在 Launcher 点击图标时提前加载进程。
   - slug: `harmonyos-guides/preload-application`
3. **首屏懒加载**：`onWindowStageCreate` 只 `loadContent` 首页，数据异步加载。
4. **HSP 动态加载**：非首屏模块做成 HSP，按需加载减少首帧时间。

## 七、渲染性能

1. **避免深层嵌套**：`Column > Row > Stack > Column > ...` 超过 5 层考虑拆组件。
2. **`renderGroup()`**：静态复合节点用 `renderGroup()` 合并为一个渲染节点。
3. **避免 `if/else` 频繁切换**：用 `visibility` 控制显隐比销毁/重建快。
4. **`geometryTransition`**：页面转场用共享元素比整屏动画便宜。
5. **`drawing` 高级 API**：需要 2D 自绘时用 `@ohos.graphics.drawing`，避免频繁 `Canvas`。

## 八、反模式清单

| ❌ 反模式 | ✅ 改进 |
|---|---|
| 在 `build()` 里做计算 / 调 API | 移到 `aboutToAppear` 或 `@Computed` |
| `@State` 存整棵大对象 | 拆成多个 `@Local` / `@Trace` |
| `ForEach` 渲染 1000+ 项 | 换 `LazyForEach` |
| 每次 `onClick` 都 `new` 闭包 | 提升为成员箭头函数 |
| 主线程读文件/解图 | `taskpool.execute` |
| 整图直接 decode 到 `PixelMap` | 指定 `desiredSize` 缩解码 |
| `setTimeout` 做动画 | `animateTo` / `displaySync` 帧回调 |
| `onPageShow` 里重新请求全部数据 | 用 `@Monitor` 监听变化 + 增量更新 |
| 深层 `@Provide`/`@Consume` 跨 10 层 | 改 `LocalStorage` 单例或 `AppStorage` |
| `@ObservedV2` 不配 `@Trace` | 属性必须标 `@Trace` 才会被观察 |

## 九、诊断工具

| 工具 | 用途 |
|---|---|
| DevEco Profiler → Frame | 帧率 / 掉帧分析 |
| DevEco Profiler → Time | 方法耗时、调用链 |
| DevEco Profiler → ArkWeb | ArkUI 组件树重建次数 |
| HiTraceMeter | 代码打点，与 Profiler 联动 |
| `displaySync.register` | 运行时帧回调用于自检 |

## 十、相关 slug

- `harmonyos-guides/arkts-high-performance-programming` — 主文档
- `harmonyos-guides/arkts-new-observedv2-and-trace` — V2 精准观察
- `harmonyos-guides/arkts-new-local` — @Local
- `harmonyos-guides/lazy-foreach-introduction` — LazyForEach
- `harmonyos-guides/component-reuse` — @Reusable
- `harmonyos-guides/taskpool-introduction` — TaskPool
- `harmonyos-guides/worker-introduction` — Worker
- `harmonyos-guides/app-startup` — AppStartup
- `harmonyos-guides/sendable-across-threads` — Sendable 多线程安全
- `harmonyos-guides/image-loading` — 图片加载优化
