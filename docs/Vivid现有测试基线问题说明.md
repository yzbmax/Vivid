# Vivid 现有测试基线问题说明

> 记录日期：2026-08-21
>
> 影响范围：项目级 Hvigor 单元测试
> 当前责任边界：`EditModels.test.ets` 由开发者 C 维护

## 一、问题现象

执行以下项目单元测试命令：

```powershell
hvigorw.bat --mode module -p product=default -p module=entry@default -p buildMode=debug test --no-daemon --no-incremental
```

测试在执行测试用例前，于 `:entry:default@UnitTestArkTS` 阶段失败。

编译器错误为：

```text
10605038 ArkTS Compiler Error
Object literal must correspond to some explicitly declared class or interface
(arkts-no-untyped-obj-literals)
```

## 二、错误位置

文件：`entry/src/test/EditModels.test.ets`

当前报告的错误行：

- 第 27 行
- 第 34 行
- 第 42 行
- 第 50 行
- 第 54 行
- 第 58 行
- 第 301 行
- 第 311 行
- 第 321 行
- 第 330 行
- 第 342 行

这些位置直接把对象字面量传给 `parseEditRouteParams()`。当前 ArkTS 编译规则要求对象字面量对应显式声明的类或接口，不能按普通 TypeScript 的无类型对象字面量处理。

## 三、影响

- 项目单元测试无法进入实际测试执行阶段。
- `AppSettingsStore.test.ets` 等已经注册的测试无法获得完整执行结果。
- `PendingEditIntentStore.test.ets` 即使注册，也会先被该编译错误阻断。
- 当前不能声明项目级单元测试通过。
- 该问题不等同于开发者 A 的首页门禁、登录恢复或导出设置功能运行失败；相关功能已由测试人员进行手工验证，但自动化回归证据仍不完整。

## 四、建议修复方式

由开发者 C 在 `EditModels.test.ets` 中为路由原始参数声明显式类型，例如统一使用：

```typescript
const raw: Record<string, string> = {
  source: 'picker',
  imageUri: 'file:///tmp/a.jpg'
};
const route = parseEditRouteParams(raw);
```

所有报错位置应采用同类修复，不应删除、跳过或弱化现有断言。

修复后需要重新执行完整 Hvigor 单元测试，并确认：

1. `UnitTestArkTS` 编译通过；
2. 所有已注册测试实际执行；
3. 测试结果为零失败；
4. 再注册并执行 `PendingEditIntentStore.test.ets`。

## 五、本次推送说明

本问题在开发者 A 改动前已经存在，且对应测试文件属于 C 的独占修改范围，因此 A 未修改 `EditModels.test.ets`。

经项目负责人明确授权，本次开发者 A 功能仍提交并推送到 `origin/merge/all-three`；该授权仅允许带已知基线问题推送，不表示单元测试已经通过，也不解除后续修复和重跑测试的要求。
