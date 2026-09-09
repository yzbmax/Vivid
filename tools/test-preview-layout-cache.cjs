const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('TDD: PreviewArea 渲染布局缓存机制与零字符串分配校验');
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

const previewAreaPath = path.join(root, 'entry/src/main/ets/components/editor/PreviewArea.ets');
const previewAreaContent = fs.readFileSync(previewAreaPath, 'utf8');

// 1. 验证移除了动态模板字符串 key 拼接
test('PreviewArea.ets 不再使用模板字符串动态构建 lastLayoutKey', () => {
  assert(!previewAreaContent.includes('const key = `${this.containerW}'), 'layout() 中不应再出现动态 template string key 拼接');
  assert(!previewAreaContent.includes('this.lastLayoutKey === key'), '不应再使用字符串全量对比作为缓存凭据');
});

// 2. 验证引入了数值与结构化快速比较缓存字段
test('PreviewArea.ets 包含基本类型缓存字段进行精确脏值检测', () => {
  assert(previewAreaContent.includes('cachedContainerW'), '必须包含 cachedContainerW 字段');
  assert(previewAreaContent.includes('cachedContainerH'), '必须包含 cachedContainerH 字段');
  assert(previewAreaContent.includes('cachedPhotoW'), '必须包含 cachedPhotoW 字段');
  assert(previewAreaContent.includes('cachedPhotoH'), '必须包含 cachedPhotoH 字段');
  assert(previewAreaContent.includes('cachedBorderTemplateId'), '必须包含 cachedBorderTemplateId 字段');
  assert(previewAreaContent.includes('cachedBorderWidthRatio'), '必须包含 cachedBorderWidthRatio 字段');
});

// 3. 验证 layout() 内部采用短路求值直返缓存
test('PreviewArea.ets layout() 实现精确脏值判断与零字符串分配返回', () => {
  const layoutIdx = previewAreaContent.indexOf('private layout(): EditorPreviewLayout');
  assert(layoutIdx > 0, '必须定义 private layout(): EditorPreviewLayout');
  const layoutBody = previewAreaContent.slice(layoutIdx, layoutIdx + 1200);
  assert(layoutBody.includes('this.cachedContainerW === this.containerW'), '必须比对 containerW');
  assert(layoutBody.includes('this.cachedContainerH === this.containerH'), '必须比对 containerH');
  assert(layoutBody.includes('return this.cachedLayout'), '必须直接返回 cachedLayout');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
