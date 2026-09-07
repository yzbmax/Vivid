const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 2: 题跋长卷离屏渲染器测试');
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

// 1. ColophonScrollRenderer.ets 存在与接口契约
test('ColophonScrollRenderer.ets 导出核心类与尺寸计算接口', () => {
  const rendererPath = path.join(root, 'entry/src/main/ets/services/ColophonScrollRenderer.ets');
  assert(fs.existsSync(rendererPath), 'ColophonScrollRenderer.ets 必须存在');
  const content = fs.readFileSync(rendererPath, 'utf8');
  assert(content.includes('class ColophonScrollRenderer'), '必须导出 ColophonScrollRenderer 类');
  assert(content.includes('calculateLayout'), '必须包含 calculateLayout 布局高度预估');
  assert(content.includes('ColophonScrollLayout'), '必须定义 ColophonScrollLayout 布局模型');
});

// 2. 传统色目与印章渲染支持
test('ColophonScrollRenderer.ets 支持色谱带与鉴藏印章绘制', () => {
  const rendererPath = path.join(root, 'entry/src/main/ets/services/ColophonScrollRenderer.ets');
  const content = fs.readFileSync(rendererPath, 'utf8');
  assert(content.includes('drawPalette') || content.includes('renderPalette'), '必须支持色谱绘制');
  assert(content.includes('drawSeal') || content.includes('renderSeal'), '必须支持印章绘制');
  assert(content.includes('SEAL_RED') || content.includes('#B23B2F'), '印章必须使用朱砂红');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
