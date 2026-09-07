/**
 * 自动化色彩无障碍对比度合规测试
 * 
 * 校验标准：
 * - 图标或标题文字与背景对比度 >= 3.0:1
 * - 正文文字与背景对比度 >= 4.5:1
 */
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');

function hexToRgb(hex) {
  hex = hex.replace(/^#/, '').trim();
  if (hex.length === 8) {
    const a = parseInt(hex.substring(0, 2), 16) / 255;
    const r = parseInt(hex.substring(2, 4), 16);
    const g = parseInt(hex.substring(4, 6), 16);
    const b = parseInt(hex.substring(6, 8), 16);
    return { r, g, b, a };
  } else if (hex.length === 6) {
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return { r, g, b, a: 1 };
  } else if (hex.length === 3) {
    const r = parseInt(hex[0] + hex[0], 16);
    const g = parseInt(hex[1] + hex[1], 16);
    const b = parseInt(hex[2] + hex[2], 16);
    return { r, g, b, a: 1 };
  }
  throw new Error('Invalid hex color: ' + hex);
}

function blend(fg, bg) {
  if (fg.a === 1) return fg;
  return {
    r: Math.round(fg.r * fg.a + bg.r * (1 - fg.a)),
    g: Math.round(fg.g * fg.a + bg.g * (1 - fg.a)),
    b: Math.round(fg.b * fg.a + bg.b * (1 - fg.a)),
    a: 1
  };
}

function relativeLuminance(rgb) {
  function channel(c) {
    const val = c / 255;
    return val <= 0.04045 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
  }
  return 0.2126 * channel(rgb.r) + 0.7152 * channel(rgb.g) + 0.0722 * channel(rgb.b);
}

function contrastRatio(color1, color2) {
  const l1 = relativeLuminance(color1);
  const l2 = relativeLuminance(color2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

let passed = 0;
let failed = 0;

function checkContrast(testName, fgHex, bgHex, minRequiredRatio) {
  const fg = hexToRgb(fgHex);
  const bg = hexToRgb(bgHex);
  const blendedFg = blend(fg, bg);
  const ratio = contrastRatio(blendedFg, bg);
  const ok = ratio >= minRequiredRatio - 0.001; // allow small float precision
  if (ok) {
    console.log(`  [PASS] ${testName} -> ${ratio.toFixed(2)}:1 (req >= ${minRequiredRatio}:1)`);
    passed++;
  } else {
    console.error(`  [FAIL] ${testName} -> ${ratio.toFixed(2)}:1 (req >= ${minRequiredRatio}:1) [FG: ${fgHex}, BG: ${bgHex}]`);
    failed++;
  }
  return ok;
}

console.log('====================================================');
console.log('1. 基础色彩令牌（Theme / MASK_SEAL）对比度校验');
console.log('====================================================');

const PAPER_BASE = '#DEDDD7';
const PAPER_SURFACE = '#F2F1ED';
const SURFACE = '#FFF8F7';
const SURFACE_CONTAINER = '#FFE9E7';
const SURFACE_CONTAINER_HIGHEST = '#F3DEDC';
const WHITE = '#FFFFFF';
const DARK_INK = '#1A1A1A';

// 正文核心色
checkContrast('ON_SURFACE (#241918) on PAPER_BASE', '#241918', PAPER_BASE, 4.5);
checkContrast('ON_SURFACE (#241918) on PAPER_SURFACE', '#241918', PAPER_SURFACE, 4.5);
checkContrast('ON_SURFACE_VARIANT (#574140) on PAPER_BASE', '#574140', PAPER_BASE, 4.5);
checkContrast('ON_SURFACE_VARIANT (#574140) on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);
checkContrast('ON_SURFACE_VARIANT (#574140) on SURFACE_CONTAINER', '#574140', SURFACE_CONTAINER, 4.5);
checkContrast('ON_SURFACE_VARIANT (#574140) on SURFACE_CONTAINER_HIGHEST', '#574140', SURFACE_CONTAINER_HIGHEST, 4.5);
checkContrast('PRIMARY (#7B171B) on PAPER_BASE', '#7B171B', PAPER_BASE, 4.5);
checkContrast('PRIMARY (#7B171B) on PAPER_SURFACE', '#7B171B', PAPER_SURFACE, 4.5);
checkContrast('ON_PRIMARY (#FFFFFF) on PRIMARY (#7B171B)', '#FFFFFF', '#7B171B', 4.5);
checkContrast('SEAL_RED (#B23B2F) on PAPER_SURFACE', '#B23B2F', PAPER_SURFACE, 4.5);
checkContrast('SEAL_RED (#B23B2F) on WHITE', '#B23B2F', WHITE, 4.5);
checkContrast('SEAL_RED (#B23B2F) on SURFACE_CONTAINER_HIGHEST', '#B23B2F', SURFACE_CONTAINER_HIGHEST, 4.5);

console.log('\n====================================================');
console.log('2. 组件层优化后对比度校验');
console.log('====================================================');

// 1. FooterSealBar & Footer: 落款改用 PRIMARY
checkContrast('FooterSealBar / Footer: PRIMARY on PAPER_BASE', '#7B171B', PAPER_BASE, 4.5);

// 2. Footer & CtaBlock: 辅助说明改用 ON_SURFACE_VARIANT
checkContrast('Footer: VIVID archive note on PAPER_BASE', '#574140', PAPER_BASE, 4.5);
checkContrast('CtaBlock: note text on PAPER_BASE', '#574140', PAPER_BASE, 4.5);

// 3. RecentWorkSection 空状态文案
checkContrast('RecentWorkSection: empty state title on PAPER_BASE', '#241918', PAPER_BASE, 4.5);
checkContrast('RecentWorkSection: empty state subline on PAPER_BASE', '#574140', PAPER_BASE, 4.5);

// 4. PaperFrame: FILE . NO 标签
checkContrast('PaperFrame: FILE . NO label on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);

// 5. SegmentTabs: 未选中 Chip 文本
checkContrast('SegmentTabs: unselected chip text on SURFACE_CONTAINER_HIGHEST', '#574140', SURFACE_CONTAINER_HIGHEST, 4.5);

// 6. AdjustPanel & StickerPanel: 单位与空状态提示
checkContrast('AdjustPanel: unit text on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);
checkContrast('AdjustPanel: type chip unit on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);
checkContrast('StickerPanel: empty hint text on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);

// 7. TextInput 占位符收敛为 inkMuted (#574140)
checkContrast('FloatingInput: placeholderColor on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);
checkContrast('FloatingInput: placeholderColor on PAPER_BASE', '#574140', PAPER_BASE, 4.5);

// 8. 登录与个人页次级/署名文字收敛为 inkMuted (#574140)
checkContrast('LoginPage: unselected tab on PAPER_SURFACE', '#574140', PAPER_SURFACE, 4.5);
checkContrast('MinePage: app info signature on PAPER_BASE', '#574140', PAPER_BASE, 4.5);
checkContrast('AgreementPage: bottom signature on PAPER_BASE', '#574140', PAPER_BASE, 4.5);

// 9. EmptyState: 图标对比度
checkContrast('EmptyState: archive icon on PAPER_BASE', '#574140', PAPER_BASE, 3.0);

console.log('\n====================================================');
console.log('3. Canvas 边框装裱水印对比度校验');
console.log('====================================================');

// 10. BorderPainter & PickerModal
checkContrast('BorderPainter: XMAGE logo on light background (#9A7432 on WHITE)', '#9A7432', WHITE, 3.0);
checkContrast('BorderPainter: MasterGrid labelColor (#666666 on WHITE)', '#666666', WHITE, 4.5);
checkContrast('BorderPainter: TravelStamp params (#666666 on #FBFBF9)', '#666666', '#FBFBF9', 4.5);
checkContrast('BorderPainter: TravelPostcard subline (#476375 on #E4ECF0)', '#476375', '#E4ECF0', 4.5);
checkContrast('BorderPainter: SlimWhite rightText (#666666 on WHITE)', '#666666', WHITE, 4.5);
checkContrast('BorderTemplatePickerModal: Retro 1984 No.24 (#666666 on #F5F2E8)', '#666666', '#F5F2E8', 4.5);

console.log('\n====================================================');
console.log('4. 源代码实际色值扫描与断言（防止遗留低对比度色）');
console.log('====================================================');

function assertFileNotContains(relPath, pattern, message) {
  const fullPath = path.resolve(root, relPath);
  const content = fs.readFileSync(fullPath, 'utf8');
  const found = content.includes(pattern);
  if (!found) {
    console.log(`  [PASS] ${relPath} 不含 ${pattern}`);
    passed++;
  } else {
    console.error(`  [FAIL] ${relPath} 仍包含 ${pattern}: ${message}`);
    failed++;
  }
}

// 检查是否已消除违规硬编码色或错误令牌引用
assertFileNotContains('entry/src/main/ets/components/common/FooterSealBar.ets', 'Theme.PRIMARY_60', '应改用 Theme.PRIMARY');
assertFileNotContains('entry/src/main/ets/components/home/Footer.ets', 'Theme.PRIMARY_60', '应改用 Theme.PRIMARY');
assertFileNotContains('entry/src/main/ets/components/home/Footer.ets', 'Theme.OUTLINE', '应改用 Theme.ON_SURFACE_VARIANT');
assertFileNotContains('entry/src/main/ets/components/home/CtaBlock.ets', 'Theme.OUTLINE', '应改用 Theme.ON_SURFACE_VARIANT');
assertFileNotContains('entry/src/main/ets/components/home/RecentWorkSection.ets', '.fontColor(Theme.OUTLINE_VARIANT)', '空状态文字不应使用超低对比度 OUTLINE_VARIANT');
assertFileNotContains('entry/src/main/ets/components/common/PaperFrame.ets', 'Theme.OUTLINE', 'FILE . NO 应改用 Theme.ON_SURFACE_VARIANT');
assertFileNotContains('entry/src/main/ets/components/common/SegmentTabs.ets', 'Theme.ON_SURFACE_VARIANT_70', 'Chip 文本应改用 Theme.ON_SURFACE_VARIANT');
assertFileNotContains('entry/src/main/ets/components/MaskSeal.ets', "'#957d7a'", '占位符应改用 inkMuted');
assertFileNotContains('entry/src/main/ets/pages/LoginPage.ets', "'#987f7b'", '未激活 Tab 应改用 inkMuted');
assertFileNotContains('entry/src/main/ets/pages/LoginPage.ets', 'LoginUnavailableOverlay', 'LoginPage 不应包含不可用遮罩');
assertFileNotContains('entry/src/main/ets/pages/RegisterPage.ets', 'LoginUnavailableOverlay', 'RegisterPage 不应包含不可用遮罩');
assertFileNotContains('entry/src/main/ets/components/mine/MinePage.ets', "'#8a5c57'", '署名应改用 inkMuted');
assertFileNotContains('entry/src/main/ets/components/AgreementPage.ets', "'#8a5c57'", '署名应改用 inkMuted');

console.log('\n====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
} else {
  console.log('🎉 所有色彩对比度检查项均满足要求！');
}
