# ArkTS 语言语法速查

> ArkTS = TypeScript 的严格子集 + UI 声明扩展。入口 slug：`harmonyos-guides/introduction-to-arkts`

## 一、ArkTS 与 TypeScript 的关键差异

| 主题 | TypeScript | ArkTS |
|---|---|---|
| `any` 类型 | 允许 | **禁用**（所有变量/参数必须显式类型） |
| 函数返回类型 | 可推断 | **必须显式声明** |
| `Object` / `{}` 作任意类型 | 允许 | 不推荐，应用具体类型 |
| `struct` / `class` 装饰 | 仅 class | **`struct` 用于组件**，`@Component`/`@ComponentV2` 装饰 |
| `interface` 装饰器 | 无 | 有 `@Interface`（V2 用于抽象组件） |
| 动态属性访问 `obj[key]` | 允许 | 限制（需 `Record<K,V>` 显式声明） |
| `in` / `delete` 操作符 | 允许 | 禁用 |
| 装饰器参数 | 任意 | 部分装饰器参数需字面量 |
| `eval()` | 危险但可 | **禁用** |
| 函数 `arguments` 对象 | 可用 | 禁用（用 rest `...args`） |
| `with` 语句 | 禁用 | 禁用 |
| `Symbol` 任意使用 | 允许 | 限制（需显式 `unique symbol`） |

## 二、禁用语法清单

```typescript
// ❌ 禁用
let x: any = 1;                      // 禁用 any
let y = someObj as any;              // 禁用 as any
function f(a) { return a + 1; }      // 禁用隐式 any（参数必须 : type）
const o = { a: 1 }; o['b'] = 2;      // 禁用动态属性（用 Record）
const z = eval('1+1');               // 禁用 eval
function g() { console.log(arguments); }  // 禁用 arguments

// ✅ 正确
let x: number = 1;
let y: MyType = someObj as MyType;
function f(a: number): number { return a + 1; }
const o: Record<string, number> = { a: 1 }; o['b'] = 2;
function g(...args: number[]) { args.forEach(a => console.log(a)); }
```

## 三、常用模式

### 3.1 `StringEnum`（强类型枚举）

```typescript
// ArkTS 推荐用 enum 或 StringEnum 代替 TS 的字面量 union
enum Direction { Up = 'UP', Down = 'DOWN', Left = 'LEFT', Right = 'RIGHT' }
// 或：
type Status = 'idle' | 'loading' | 'done' | 'error';   // union 也可以
```

### 3.2 `struct` vs `class`

```typescript
// struct：用于组件，所有字段默认 public，不能继承
@Component
struct MyComp {
  @Local count: number = 0
  build() { Text(`${this.count}`) }
}

// class：用于数据模型 / 工具类，支持继承、private
@ObservedV2
class UserModel {
  @Trace name: string = ''
  @Trace age: number = 0
  getFullInfo(): string { return `${this.name}/${this.age}` }
}
```

### 3.3 `union` 类型

```typescript
type Result = Success | Failure;
type Success = { ok: true; data: string };
type Failure = { ok: false; error: string };

function handle(r: Result): void {
  if (r.ok) { /* r 自动收窄为 Success */ }
}
```

### 3.4 `Sendable`（跨线程安全类型）

```typescript
import { taskpool } from '@kit.ArkTs';

@Sendable
class TransferableModel {
  name: string = '';
  data: ArrayBuffer = new ArrayBuffer(0);
}

@Concurrent
function process(m: TransferableModel): void { /* ... */ }
```

`Sendable` 限制：
- 不能有普通闭包字段
- 属性必须是 `Sendable` 类型（基本类型 / `ArrayBuffer` / `Sendable class`）
- 不能有装饰器（`@State` 等）

### 3.5 `Record<K, V>`（替代索引签名）

```typescript
// TS：{ [key: string]: number }
// ArkTS：
const map: Record<string, number> = { a: 1, b: 2 };
map['c'] = 3;
```

### 3.6 可选链 + 空值合并

```typescript
const user: UserModel | undefined = getUser();
const name: string = user?.name ?? '匿名';
const age: number = user?.age ?? 0;
```

## 四、装饰器速查

