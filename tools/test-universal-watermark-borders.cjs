const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const sharedContractsPath = path.join(root, 'entry/src/main/ets/models/SharedContracts.ets');
const borderCatalogPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderCatalog.ets');
const borderStatePath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderState.ets');
const borderLayoutResolverPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderLayoutResolver.ets');
const borderPainterPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');
const borderCompositionPath = path.join(root, 'entry/src/main/ets/services/BorderCompositionService.ets');
const previewAreaPath = path.join(root, 'entry/src/main/ets/components/editor/PreviewArea.ets');
const borderPanelPath = path.join(root, 'entry/src/main/ets/components/editor/BorderPanel.ets');
const templatePickerModalPath = path.join(root, 'entry/src/main/ets/components/editor/BorderTemplatePickerModal.ets');

console.log('====================================================');
console.log('通用摄影水印边框套件（4 大通用版式）专项测试套件');
console.log('====================================================');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✔ [PASS] ${name}`);
    passed++;
  } catch (err) {
    console.error(`  ✘ [FAIL] ${name}: ${err.message}`);
    failed++;
  }
}

const sharedContractsContent = fs.readFileSync(sharedContractsPath, 'utf8');
const borderCatalogContent = fs.readFileSync(borderCatalogPath, 'utf8');
const borderStateContent = fs.readFileSync(borderStatePath, 'utf8');

// ==========================================
// 1. 数据契约层 (SharedContracts) 校验
// ==========================================
test('WatermarkConfig 包含通用扩展字段 (gpsText, subTitle, headerText)', () => {
  assert(sharedContractsContent.includes('gpsText?: string;'), '必须包含 gpsText 可选字段');
  assert(sharedContractsContent.includes('subTitle?: string;'), '必须包含 subTitle 可选字段');
  assert(sharedContractsContent.includes('headerText?: string;'), '必须包含 headerText 可选字段');
});

test('cloneWatermarkConfig 与 defaultWatermarkConfig 包含新扩展字段', () => {
  assert(sharedContractsContent.includes('gpsText:'), 'cloneWatermarkConfig 必须处理 gpsText');
  assert(sharedContractsContent.includes('subTitle:'), 'cloneWatermarkConfig 必须处理 subTitle');
  assert(sharedContractsContent.includes('headerText:'), 'cloneWatermarkConfig 必须处理 headerText');
});

// ==========================================
// 2. 边框元数据与目录 (BorderCatalog & BorderState) 校验
// ==========================================
test('BorderCatalog 注册 4 款新一代通用模板', () => {
  assert(borderCatalogContent.includes("'watermark_centered_specs'"), '必须注册 watermark_centered_specs (居中全参)');
  assert(borderCatalogContent.includes("'watermark_harmonic_editorial'"), '必须注册 watermark_harmonic_editorial (同调画报)');
  assert(borderCatalogContent.includes("'watermark_minimal_keyvalue'"), '必须注册 watermark_minimal_keyvalue (极简键值)');
  assert(borderCatalogContent.includes("'watermark_blur_pip'"), '必须包含 watermark_blur_pip (画中画卡片)');
});

test('isWatermarkTemplate 正确涵盖所有 4 款新通用模板', () => {
  const checkFuncMatch = borderCatalogContent.match(/export function isWatermarkTemplate[\s\S]*?\{([\s\S]*?)\}/);
  assert(checkFuncMatch, '必须导出 isWatermarkTemplate 函数');
  const body = checkFuncMatch[1];
  assert(body.includes('watermark_centered_specs'), 'isWatermarkTemplate 必须包含 watermark_centered_specs');
  assert(body.includes('watermark_harmonic_editorial'), 'isWatermarkTemplate 必须包含 watermark_harmonic_editorial');
  assert(body.includes('watermark_minimal_keyvalue'), 'isWatermarkTemplate 必须包含 watermark_minimal_keyvalue');
  assert(body.includes('watermark_blur_pip'), 'isWatermarkTemplate 必须包含 watermark_blur_pip');
});

test('BorderState 包含对新模板的规范化与默认参数配置', () => {
  assert(borderStateContent.includes('watermark_centered_specs'), 'BorderState 必须支持 watermark_centered_specs');
  assert(borderStateContent.includes('watermark_harmonic_editorial'), 'BorderState 必须支持 watermark_harmonic_editorial');
  assert(borderStateContent.includes('watermark_minimal_keyvalue'), 'BorderState 必须支持 watermark_minimal_keyvalue');
});

console.log('====================================================');
console.log(`Task 1 测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');
if (failed > 0) {
  process.exit(1);
}
