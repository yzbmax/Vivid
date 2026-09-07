const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 3: 调色配方「复制/粘贴」流与存储测试');
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

// 1. ColorRecipe.ets 校验
test('ColorRecipe.ets 存在且定义完整配方契约', () => {
  const modelPath = path.join(root, 'entry/src/main/ets/models/ColorRecipe.ets');
  assert(fs.existsSync(modelPath), 'ColorRecipe.ets 必须存在');
  const content = fs.readFileSync(modelPath, 'utf8');
  assert(content.includes('interface ColorRecipe'), '必须导出 ColorRecipe 接口');
  assert(content.includes('adjustments'), 'ColorRecipe 必须包含 adjustments 字段');
  assert(content.includes('filterId'), 'ColorRecipe 必须包含 filterId 字段');
  assert(content.includes('filterStrength'), 'ColorRecipe 必须包含 filterStrength 字段');
});

// 2. ColorRecipeStore.ets 校验
test('ColorRecipeStore.ets 具备 copyRecipe 与 getRecipe 能力', () => {
  const storePath = path.join(root, 'entry/src/main/ets/services/ColorRecipeStore.ets');
  assert(fs.existsSync(storePath), 'ColorRecipeStore.ets 必须存在');
  const content = fs.readFileSync(storePath, 'utf8');
  assert(content.includes('class ColorRecipeStore'), '必须导出 ColorRecipeStore 类');
  assert(content.includes('copyRecipe'), '必须包含 copyRecipe 方法');
  assert(content.includes('hasRecipe'), '必须包含 hasRecipe 方法');
  assert(content.includes('getRecipe'), '必须包含 getRecipe 方法');
});

// 3. EditPage.ets 接入配方复制与粘贴
test('EditPage.ets 支持复制配方与粘贴配方操作', () => {
  const editPagePath = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(editPagePath, 'utf8');
  assert(content.includes('ColorRecipeStore'), 'EditPage 必须引用 ColorRecipeStore');
  assert(content.includes('copyRecipe') || content.includes('copyCurrentRecipe'), 'EditPage 必须支持复制配方');
  assert(content.includes('pasteRecipe') || content.includes('applyRecipe'), 'EditPage 必须支持粘贴配方');
});

// 4. WorkDetailPage.ets 接入复制配方
test('WorkDetailPage.ets 支持复制此卷配方', () => {
  const detailPagePath = path.join(root, 'entry/src/main/ets/pages/WorkDetailPage.ets');
  const content = fs.readFileSync(detailPagePath, 'utf8');
  assert(content.includes('ColorRecipeStore'), 'WorkDetailPage 必须引用 ColorRecipeStore');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
