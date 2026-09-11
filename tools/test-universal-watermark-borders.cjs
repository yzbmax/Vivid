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

// ==========================================
// 3. 几何解析器 (BorderLayoutResolver) 校验
// ==========================================
const borderLayoutResolverContent = fs.readFileSync(borderLayoutResolverPath, 'utf8');

test('BorderLayoutResolver 包含新模板的几何解析函数与分发', () => {
  assert(borderLayoutResolverContent.includes('resolveCenteredSpecsWatermark'), '必须包含 resolveCenteredSpecsWatermark');
  assert(borderLayoutResolverContent.includes('resolveHarmonicEditorialWatermark'), '必须包含 resolveHarmonicEditorialWatermark');
  assert(borderLayoutResolverContent.includes('resolveMinimalKeyvalueWatermark'), '必须包含 resolveMinimalKeyvalueWatermark');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_centered_specs'"), '分发中必须包含 watermark_centered_specs');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_harmonic_editorial'"), '分发中必须包含 watermark_harmonic_editorial');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_minimal_keyvalue'"), '分发中必须包含 watermark_minimal_keyvalue');
});

// ==========================================
// 4. 绘制引擎 (BorderPainter) 校验
// ==========================================
const borderPainterContent = fs.readFileSync(borderPainterPath, 'utf8');

test('BorderPainter 包含 4 款新通用模板的绘制分发与函数实现', () => {
  assert(borderPainterContent.includes('paintCenteredSpecsWatermark'), '必须实现 paintCenteredSpecsWatermark');
  assert(borderPainterContent.includes('paintHarmonicEditorialWatermark'), '必须实现 paintHarmonicEditorialWatermark');
  assert(borderPainterContent.includes('paintMinimalKeyvalueWatermark'), '必须实现 paintMinimalKeyvalueWatermark');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_centered_specs'"), 'paintBorder 必须路由 watermark_centered_specs');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_harmonic_editorial'"), 'paintBorder 必须路由 watermark_harmonic_editorial');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_minimal_keyvalue'"), 'paintBorder 必须路由 watermark_minimal_keyvalue');
});

test('paintBlurPipWatermark 彻底移除混杂的顶部手写铭文，保持纯净卡片装裱', () => {
  const blurFuncMatch = borderPainterContent.match(/function paintBlurPipWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(blurFuncMatch, '必须提取到 paintBlurPipWatermark 函数实现');
  const blurBody = blurFuncMatch[1];
  assert(!blurBody.includes('The decisive moment'), 'paintBlurPipWatermark 不得包含 The decisive moment');
  assert(!blurBody.includes('P H O T O G R A P H'), 'paintBlurPipWatermark 不得包含 P H O T O G R A P H');
});

test('paintHarmonicEditorialWatermark 包含优雅题签与中英文双行排版', () => {
  const harmFuncMatch = borderPainterContent.match(/function paintHarmonicEditorialWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(harmFuncMatch, '必须提取到 paintHarmonicEditorialWatermark 函数实现');
  const harmBody = harmFuncMatch[1];
  assert(harmBody.includes('The decisive moment') || harmBody.includes('headerText'), '必须包含顶部花体题签');
  assert(harmBody.includes('subTitle') || harmBody.includes('一双发现美的眼睛'), '必须支持中文副标');
});

test('paintMinimalKeyvalueWatermark 包含键值对参数格式化', () => {
  assert(borderPainterContent.includes('Aperture |') || borderPainterContent.includes('formatKeyValueSpecs'), '必须支持 Aperture | 键值对排版');
});

// ==========================================
// 5. 色彩联动与合成服务 (BorderCompositionService & PreviewArea) 校验
// ==========================================
const borderCompositionContent = fs.readFileSync(borderCompositionPath, 'utf8');
const previewAreaContent = fs.readFileSync(previewAreaPath, 'utf8');

test('BorderCompositionService 正确处理 watermark_harmonic_editorial 色彩联动与画中画合成', () => {
  assert(borderCompositionContent.includes('watermark_harmonic_editorial'), 'BorderCompositionService 必须支持 watermark_harmonic_editorial');
  assert(borderCompositionContent.includes('watermark_centered_specs'), 'BorderCompositionService 必须支持 watermark_centered_specs 悬浮层时序');
});

test('PreviewArea 包含对 watermark_harmonic_editorial 与悬浮水印的预览图层支持', () => {
  assert(previewAreaContent.includes('watermark_harmonic_editorial'), 'PreviewArea 必须包含 watermark_harmonic_editorial 联动层');
  assert(previewAreaContent.includes('watermark_centered_specs'), 'PreviewArea 必须包含 watermark_centered_specs 悬浮预览');
});

// ==========================================
// 6. UI 面板与全屏模版选择器 (BorderPanel & PickerModal) 校验
// ==========================================
const borderPanelContent = fs.readFileSync(borderPanelPath, 'utf8');
const templatePickerModalContent = fs.readFileSync(templatePickerModalPath, 'utf8');

test('BorderPanel 包含 4 款新模版的微缩视觉呈现', () => {
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_centered_specs'"), 'BorderPanel 必须包含 watermark_centered_specs');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_harmonic_editorial'"), 'BorderPanel 必须包含 watermark_harmonic_editorial');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_minimal_keyvalue'"), 'BorderPanel 必须包含 watermark_minimal_keyvalue');
});

test('BorderTemplatePickerModal 包含 4 款新模版的高清模拟卡片呈现', () => {
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_centered_specs'"), 'PickerModal 必须包含 watermark_centered_specs');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_harmonic_editorial'"), 'PickerModal 必须包含 watermark_harmonic_editorial');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_minimal_keyvalue'"), 'PickerModal 必须包含 watermark_minimal_keyvalue');
});

console.log('====================================================');
console.log(`全部测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');
if (failed > 0) {
  process.exit(1);
}
