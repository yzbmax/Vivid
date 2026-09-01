# DevEco Studio 工具链速查

> 官方入口：`harmonyos-guides/application-dev-guide`、`harmonyos-guides/start-overview`

## 一、工程结构

```
MyApplication/
├── AppScope/                     # 应用级配置（全局唯一）
│   ├── app.json5                 # bundleName, vendor, versionCode, versionName, icon
│   └── resources/                # 全局资源（app.media.app_icon 等）
├── entry/                        # HAP 模块（默认入口）
│   ├── src/main/
│   │   ├── ets/entryability/EntryAbility.ets
│   │   ├── ets/pages/Index.ets
│   │   ├── resources/base/element/string.json
│   │   ├── resources/base/media/
│   │   ├── resources/base/profile/main_pages.json
│   │   └── module.json5          # 模块配置（abilities, requestPermissions, routerMap…）
│   ├── src/ohosTest/             # 模块级 instrumented 测试
│   ├── hvigorfile.ts
│   ├── build-profile.json5       # 模块构建配置
│   └── oh-package.json5          # 模块依赖
├── products/                     # 可选：多产品 HAP
├── library/                      # 可选：HAR / HSP 共享模块
├── build-profile.json5           # 工程级构建配置（signingConfigs, products, modules）
├── hvigorfile.ts
├── hvigorw / hvigorw.bat         # hvigor wrapper（类似 gradlew）
├── oh-package.json5              # 工程级依赖
└── oh-package-lock.json5
```

**关键配置文件**：
| 文件 | 作用 |
|---|---|
| `app.json5` | bundleName（全局唯一）、版本号、vendor、minAPIVersion |
| `module.json5` | 模块类型（entry/feature/har/hsp）、abilities、permissions、routerMap、pages |
| `build-profile.json5` | 签名配置、产品配置、构建选项、compatibleSdkVersion |
| `oh-package.json5` | 依赖（支持 file: 指向本地 HAR/HSP） |
| `main_pages.json` | 注册 `@Entry` 页面的 routerMap（Router 模式） |

## 二、hvigor 构建

hvigor 是 HarmonyOS 的 Gradle 等价物，基于 TypeScript 配置。

```bash
# Windows
hvigorw.bat assembleHap          # 构建单个 HAP
hvigorw.bat assembleApp          # 构建完整应用（含所有模块）
hvigorw.bat clean                # 清理

# macOS/Linux
./hvigorw assembleHap
./hvigorw assembleApp

# 指定 product / module
hvigorw.bat assembleHap --mode module -p module=entry@default -p product=default
```

**hvigorfile.ts** 是构建脚本（每个模块一份），常用 plugin：
- `appTasks.append()` — HAP 应用插件
- `harTasks.append()` — HAR 库插件
- `hspTasks.append()` — HSP 动态库插件

## 三、签名

### 3.1 调试签名（.p7b + .p12）

DevEco 自动为 debug 构建生成签名，配置在 `build-profile.json5` 的 `signingConfigs`。手动：

```json5
// build-profile.json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "/path/to/harmonyos_debug.cer",
          "storePassword": "***",
          "keyAlias": "harmonyos_debug",
          "keyPassword": "***",
          "profile": "/path/to/harmonyos_debug.p7b",
          "storeFile": "/path/to/harmonyos_debug.p12"
        }
      }
    ]
  }
}
```

**申请调试证书**：DevEco → Tools → HarmonyOS Debug Certificate（需华为开发者账号 + 设备 UDID）。

### 3.2 发布签名

发布到 AppGallery Connect 必须用发布证书：
1. AppGallery Connect → User and Access → HarmonyOS API → Certificate Management
2. 申请发布证书（.cer）+ Profile（.p7b）
3. 转为 .p12 后填入 `signingConfigs` 的 release 配置

## 四、调试

| 工具 | 用途 | 启动 |
|---|---|---|
| **Log / HiLog** | 运行日志 | `hilog.info(0x0000, 'tag', 'msg %{public}s', var)` |
| **Debugger** | 断点调试 | DevEco Debug 面板 |
| **Profiler** | 性能分析（帧率/CPU/内存） | Tools → Profiler |
| **Device File Browser** | 查看设备/模拟器沙箱文件 | Tools → Device File Browser |
| **Inspector** | UI 层级检查 | 右键组件 → Inspect |
| **Emulator** | 本地 HarmonyOS 模拟器 | Tools → Device Manager |

**HiLog 等级**：`DEBUG < INFO < WARN < ERROR < FATAL`。发布构建默认过滤 DEBUG/INFO。

**真机调试**：设备开启"开发者模式" + "USB 调试"，DevEco Device Manager 识别后可直接 Run。

## 五、发布

1. **生成 .app 包**：`hvigorw assembleApp --no-daemon`
2. **上传 AppGallery Connect**：
   - AppGallery Connect → My Projects → 选应用 → AppGallery Connect
   - Distribution → Version Distribution → Create a version
   - 上传 `.app` 文件（含所有 HAP）
3. **审核**：提交后进入华为审核（通常 1-3 工作日）
4. **灰度 / 全量**：审核通过后分阶段发布

## 六、模拟器与真机部署

- **模拟器**：Device Manager → Local → 选系统镜像（如 Phone API 12）→ Create → Run
- **真机**：USB 连接 → Device Manager 识别 → 右键 Run 'entry'
- **远程设备**：Remote 选项需登录华为账号 + 云端设备预约

## 七、常用 ohpm 命令

```bash
ohpm install @ohos/axios                 # 安装依赖
ohpm install -D @ohos/hypium             # 安装到 devDependencies
ohpm uninstall @ohos/axios
ohpm list                                # 列出依赖
ohpm view @ohos/axios                    # 查看包信息
```

`oh-package.json5` 依赖格式：
```json5
{
  "dependencies": {
    "@ohos/axios": "^2.0.0",
    "mylocalhar": "file:../library/mylocalhar"
  }
}
```

## 八、常见构建错误

| 错误 | 原因 | 修复 |
|---|---|---|
| `Module not found: @ohos/xxx` | 未安装 | `ohpm install @ohos/xxx` |
| `ArkTSError: Cannot find name` | TS 类型缺失 / 装饰器用错 | 检查 import + 装饰器版本 |
| `Build failed: signingConfigs is empty` | 缺签名 | DevEco → File → Project Structure → Signing Configs |
| `compatibleSdkVersion must ≤ compileSdkVersion` | SDK 版本不匹配 | build-profile.json5 调整 |
| `ohpm install` 卡住 | 网络/镜像 | 配置 `ohpm config set registry https://repo.harmonyos.com/ohpm/` |

## 九、相关 slug

- `harmonyos-guides/start-overview` — 开发准备
- `harmonyos-guides/start-with-ets-stage` — 第一个应用
- `harmonyos-guides/application-configuration-file-overview-stage` — 配置概览
- `harmonyos-guides/app-configuration-file` — app.json5
- `harmonyos-guides/module-configuration-file` — module.json5
- `harmonyos-guides/ide-debug-overview` — 调试总览
- `harmonyos-guides/ide-profiler-overview` — Profiler
- `harmonyos-guides/publish-overview` — 发布总览
