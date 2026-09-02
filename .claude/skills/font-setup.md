---
name: font-setup
description: Vivid 项目的自定义字体配置规范。当需要添加、修改、引用字体，或排查字体显示问题时使用。包含字体文件位置、注册方式、Theme 令牌用法和中英文 fallback 原理。
---

# Vivid 字体配置规范

## 一、字体方案

| 用途 | 字体名 | 文件 | 说明 |
|---|---|---|---|
| 中文标题/正文 | `NotoSerifSC` | `rawfile/font/NotoSerifSC-VariableFont_wght.ttf` | Noto Serif 简体中文版，可变字重 |
| 英文/数字 | `NotoSerif` | `rawfile/font/NotoSerif-VariableFont_wdth,wght.ttf` | Noto Serif 拉丁版，可变字宽+字重 |
| 等宽数据 | `monospace` | 系统内置 | 用于数据标签、日期、状态码 |

### 中英文 Fallback 机制

Theme.ets 中 `FONT_SERIF` 使用逗号分隔的字体列表：

```typescript
static readonly FONT_SERIF: string = 'NotoSerifSC, NotoSerif';
```

HarmonyOS 的 `.fontFamily()` 支持逗号分隔字体列表，系统对每个字符依次匹配：
- **中文字符** → 命中 `NotoSerifSC`
- **英文/数字** → `NotoSerifSC` 无此字符 → 自动 fallback 到 `NotoSerif`

## 二、注册方式

字体在启动页 `Index.ets` 的 `aboutToAppear` 中全局注册（一次注册，全 App 可用）：

```typescript
aboutToAppear(): void {
  const fontApi = this.getUIContext().getFont();
  fontApi.registerFont({
    familyName: 'NotoSerifSC',
    familySrc: $rawfile('font/NotoSerifSC-VariableFont_wght.ttf')
  });
  fontApi.registerFont({
    familyName: 'NotoSerif',
    familySrc: $rawfile('font/NotoSerif-VariableFont_wdth,wght.ttf')
  });
}
```

### API 说明

- `this.getUIContext().getFont().registerFont()` — HarmonyOS 字体注册接口
- `familyName` — 注册的字体名，在 `.fontFamily()` 中引用
- `familySrc` — 字体文件路径，使用 `$rawfile()` 引用 `resources/rawfile/` 下的文件

## 三、Theme 令牌

所有字体引用应通过 `Theme.ets` 令牌，不硬编码字体名：

```typescript
// 衬线（标题、品牌名、印章）—— 中英文混合
.fontFamily(Theme.FONT_SERIF)    // → 'NotoSerifSC, NotoSerif'

// 无衬线（正文、描述、按钮）—— 系统 HarmonyOS Sans
.fontFamily(Theme.FONT_SANS)     // → 'HarmonyOS Sans SC'

// 等宽（数据标签、日期、状态码）
.fontFamily(Theme.FONT_MONO)     // → 'monospace'
```

## 四、文件位置

```
entry/src/main/resources/rawfile/font/
├── NotoSerifSC-VariableFont_wght.ttf      # 中文衬线
└── NotoSerif-VariableFont_wdth,wght.ttf   # 英文衬线
```

## 五、添加新字体步骤

1. 将 `.ttf` / `.otf` 文件放入 `entry/src/main/resources/rawfile/font/`
2. 在 `Index.ets` 的 `aboutToAppear` 中调用 `registerFont`
3. 如需全局替换，更新 `Theme.ets` 对应令牌
4. 如仅局部使用，直接在组件中 `.fontFamily('新字体名')` 引用

## 六、注意事项

- 字体文件**必须**放在 `rawfile/` 目录下，`$r('app.media.xxx')` 方式不适用于字体
- `registerFont` 是**异步**的，首次渲染可能短暂使用回退字体（通常不可察觉）
- `EditPage` 等独立路由页（非 Index Tab 子页）同样受益于全局注册，无需重复注册
- 如果文件名含特殊字符（如逗号），`$rawfile()` 可以正常解析
