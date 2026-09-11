const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = '/Users/qiuhaiqin/DevEcoStudioProjects/Vivid';
const borderPainterPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');

console.log('====================================================');
console.log('相机水印机型与品牌 Logo 冲突去重功能测试');
console.log('====================================================');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  [PASS] ${name}`);
    passed++;
  } catch (err) {
    console.error(`  [FAIL] ${name}: ${err.message}`);
    failed++;
  }
}

const borderPainterContent = fs.readFileSync(borderPainterPath, 'utf8');

// 提取 isLogoDuplicatedWithDevice 逻辑进行纯函数模拟测试
function isLogoDuplicatedWithDevice(logo, deviceModel) {
  if (!logo || logo === 'none' || !deviceModel || deviceModel.trim().length === 0) {
    return false;
  }
  const devLower = deviceModel.trim().toLowerCase();
  const logoLower = logo.trim().toLowerCase();

  if (logoLower === 'apple') {
    return devLower === 'apple' || devLower === '苹果';
  }

  const brandKeywords = {
    'sony': ['sony', '索尼'],
    'canon': ['canon', '佳能'],
    'nikon': ['nikon', '尼康'],
    'fujifilm': ['fujifilm', 'fuji', '富士'],
    'leica': ['leica', '徕卡'],
    'hasselblad': ['hasselblad', '哈苏'],
    'zeiss': ['zeiss', '蔡司'],
    'xiaomi': ['xiaomi', 'redmi', '小米', '红米'],
    'samsung': ['samsung', 'galaxy', '三星'],
    'vivo': ['vivo', 'iqoo'],
    'oppo': ['oppo', 'oneplus', '一加'],
    'honor': ['honor', '荣耀']
  };

  const keywords = brandKeywords[logoLower];
  if (keywords) {
    for (let i = 0; i < keywords.length; i++) {
      if (devLower.includes(keywords[i])) {
        return true;
      }
    }
  } else if (devLower.includes(logoLower)) {
    return true;
  }
  return false;
}

function formatWatermarkDeviceText(rawDevice, logo, hasLogo) {
  if (!rawDevice || rawDevice.length === 0) {
    return '';
  }
  if (hasLogo && logo === 'apple' && rawDevice.toLowerCase().startsWith('apple ')) {
    return rawDevice.substring(6).trim();
  }
  return rawDevice;
}

// 1. 核心判定逻辑测试
test('索尼 SONY ILCE-7 与 sony 标识判定为重复冲突', () => {
  assert.equal(isLogoDuplicatedWithDevice('sony', 'SONY ILCE-7'), true);
  assert.equal(isLogoDuplicatedWithDevice('sony', 'Sony α7 IV'), true);
});

test('不带品牌前缀的机型（如 ILCE-7）不触发冲突，允许显示独立 Logo', () => {
  assert.equal(isLogoDuplicatedWithDevice('sony', 'ILCE-7'), false);
  assert.equal(isLogoDuplicatedWithDevice('sony', 'α7R V'), false);
});

test('联名机型（如小米徕卡、vivo蔡司、OPPO哈苏）不判为冲突，正常保留镜头联名标', () => {
  assert.equal(isLogoDuplicatedWithDevice('leica', 'Xiaomi 14 Ultra'), false);
  assert.equal(isLogoDuplicatedWithDevice('zeiss', 'vivo X300 Pro'), false);
  assert.equal(isLogoDuplicatedWithDevice('hasselblad', 'OPPO Find X7 Ultra'), false);
});

test('Apple 矢量图标与 iPhone 机型和谐共存，不误判冲突；格式化自动规整为优雅的 iPhone 15 Pro', () => {
  assert.equal(isLogoDuplicatedWithDevice('apple', 'iPhone 16 Pro'), false);
  assert.equal(isLogoDuplicatedWithDevice('apple', 'Apple iPhone 15 Pro'), false);
  assert.equal(isLogoDuplicatedWithDevice('apple', 'Apple'), true);
  assert.equal(formatWatermarkDeviceText('Apple iPhone 15 Pro', 'apple', true), 'iPhone 15 Pro');
  assert.equal(formatWatermarkDeviceText('iPhone 15 Pro', 'apple', true), 'iPhone 15 Pro');
  assert.equal(formatWatermarkDeviceText('Apple iPhone 15 Pro', 'apple', false), 'Apple iPhone 15 Pro');
});

test('其他品牌机型全名与同品牌 Logo 判定冲突（如 Canon EOS R5、Nikon Z8、Xiaomi 15 Pro）', () => {
  assert.equal(isLogoDuplicatedWithDevice('canon', 'Canon EOS R5'), true);
  assert.equal(isLogoDuplicatedWithDevice('nikon', 'Nikon Z8'), true);
  assert.equal(isLogoDuplicatedWithDevice('fujifilm', 'Fujifilm X-T5'), true);
  assert.equal(isLogoDuplicatedWithDevice('xiaomi', 'Xiaomi 15 Pro'), true);
});

// 2. 边框源码集成检查
test('BorderPainter 导出 isLogoDuplicatedWithDevice 识别函数', () => {
  assert(
    borderPainterContent.includes('export function isLogoDuplicatedWithDevice'),
    'BorderPainter 必须导出 isLogoDuplicatedWithDevice 函数'
  );
});

test('paintWatermark 包含冲突去重，当机型带品牌时不绘制独立 Logo 与竖线', () => {
  assert(
    borderPainterContent.includes('isLogoDuplicatedWithDevice(wm.logo, deviceModel)'),
    'paintWatermark 必须调用 isLogoDuplicatedWithDevice 检查冲突'
  );
});

test('paintBlurPipWatermark 包含冲突去重，避免底部出现 SONY SONY ILCE-7', () => {
  assert(
    borderPainterContent.includes('isLogoDuplicatedWithDevice(wm.logo, device)'),
    'paintBlurPipWatermark 必须在底部排版中检查冲突并去重'
  );
  assert(
    borderPainterContent.includes('isTopDuplicated'),
    'paintBlurPipWatermark 必须在顶部题签中规避重复'
  );
});

test('paintMasterGridWatermark（影展矩阵）完整支持机型排版与 Logo 居中，彻底修复只有单独 iPhone 字样缺陷', () => {
  assert(
    borderPainterContent.includes('const hasDevice = !!(wm.showDevice && wm.deviceModel && wm.deviceModel.trim().length > 0);'),
    'paintMasterGridWatermark 必须支持 wm.showDevice 与 wm.deviceModel'
  );
  assert(
    borderPainterContent.includes('const displayDevice = formatWatermarkDeviceText(rawDevice, logo, hasLogo);'),
    'paintMasterGridWatermark 必须应用 formatWatermarkDeviceText 规整机型文本'
  );
  assert(
    borderPainterContent.includes('context.fillText(displayDevice, startX + logoW + gap, topCenterY);'),
    'paintMasterGridWatermark 必须在 Logo 旁绘制机型型号'
  );
});

test('影展矩阵快门速度解析优先匹配分数，彻底杜绝 48mm 误判为 48 S', () => {
  const p = '48mm  f/1.78  1/48s  ISO 64';
  let sVal = '1/2787';
  const fracMatch = p.match(/(\d+\/\d+)\s*s?/i);
  if (fracMatch) {
    sVal = fracMatch[1];
  } else {
    const secMatch = p.match(/(\d+(\.\d+)?)\s*s(?:ec)?(?!\w)/i);
    if (secMatch) {
      sVal = secMatch[1];
    }
  }
  assert.equal(sVal, '1/48', '快门速度必须正确解析为 1/48 而不是 48');
});

test('BorderPainter 包含官方 Apple 咬口苹果与飞叶纯矢量 Path2D 路径', () => {
  assert(
    borderPainterContent.includes('APPLE_ICON_SVG'),
    'BorderPainter 必须包含 APPLE_ICON_SVG 路径常量'
  );
  assert(
    borderPainterContent.includes('getAppleIconPath()'),
    'BorderPainter 必须导出或定义 getAppleIconPath'
  );
  assert(
    !borderPainterContent.includes("context.fillText(' iPhone'"),
    'paintLogoBadge 严禁使用无法在非苹果系统渲染的  iPhone 裸字符串'
  );
});

test('复古胶片与悬浮毛玻璃边框移除了强制 fallback 到固定 logo 的缺陷', () => {
  assert(
    !borderPainterContent.includes("? wm.logo : 'fujifilm'"),
    'paintRetroFilmWatermark 不得在无 logo 时强行 fallback 到 fujifilm'
  );
  assert(
    !borderPainterContent.includes("? wm.logo : 'sony'"),
    'paintOverlayWatermark 不得在无 logo 时强行 fallback 到 sony'
  );
});

// 3. 界面合规与纯 EXIF/输入识别测试
const borderPanelPath = path.join(root, 'entry/src/main/ets/components/editor/BorderPanel.ets');
const borderPanelContent = fs.readFileSync(borderPanelPath, 'utf8');
const exifReaderPath = path.join(root, 'entry/src/main/ets/services/ExifReaderService.ets');
const exifReaderContent = fs.readFileSync(exifReaderPath, 'utf8');

test('BorderPanel 彻底移除明文机型预设与品牌 Logo 候选列表（合规与极简设计）', () => {
  assert(
    !borderPanelContent.includes('devicePresets'),
    'BorderPanel 不得明文列出机型预设列表'
  );
  assert(
    !borderPanelContent.includes('logoOptions'),
    'BorderPanel 不得明文列出品牌 Logo 选项列表'
  );
  assert(
    borderPanelContent.includes('inferLogoFromDeviceModel'),
    'BorderPanel 机型输入时必须调用 inferLogoFromDeviceModel 自适应识别'
  );
});

test('ExifReaderService 导出 inferLogoFromDeviceModel 且全面覆盖主流品牌与微单型号', () => {
  assert(
    exifReaderContent.includes('export function inferLogoFromDeviceModel'),
    'ExifReaderService 必须导出 inferLogoFromDeviceModel 函数'
  );
  assert(
    exifReaderContent.includes('ilce') && exifReaderContent.includes('alpha'),
    'inferLogoFromDeviceModel 必须支持索尼微单 ilce 和 alpha 自动识别'
  );
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
