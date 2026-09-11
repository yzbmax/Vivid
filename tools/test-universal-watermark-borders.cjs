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

test('居中全参与极简键值声明 width 能力，支持底栏高度与字号实时无级调节', () => {
  const centeredMatch = borderCatalogContent.match(/templateId:\s*'watermark_centered_specs'[\s\S]*?capabilities:\s*\[([\s\S]*?)\]/);
  assert(centeredMatch, '必须找到 watermark_centered_specs 的 capabilities');
  assert(centeredMatch[1].includes("'width'"), 'watermark_centered_specs 必须声明 width 能力');

  const kvMatch = borderCatalogContent.match(/templateId:\s*'watermark_minimal_keyvalue'[\s\S]*?capabilities:\s*\[([\s\S]*?)\]/);
  assert(kvMatch, '必须找到 watermark_minimal_keyvalue 的 capabilities');
  assert(kvMatch[1].includes("'width'"), 'watermark_minimal_keyvalue 必须声明 width 能力');
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

test('paintMinimalKeyvalueWatermark 包含键值对参数格式化与机型名称排版', () => {
  assert(borderPainterContent.includes('Aperture |') || borderPainterContent.includes('formatKeyValueSpecs'), '必须支持 Aperture | 键值对排版');
  const kvFuncMatch = borderPainterContent.match(/function paintMinimalKeyvalueWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(kvFuncMatch, '必须提取到 paintMinimalKeyvalueWatermark 函数实现');
  const kvBody = kvFuncMatch[1];
  assert(kvBody.includes('displayDevice') || kvBody.includes('deviceModel'), 'paintMinimalKeyvalueWatermark 必须包含机型名称呈现');
});

test('paintCenteredSpecsWatermark 具备底部呼吸留白与阶梯间距结构，杜绝排版紧迫贴底', () => {
  const centeredFuncMatch = borderPainterContent.match(/function paintCenteredSpecsWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(centeredFuncMatch, '必须提取到 paintCenteredSpecsWatermark 函数实现');
  const centeredBody = centeredFuncMatch[1];
  assert(centeredBody.includes('bottomMargin'), 'paintCenteredSpecsWatermark 必须包含明确的 bottomMargin 底部留白保护');
  assert(centeredBody.includes('CenteredStackItem') || centeredBody.includes('items.push'), 'paintCenteredSpecsWatermark 必须具备结构化梯级间距');
});

test('居中全参、极简键值与无界悬浮水印字号及高度随 safe.widthRatio 顺畅联动，彻底消除死板硬编码封顶', () => {
  const centeredFuncMatch = borderPainterContent.match(/function paintCenteredSpecsWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(centeredFuncMatch, '必须提取到 paintCenteredSpecsWatermark');
  const centeredBody = centeredFuncMatch[1];
  assert(centeredBody.includes('safeRatio') || centeredBody.includes('safe.widthRatio'), '居中全参必须消费 safe.widthRatio');
  assert(!centeredBody.includes('Math.min(22 * scale'), '居中全参不得包含死板的 22*scale 字号硬编码封顶');

  const kvFuncMatch = borderPainterContent.match(/function paintMinimalKeyvalueWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(kvFuncMatch, '必须提取到 paintMinimalKeyvalueWatermark');
  const kvBody = kvFuncMatch[1];
  assert(kvBody.includes('safeRatio') || kvBody.includes('safe.widthRatio'), '极简键值必须消费 safe.widthRatio');
  assert(!kvBody.includes('Math.min(22 * scale'), '极简键值不得包含死板的 22*scale 字号硬编码封顶');

  const overlayFuncMatch = borderPainterContent.match(/function paintOverlayWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(overlayFuncMatch, '必须提取到 paintOverlayWatermark');
  const overlayBody = overlayFuncMatch[1];
  assert(overlayBody.includes('safeRatio') || overlayBody.includes('safe.widthRatio'), '无界悬浮必须消费 safe.widthRatio');
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

test('BorderPainter 必须排除 watermark_harmonic_editorial 实色衬底，确保弥散色彩通透', () => {
  assert(borderPainterContent.includes("geometry.templateId !== 'watermark_harmonic_editorial'"),
    'paintBorder 必须将 watermark_harmonic_editorial 排除在实色衬底填充之外');
});

// ==========================================
// 6. UI 面板与全屏模版选择器 (BorderPanel & PickerModal) 校验
// ==========================================
const borderPanelContent = fs.readFileSync(borderPanelPath, 'utf8');
const templatePickerModalContent = fs.readFileSync(templatePickerModalPath, 'utf8');

test('全工程严禁硬编码同调画报历史固定实色 658A97', () => {
  assert(!borderStateContent.includes('658A97'), 'BorderState 不得包含 658A97');
  assert(!previewAreaContent.includes('658A97'), 'PreviewArea 不得包含 658A97');
  assert(!borderPanelContent.includes('658A97'), 'BorderPanel 不得包含 658A97');
  assert(!templatePickerModalContent.includes('658A97'), 'TemplatePickerModal 不得包含 658A97');
});

test('BorderPanel 与 PickerModal 缩略图为 watermark_harmonic_editorial 应用动态模糊弥散', () => {
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_harmonic_editorial'"), 'BorderPanel 必须支持');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_harmonic_editorial'"), 'PickerModal 必须支持');
});

// ==========================================
// 7. 新增 5 款全新通用摄影水印边框专项校验
// ==========================================
test('WatermarkConfig 包含 lensModel 与 showLens 字段，支持镜头型号提取与展示', () => {
  assert(sharedContractsContent.includes('lensModel?: string;'), '必须包含 lensModel 镜头型号字段');
  assert(sharedContractsContent.includes('showLens?: boolean;'), '必须包含 showLens 镜头展示开关');
  assert(sharedContractsContent.includes('lensModel:'), 'default/cloneWatermarkConfig 必须处理 lensModel');
  assert(sharedContractsContent.includes('showLens:'), 'default/cloneWatermarkConfig 必须处理 showLens');
});

test('BorderCatalog 注册 5 款全新通用摄影模版', () => {
  assert(borderCatalogContent.includes("'watermark_inset_wireframe'"), '必须注册 watermark_inset_wireframe (画中画浮雕)');
  assert(borderCatalogContent.includes("'watermark_gallery_inline'"), '必须注册 watermark_gallery_inline (画廊微印)');
  assert(borderCatalogContent.includes("'watermark_curated_editorial'"), '必须注册 watermark_curated_editorial (策展矩阵)');
  assert(borderCatalogContent.includes("'watermark_monolith_specs'"), '必须注册 watermark_monolith_specs (典藏分柱)');
  assert(borderCatalogContent.includes("'watermark_ambient_side_ruler'"), '必须注册 watermark_ambient_side_ruler (弥散侧标)');
});

test('isWatermarkTemplate 涵盖 5 款全新模版', () => {
  assert(borderCatalogContent.includes('watermark_inset_wireframe'), 'isWatermarkTemplate 必须包含 watermark_inset_wireframe');
  assert(borderCatalogContent.includes('watermark_gallery_inline'), 'isWatermarkTemplate 必须包含 watermark_gallery_inline');
  assert(borderCatalogContent.includes('watermark_curated_editorial'), 'isWatermarkTemplate 必须包含 watermark_curated_editorial');
  assert(borderCatalogContent.includes('watermark_monolith_specs'), 'isWatermarkTemplate 必须包含 watermark_monolith_specs');
  assert(borderCatalogContent.includes('watermark_ambient_side_ruler'), 'isWatermarkTemplate 必须包含 watermark_ambient_side_ruler');
});

test('BorderLayoutResolver 包含 5 款新模版的几何解析函数与路由分发', () => {
  assert(borderLayoutResolverContent.includes('resolveInsetWireframeWatermark'), '必须包含 resolveInsetWireframeWatermark');
  assert(borderLayoutResolverContent.includes('resolveGalleryInlineWatermark'), '必须包含 resolveGalleryInlineWatermark');
  assert(borderLayoutResolverContent.includes('resolveCuratedEditorialWatermark'), '必须包含 resolveCuratedEditorialWatermark');
  assert(borderLayoutResolverContent.includes('resolveMonolithSpecsWatermark'), '必须包含 resolveMonolithSpecsWatermark');
  assert(borderLayoutResolverContent.includes('resolveAmbientSideRulerWatermark'), '必须包含 resolveAmbientSideRulerWatermark');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_inset_wireframe'"), '必须分发 watermark_inset_wireframe');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_gallery_inline'"), '必须分发 watermark_gallery_inline');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_curated_editorial'"), '必须分发 watermark_curated_editorial');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_monolith_specs'"), '必须分发 watermark_monolith_specs');
  assert(borderLayoutResolverContent.includes("templateId === 'watermark_ambient_side_ruler'"), '必须分发 watermark_ambient_side_ruler');
});

test('BorderPainter 包含 parseExtractedSpecs 与 5 款新模版的高精度 Canvas 渲染实现', () => {
  assert(borderPainterContent.includes('parseExtractedSpecs'), '必须导出 parseExtractedSpecs');
  assert(borderPainterContent.includes('paintInsetWireframeWatermark'), '必须实现 paintInsetWireframeWatermark');
  assert(borderPainterContent.includes('paintGalleryInlineWatermark'), '必须实现 paintGalleryInlineWatermark');
  assert(borderPainterContent.includes('paintCuratedEditorialWatermark'), '必须实现 paintCuratedEditorialWatermark');
  assert(borderPainterContent.includes('paintMonolithSpecsWatermark'), '必须实现 paintMonolithSpecsWatermark');
  assert(borderPainterContent.includes('paintAmbientSideRulerWatermark'), '必须实现 paintAmbientSideRulerWatermark');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_inset_wireframe'"), 'paintBorder 必须路由 watermark_inset_wireframe');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_gallery_inline'"), 'paintBorder 必须路由 watermark_gallery_inline');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_curated_editorial'"), 'paintBorder 必须路由 watermark_curated_editorial');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_monolith_specs'"), 'paintBorder 必须路由 watermark_monolith_specs');
  assert(borderPainterContent.includes("geometry.templateId === 'watermark_ambient_side_ruler'"), 'paintBorder 必须路由 watermark_ambient_side_ruler');
});

test('BorderCompositionService 与 PreviewArea 包含弥散背景模板合成支持', () => {
  assert(borderCompositionContent.includes('watermark_inset_wireframe'), 'BorderCompositionService 必须支持 watermark_inset_wireframe');
  assert(borderCompositionContent.includes('watermark_ambient_side_ruler'), 'BorderCompositionService 必须支持 watermark_ambient_side_ruler');
  assert(previewAreaContent.includes('watermark_inset_wireframe'), 'PreviewArea 必须支持 watermark_inset_wireframe');
  assert(previewAreaContent.includes('watermark_ambient_side_ruler'), 'PreviewArea 必须支持 watermark_ambient_side_ruler');
});

test('BorderPainter 必须排除 watermark_inset_wireframe 与 watermark_ambient_side_ruler 实色衬底', () => {
  assert(borderPainterContent.includes("geometry.templateId !== 'watermark_inset_wireframe'"),
    'paintBorder 必须将 watermark_inset_wireframe 排除在实色衬底填充之外');
  assert(borderPainterContent.includes("geometry.templateId !== 'watermark_ambient_side_ruler'"),
    'paintBorder 必须将 watermark_ambient_side_ruler 排除在实色衬底填充之外');
});

test('BorderPanel 与 PickerModal 为 5 款新模版提供专用缩略卡片渲染', () => {
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_inset_wireframe'"), 'BorderPanel 必须支持 watermark_inset_wireframe');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_gallery_inline'"), 'BorderPanel 必须支持 watermark_gallery_inline');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_curated_editorial'"), 'BorderPanel 必须支持 watermark_curated_editorial');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_monolith_specs'"), 'BorderPanel 必须支持 watermark_monolith_specs');
  assert(borderPanelContent.includes("tpl.templateId === 'watermark_ambient_side_ruler'"), 'BorderPanel 必须支持 watermark_ambient_side_ruler');

  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_inset_wireframe'"), 'PickerModal 必须支持 watermark_inset_wireframe');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_gallery_inline'"), 'PickerModal 必须支持 watermark_gallery_inline');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_curated_editorial'"), 'PickerModal 必须支持 watermark_curated_editorial');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_monolith_specs'"), 'PickerModal 必须支持 watermark_monolith_specs');
  assert(templatePickerModalContent.includes("tpl.templateId === 'watermark_ambient_side_ruler'"), 'PickerModal 必须支持 watermark_ambient_side_ruler');
});

test('cleanDeviceWithoutBrand 规范化剔除冗余品牌名且保留纯净型号', () => {
  assert(borderPainterContent.includes('export function cleanDeviceWithoutBrand'), 'BorderPainter 必须导出 cleanDeviceWithoutBrand');
  assert(borderPainterContent.includes('cleanDeviceWithoutBrand(wm.deviceModel'), '水印函数中必须消费 cleanDeviceWithoutBrand');
});

test('paintInsetWireframeWatermark 必须包含画内嵌入式线框与基线对齐排版', () => {
  const insetMatch = borderPainterContent.match(/function paintInsetWireframeWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(insetMatch, '必须提取到 paintInsetWireframeWatermark 函数体');
  const body = insetMatch[1];
  assert(body.includes('px + inset') && body.includes('pw - inset * 2'), '线框必须内嵌在照片画幅内部');
  assert(body.includes('baseBottomY'), '左侧镜头与右侧 ISO 必须共享 baseBottomY 基线');
  assert(body.includes('dateStr'), '右上角必须包含拍摄日期');
  assert(body.includes('apertureGrace'), '光圈值必须包含优雅弧线 ƒ4.5');
});

test('resolveAmbientSideRulerWatermark 必须三边等宽对称且右侧栏为 3.0 倍基准边距', () => {
  const resolverMatch = borderLayoutResolverContent.match(/function resolveAmbientSideRulerWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(resolverMatch, '必须提取到 resolveAmbientSideRulerWatermark 函数体');
  const body = resolverMatch[1];
  assert(body.includes('left = baseMargin'), '左边距必须等于 baseMargin');
  assert(body.includes('top = baseMargin'), '上边距必须等于 baseMargin');
  assert(body.includes('bottom = baseMargin'), '下边距必须等于 baseMargin');
  assert(body.includes('baseMargin * 3.0'), '右侧栏必须为 baseMargin 的 3.0 倍');
});

test('paintAmbientSideRulerWatermark 必须对齐图二排版（顶格Logo、居中斜体f参数、双列顺时针底对齐）', () => {
  const rulerMatch = borderPainterContent.match(/function paintAmbientSideRulerWatermark[\s\S]*?\{([\s\S]*?)\n\}/);
  assert(rulerMatch, '必须提取到 paintAmbientSideRulerWatermark 函数体');
  const body = rulerMatch[1];
  assert(body.includes('context.strokeStyle = \'#FFFFFF\''), '照片四周必须为纯白细边框');
  assert(body.includes('py + Math.max(3,'), '顶部 Logo 必须顶格对齐照片上沿');
  assert(body.includes('py + ph * 0.5'), '曝光参数必须绝对垂直居中展开');
  assert(body.includes('italic 500') && body.includes('serif'), '光圈单位必须为优雅数学斜体 f');
  assert(body.includes('rotate(Math.PI / 2)'), '底部文字必须顺时针 90° 旋转向下阅读');
  assert(body.includes("textAlign = 'right'"), '底部文字必须采用 right 对齐');
  assert(body.includes('bottomPadY = py + ph -'), '底部文字末端必须对齐照片底边线');
});


console.log('====================================================');
console.log(`全部测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');
if (failed > 0) {
  process.exit(1);
}
