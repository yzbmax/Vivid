/**
 * 设计令牌 —— 全局唯一来源
 *
 * 依据：
 *  - docs/stitch_/stitch_/mask_seal/DESIGN.md（Mask & Seal 炎国卷轴风格）
 *  - docs/公共组件预留文档.md §三（颜色/字体/间距/动效令牌）
 *
 * 约束：组件内禁止硬编码令牌之外的色值/字号；确需微调间距，取本类常量的倍数。
 * 颜色令牌与 resources/base/element/color.json 及 dark 保持一致。
 */
export class Theme {
  // ───────────────────────── 颜色令牌（与 color.json 一一对应）─────────────────────────
  static readonly PAPER_BASE: string = '#DEDDD7';            // 宣纸灰：全局背景
  static readonly PAPER_SURFACE: string = '#F2F1ED';         // 浅纸白：顶栏/浮层表面
  static readonly SURFACE: string = '#FFF8F7';               // M3 主 surface
  static readonly SURFACE_CONTAINER_LOWEST: string = '#FFFFFF';
  static readonly SURFACE_CONTAINER_LOW: string = '#FFF0EF';
  static readonly SURFACE_CONTAINER: string = '#FFE9E7';     // 常规卡片（作品卡）
  static readonly SURFACE_CONTAINER_HIGH: string = '#F9E3E1';
  static readonly SURFACE_CONTAINER_HIGHEST: string = '#F3DEDC'; // 未激活筛选 chip 底
  static readonly ON_SURFACE: string = '#241918';            // 正文墨色
  static readonly ON_SURFACE_VARIANT: string = '#574140';    // 次级文字
  static readonly INVERSE_SURFACE: string = '#3A2D2C';       // 反色面
  static readonly INVERSE_ON_SURFACE: string = '#FFEDEB';
  static readonly OUTLINE: string = '#8B716F';               // 描边/结束装饰线
  static readonly OUTLINE_VARIANT: string = '#DEBFBD';
  static readonly SURFACE_TINT: string = '#A73837';
  static readonly PRIMARY: string = '#7B171B';               // 深朱砂主色
  static readonly ON_PRIMARY: string = '#FFFFFF';
  static readonly PRIMARY_CONTAINER: string = '#9B2F2F';
  static readonly SEAL_RED: string = '#B23B2F';              // 钤印红
  static readonly ON_PRIMARY_FIXED_VARIANT: string = '#862022'; // 激活 chip 角标
  static readonly TERTIARY: string = '#004645';
  static readonly ERROR: string = '#BA1A1A';
  static readonly ERROR_CONTAINER: string = '#FFDAD6';
  static readonly ON_ERROR_CONTAINER: string = '#93000A';

  // ─────────────── 派生（带 alpha 的合成色，用途见命名）───────────────
  static readonly PAPER_SURFACE_80: string = '#CCF2F1ED';    // 顶栏 paper-surface/80
  static readonly PAPER_BASE_90: string = '#E6DEDDD7';       // 底部落款条 paper-base/90
  static readonly PRIMARY_60: string = '#996B171B';          // primary/60
  static readonly PRIMARY_20: string = '#337B171B';          // primary/20（落款边框）
  static readonly PRIMARY_05: string = '#0D7B171B';          // primary/5（落款底）
  static readonly ON_SURFACE_VARIANT_70: string = '#B2574140'; // on-surface-variant/70（未激活 chip 文字）
  static readonly INVERSE_SURFACE_40: string = '#663A2D2C';  // inverse-surface/40（草稿遮罩）
  static readonly SHADOW_SM: string = '#0D000000';           // shadow-sm ≈ 0 1px 2px rgba(0,0,0,0.05)
  static readonly SHADOW_HEADER: string = '#0A000000';       // 顶栏 0 1px 8px rgba(0,0,0,0.04)
  static readonly GRID_LINE: string = 'rgba(209, 191, 187, 0.34)'; // 宣纸网格线（PaperBackground Canvas 绘制）

  // ───────────────────────── 字体 ─────────────────────────
  // 中文 → NotoSerifSC，英文/数字 → NotoSerif（系统按字符自动 fallback）
  static readonly FONT_SERIF: string = 'Noto Serif SC, Noto Serif';
  static readonly FONT_SANS: string = 'HarmonyOS Sans SC';    // 正文无衬线
  static readonly FONT_MONO: string = 'monospace';            // 数据/标签等宽

  // ───────────────────────── 字号（vp）─────────────────────────
  static readonly FONT_SIZE_HEADLINE_LG: number = 32;         // headline-lg
  static readonly FONT_SIZE_HEADLINE_LG_MOBILE: number = 28;  // headline-lg-mobile（指标大数字）
  static readonly FONT_SIZE_HEADLINE_MD: number = 24;         // headline-md（顶栏标题）
  static readonly FONT_SIZE_BODY_MD: number = 16;             // body-md
  static readonly FONT_SIZE_LABEL_MONO: number = 13;          // label-mono
  static readonly FONT_SIZE_LABEL_MONO_SM: number = 10;       // label-mono 小号（卡片日期/状态）

  // ───────────────────────── 间距 / 尺寸（vp）─────────────────────────
  static readonly SPACE_SM: number = 4;                       // 0.25rem 小间距
  static readonly SPACE_MD: number = 8;                       // 0.5rem 中间距
  static readonly SPACE_LG: number = 12;                      // 0.75rem 大间距
  static readonly SPACE_XL: number = 16;                      // 1rem 特大间距
  static readonly GRID_UNIT: number = 86;                     // 5.4rem ≈ 86.4vp 背景竖线网格间距
  static readonly MARGIN_MOBILE: number = 20;                 // 1.25rem 移动端页边距
  static readonly GUTTER: number = 16;                        // 1rem 卡片间距
  static readonly HEADER_HEIGHT: number = 46;                 // 顶栏 h-14
  static readonly NAV_BAR_HEIGHT: number = 64;                // 底部导航预留 h-16
  static readonly CARD_IMAGE_HEIGHT: number = 160;            // 作品卡缩略图 h-40
  static readonly CHIP_PADDING_X: number = 16;                // 筛选 chip 横向内边距 px-4
  static readonly CHIP_PADDING_Y: number = 8;                 // 筛选 chip 纵向内边距 py-2

  // ───────────────────────── 圆角（vp，直角偏方）─────────────────────────
  static readonly RADIUS_DEFAULT: number = 4;                 // 0.25rem
  static readonly RADIUS_LG: number = 8;                      // 0.5rem
  static readonly RADIUS_XL: number = 12;                     // 0.75rem
  static readonly RADIUS_FULL: number = 1000;                 // 全圆
}
