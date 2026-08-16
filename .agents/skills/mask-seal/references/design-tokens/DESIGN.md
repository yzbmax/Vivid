---
name: Mask & Seal
colors:
  surface: '#fff8f7'
  surface-dim: '#ebd5d3'
  surface-bright: '#fff8f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff0ef'
  surface-container: '#ffe9e7'
  surface-container-high: '#f9e3e1'
  surface-container-highest: '#f3dedc'
  on-surface: '#241918'
  on-surface-variant: '#574140'
  inverse-surface: '#3a2d2c'
  inverse-on-surface: '#ffedeb'
  outline: '#8b716f'
  outline-variant: '#debfbd'
  surface-tint: '#a73837'
  primary: '#7b171b'
  on-primary: '#ffffff'
  primary-container: '#9b2f2f'
  on-primary-container: '#ffbab5'
  inverse-primary: '#ffb3ae'
  secondary: '#5c5f5e'
  on-secondary: '#ffffff'
  secondary-container: '#e1e3e1'
  on-secondary-container: '#626564'
  tertiary: '#004645'
  on-tertiary: '#ffffff'
  tertiary-container: '#00605e'
  on-tertiary-container: '#8ed8d5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad7'
  primary-fixed-dim: '#ffb3ae'
  on-primary-fixed: '#410005'
  on-primary-fixed-variant: '#862022'
  secondary-fixed: '#e1e3e1'
  secondary-fixed-dim: '#c5c7c5'
  on-secondary-fixed: '#191c1b'
  on-secondary-fixed-variant: '#444746'
  tertiary-fixed: '#a5f0ec'
  tertiary-fixed-dim: '#8ad3d0'
  on-tertiary-fixed: '#00201f'
  on-tertiary-fixed-variant: '#00504e'
  background: '#fff8f7'
  on-background: '#241918'
  surface-variant: '#f3dedc'
  paper-base: '#deddd7'
  paper-surface: '#f2f1ed'
  seal-red: '#b23b2f'
typography:
  headline-lg:
    fontFamily: notoSerif
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: notoSerif
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-md:
    fontFamily: notoSans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-mono:
    fontFamily: geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: notoSerif
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
spacing:
  grid-unit: 5.4rem
  annotation-margin: 4rem
  gutter: 1rem
  margin-mobile: 1.25rem
  lab-arrive-x: 0.85rem
---

# 蒙版调色 —— 炎国卷轴风格设计系统

## 一、视觉基调
- **核心理念**：文书钤印、长卷批注。将图片编辑过程比作古籍呈报与审批。
- **色彩令牌**：
  - `background`: #deddd7 (宣纸灰)
  - `surface`: #f2f1ed (浅纸白)
  - `ink`: #252827 (墨黑)
  - `focus`: #9b2f2f (朱砂红)
  - `signal`: #b23b2f (钤印红)
- **字体**：
  - 中文：系统无衬线 (HarmonyOS Sans SC)
  - 数字/数据：Geist Mono (等宽仪表感)

## 二、布局范式
- **scroll-annotation-margin**：模拟长卷轴，主内容区居中，侧边留出批注空间（放置调色参数）。
- **背景装饰**：纵向 5.4rem 细线网格 + 顶部 18% 处的径向柔光。

## 三、控件语言 (Seal Press)
- **按钮**：模拟案牍钤印。
- **滑块**：红色细线轨道，滑块为微型方印章形状。
- **Tab 切换**：折页效果，类似呈文折。

## 四、实验台 (Control Lab)
- **入场动画**：自左向右横移入场 (`--lab-arrive-x: .85rem`)。
- **圆角**：直角 (`--lab-corner: 0`)。