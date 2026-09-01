# 系统能力（Kit）速查

> 按 Kit 分类列出 HarmonyOS NEXT 高频 API 入口模块 + 一句话说明 + 对应文档 slug。
> 完整 API 清单见 `catalog-references.md`。

## 一、应用框架 Ability Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@kit.AbilityKit` → `UIAbility` | 带 UI 的应用组件 | `js-apis-app-ability-uiability` |
| `Context` / `UIAbilityContext` | 上下文，访问资源/启动 Ability | `js-apis-inner-application-uiabilitycontext` |
| `Want` | 组件间传递的信息载体 | `js-apis-app-ability-want` |
| `AbilityConstant` | 启动模式/启动原因等常量 | `js-apis-app-ability-abilityconstant` |

**典型用法**：`import { UIAbility, Want } from '@kit.AbilityKit';`

## 二、ArkUI 框架

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.arkui.UIContext` | UI 上下文（router / promptAction / windowStage） | `arkts-apis-uicontext` |
| `@ohos.arkui.Router` | 页面路由（老项目） | `arkts-apis-uicontext-router` |
| `ts-component-general-attributes` | 所有组件共有属性（width/height/backgroundColor…） | `ts-component-general-attributes` |
| `ts-component-general-events` | 所有组件共有事件（onClick/onTouch…） | `ts-component-general-events` |

**组件命名约定**：组件首字母大写（`Text`、`Column`、`Button`）；属性方法小写驼峰（`.fontSize()`）；事件方法 `on` 前缀（`.onClick()`）。

## 三、多媒体 Media Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.multimedia.image` | ImageSource / PixelMap 图片解码 | `js-apis-image` |
| `@ohos.multimedia.media` | AVPlayer / AVRecorder 音视频播放录制 | `js-apis-media` |
| `@ohos.multimedia.imagePack` | 图片编码打包 | `js-apis-imagepack` |
| `@ohos.multimedia.photoAccessHelper` | 相册选图（替代旧 photoPicker） | `js-apis-photoaccesshelper` |
| `@ohos.multimedia.camera` | 相机能力 | `js-apis-camera` |
| `@ohos.multimedia.audio` | 音频播放/录制/管理 | `js-apis-audio` |

**典型用法**（选图）：
```typescript
import { photoAccessHelper } from '@kit.MediaKit';
const phHelper = photoAccessHelper.getPhotoAccessHelper(context);
const opts: photoAccessHelper.PhotoSelectOptions = {
  MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
  maxSelectNumber: 1,
};
const uris = await phHelper.select(opts);
```

## 四、文件管理 File Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.file.fs` | 文件读写（fd-based） | `js-apis-file-fs` |
| `@ohos.file.fileuri` | URI ↔ 路径转换 | `js-apis-file-fileuri` |
| `@ohos.file.picker` | 文件选择器（FilePicker） | `js-apis-file-picker` |
| `@ohos.file.preferences` | 轻量键值持久化（Preferences） | `js-apis-data-preferences` |
| `@ohos.file.relationalStore` | 关系型数据库（RDB，SQLite） | `js-apis-relationalstore` |
| `@ohos.file.kernel` | KV 存储（KVStore） | `js-apis-distributeddata-kv-store` |

**典型用法**（读文件）：
```typescript
import { fileIo as fs } from '@kit.CoreFileKit';
let file = fs.openSync('/data/storage/xxx.txt', fs.OpenMode.READ_ONLY);
let stat = fs.statSync(file.fd);
let buf = new ArrayBuffer(stat.size);
fs.readSync(file.fd, buf);
fs.closeSync(file);
```

## 五、网络通信 Network Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.net.http` | HTTP 请求 | `js-apis-http` |
| `@ohos.net.socket` | TCP/UDP/WebSocket | `js-apis-socket` |
| `@ohos.net.connection` | 网络状态监听 | `js-apis-connection` |
| `@ohos.net.wifi` | WiFi 信息 | `js-apis-wifi` |

**典型用法**（HTTP）：
```typescript
import { http } from '@kit.NetworkKit';
let req = http.createHttp();
let resp = await req.request('https://api.example.com/data', {
  method: http.RequestMethod.GET,
  header: { 'Content-Type': 'application/json' },
  connectTimeout: 60000,
  readTimeout: 60000,
});
// resp.result 是 string / ArrayBuffer / Object
req.destroy();
```

**权限**：`ohos.permission.INTERNET` 必须在 module.json5 声明。

## 六、通知 Notification Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.notificationManager` | 发布/取消通知 | `js-apis-notification` |
| `@ohos.notification` | 通知基础类型 | `js-apis-notification` |
| `@ohos.request` | 后台下载任务 | `js-apis-request` |

