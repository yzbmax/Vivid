const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 1: 中国传统色谱与主色提取测试');
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

// 1. ColophonModels.ets 校验
test('ColophonModels.ets 定义长卷与印章契约', () => {
  const modelPath = path.join(root, 'entry/src/main/ets/models/ColophonModels.ets');
  assert(fs.existsSync(modelPath), 'ColophonModels.ets 必须存在');
  const content = fs.readFileSync(modelPath, 'utf8');
  assert(content.includes('enum AppraisalSealType') || content.includes('type AppraisalSealType'), '必须包含 AppraisalSealType');
  assert(content.includes('TraditionalColorItem'), '必须包含 TraditionalColorItem 接口');
  assert(content.includes('ColophonConfig'), '必须包含 ColophonConfig 接口');
});

// 2. TraditionalColorCatalog.ets 校验
test('TraditionalColorCatalog.ets 包含丰富国色词库与就近匹配算法', () => {
  const catalogPath = path.join(root, 'entry/src/main/ets/models/TraditionalColorCatalog.ets');
  assert(fs.existsSync(catalogPath), 'TraditionalColorCatalog.ets 必须存在');
  const content = fs.readFileSync(catalogPath, 'utf8');
  assert(content.includes('TRADITIONAL_COLORS'), '必须包含 TRADITIONAL_COLORS 色彩常数库');
  assert(content.includes('findClosestTraditionalColor'), '必须导出 findClosestTraditionalColor 方法');
  assert(content.includes('缃色') || content.includes('苍绿') || content.includes('朱砂'), '色谱库必须包含经典国风雅色');
});

// 3. ColorPaletteExtractor.ets 校验
test('ColorPaletteExtractor.ets 具备色谱聚类与提取能力', () => {
  const extractorPath = path.join(root, 'entry/src/main/ets/services/ColorPaletteExtractor.ets');
  assert(fs.existsSync(extractorPath), 'ColorPaletteExtractor.ets 必须存在');
  const content = fs.readFileSync(extractorPath, 'utf8');
  assert(content.includes('ColorPaletteExtractor'), '必须导出 ColorPaletteExtractor 类或工具');
  assert(content.includes('extractPalette'), '必须包含 extractPalette 相关提取逻辑');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