| 装饰器 | 用途 | 必须搭配 |
|---|---|---|
| `@Entry` | 入口组件（对应一个页面） | `@Component` 或 `@ComponentV2` |
| `@Component` | V1 自定义组件 | 组件内用 V1 装饰器 |
| `@ComponentV2` | V2 自定义组件 | 组件内用 V2 装饰器 |
| `@Builder` | UI 片段封装 | 在组件内定义 |
| `@BuilderParam` | `@Builder` 作为参数传递 | 组件属性 |
| `@Extend` | 扩展系统组件属性 | 组件外 |
| `@Styles` | 封装一组样式 | 组件外 |
| `@ObservedV2` | 标记 class 可被观察 | 配合 `@Trace` |
| `@Trace` | 标记具体属性被观察 | `@ObservedV2` 的 class 内 |
| `@Local` | 组件内部状态 | `@ComponentV2` |
| `@Param` | 组件输入（父传子） | `@ComponentV2` |
| `@Once` | 只初始化一次的输入 | 配合 `@Param` |
| `@Event` | 组件输出（子调父） | `@ComponentV2` |
| `@Monitor` | 监听状态变化 | `@ObservedV2` 或 `@ComponentV2` |
| `@Provider` | 跨层级提供数据 | `@ComponentV2` |
| `@Consumer` | 跨层级消费数据 | `@ComponentV2` |
| `@Computed` | 计算属性（缓存） | `@ComponentV2` |
| `@Reusable` | 组件复用 | `@Component` |
| `@ReusableV2` | 组件复用（V2） | `@ComponentV2` |
| `@Watch` | 监听 V1 状态变量 | `@State`/`@Prop`/`@Link` 等 |
| `@State` | V1 组件内状态 | `@Component` |
| `@Prop` | V1 单向父→子 | `@Component` |
| `@Link` | V1 双向父子 | `@Component` |
| `@Provide`/`@Consume` | V1 跨层级 | `@Component` |
| `@Observed`/`@ObjectLink` | V1 深度观察 | `@Component` |
| `@StorageLink`/`@StorageProp` | V1 AppStorage 绑定 | `@Component` |
| `@LocalStorageLink`/`@LocalStorageProp` | V1 LocalStorage 绑定 | `@Component` |

## 五、事件回调必须用箭头函数

```typescript
// ❌ 错误：成员函数 + bind(this) 在 ArkTS 中不推荐
class Foo {
  onClick(): void { /* ... */ }
  build() {
    Button('Click').onClick(this.onClick.bind(this))  // 不推荐
  }
}

// ✅ 正确：成员箭头函数
class Foo {
  onClick = (): void => { /* ... */ }
  build() {
    Button('Click').onClick(this.onClick)
  }
}

// ✅ 正确：内联箭头函数
build() {
  Button('Click').onClick(() => { /* ... */ })
}
```

原因：匿名函数 `function() {}` 的 `this` 由调用方决定，易错；箭头函数 `() => {}` 的 `this` 词法绑定到外层。

## 六、资源引用 `$r` / `$r('app.media.xxx')`

```typescript
// ✅ 正确：用 $r 引用资源，支持多语言/多设备
Text($r('app.string.title'))
Image($r('app.media.app_icon'))
Color($r('app.color.primary'))

// ❌ 错误：硬编码字符串
Text('标题')             // 多语言失效
Image('/path/icon.png')  // 资源路径可能失效
```

**占位符**：
```json5
// resources/base/element/string.json
{ "string": [{ "name": "greet", "value": "你好，%s！" }] }
```
```typescript
Text($r('app.string.greet', '张三'))
```

## 七、相关 slug

- `harmonyos-guides/introduction-to-arkts` — ArkTS 介绍
- `harmonyos-guides/arkts-basic-syntax-overview` — 基本语法
- `harmonyos-guides/arkts-coding-style-guide` — 编程规范
- `harmonyos-guides/typescript-to-arkts-migration-guide` — TS → ArkTS 适配
- `harmonyos-guides/arkts-more-cases` — 适配案例
- `harmonyos-guides/arkts-high-performance-programming` — 高性能编程
- `harmonyos-guides/arkts-decorator-overview` — 装饰器总览
- `harmonyos-guides/sendable-across-threads` — Sendable