**典型用法**：
```typescript
import { notificationManager } from '@kit.NotificationKit';
let req: notificationManager.NotificationRequest = {
  id: 1,
  content: {
    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
    normal: { title: '标题', text: '正文', additionalText: '附加' },
  },
};
await notificationManager.publish(req);
```

**权限**：`ohos.permission.NOTIFICATION_CONTROLLER`（系统）或 `ohos.permission.PUBLISH_AGENT_REMINDER`（普通应用）。

## 七、安全与加密 Security Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.security.cryptoFramework` | 对称/非对称加解密、摘要、签名 | `js-apis-crypto` |
| `@ohos.security.certManager` | 证书管理（X.509） | `js-apis-cert-manager` |
| `@ohos.security.huks` | 密钥库（HUKS） | `js-apis-huks` |
| `@ohos.security.accessControl` | 权限运行时检查 | `js-apis-abilityaccessctrl` |

**权限运行时检查**：
```typescript
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
const atManager = abilityAccessCtrl.createAtManager();
const result = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, 'ohos.permission.INTERNET');
// result = 0 (授权) 或 -1 (拒绝)
```

## 八、位置服务 Location Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.geoLocationManager` | 获取位置 / 地理编码 | `js-apis-geoLocationManager` |
| `@ohos.geofencing` | 地理围栏 | `js-apis-geofencing` |

**权限**：`ohos.permission.APPROXIMATELY_LOCATION` + `ohos.permission.LOCATION`。

## 九、图形与渲染 Graphics Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.graphics.displaySync` | 帧率回调 | `js-apis-display-sync` |
| `@ohos.graphics.display` | 屏幕信息（亮度/分辨率） | `js-apis-display` |
| `@ohos.graphics.window` | 窗口管理 | `js-apis-window` |
| `@ohos.graphics` | 渲染（2D 绘制、Canvas） | `ts-canvas` |

## 十、性能分析 Kit

| 模块 | 说明 | slug |
|---|---|---|
| `@ohos.hilog` | 结构化日志 | `js-apis-hilog` |
| `@ohos.hiTraceMeter` | 性能打点 | `js-apis-hitracemeter` |
| `@ohos.hiAppEvent` | 应用事件上报 | `js-apis-hiappevent` |
| `@ohos.performance` | 性能统计 | `js-apis-performance` |

## 十一、其他高频 Kit

| Kit | 常用模块 | 入口 slug |
|---|---|---|
| BasicServicesKit | `BusinessError`、`DeviceType` | `js-apis-basicservices` |
| BundleManager | 应用信息查询 | `js-apis-bundle-manager` |
| ConnectivityKit | 蓝牙、NFC | `js-apis-bluetooth` |
| DeviceInfo | 设备信息（品牌/型号/API 版本） | `js-apis-deviceinfo` |
| Global | 多语言 / 区域 | `js-apis-global` |
| I18n | 国际化 | `js-apis-i18n` |
| Pasteboard | 剪贴板 | `js-apis-pasteboard` |
| Sensor | 传感器 | `js-apis-sensor` |
| Telephony | 电话/短信 | `js-apis-telephony` |
| Vibrator | 振动 | `js-apis-vibrator` |
| Wallpaper | 壁纸 | `js-apis-wallpaper` |

## 十二、Kit 命名 → import 模块 映射

HarmonyOS 的 Kit 名和 import 路径不总是一致。常用映射：

| Kit 名 | import 模块 |
|---|---|
| AbilityKit | `@kit.AbilityKit` |
| ArkUI | `@kit.ArkUI` |
| BasicServicesKit | `@kit.BasicServicesKit` |
| CoreFileKit | `@kit.CoreFileKit` |
| MediaKit | `@kit.MediaKit` |
| NetworkKit | `@kit.NetworkKit` |
| NotificationKit | `@kit.NotificationKit` |
| SecurityKit | `@kit.SecurityKit` |
| LocationKit | `@kit.LocationKit` |
| GraphicsKit | `@kit.GraphicsKit` |
| PerformanceAnalysisKit | `@kit.PerformanceAnalysisKit` |
| TelephonyKit | `@kit.TelephonyKit` |

**优先使用 Kit 级别 import**（`@kit.Xxx`），避免老的 `@ohos.xxx` 路径（已逐步废弃）。

## 十三、权限声明

所有涉及系统能力的权限必须在 `module.json5` 的 `requestPermissions` 声明：

```json5
// entry/src/main/module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:net_reason",
        "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
      }
    ]
  }
}
```

权限分三级：
- **normal**：安装时自动授权（如 INTERNET）
- **user_grant**：需运行时弹窗（如 LOCATION、CAMERA、MICROPHONE）
- **system**：仅系统应用（普通应用无法申请）
