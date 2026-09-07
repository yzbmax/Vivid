const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 3: 题跋弹窗与 SaveButton 导出交互测试');
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

// 1. icon_scroll.svg 图标存在
test('icon_scroll.svg 题跋长卷图标存在', () => {
  const iconPath = path.join(root, 'entry/src/main/resources/base/media/icon_scroll.svg');
  assert(fs.existsSync(iconPath), 'icon_scroll.svg 必须存在');
});

// 2. ColophonExportDialog.ets 存在且使用 SaveButton
test('ColophonExportDialog.ets 存在且集成 SaveButton 安全控件', () => {
  const dialogPath = path.join(root, 'entry/src/main/ets/components/common/ColophonExportDialog.ets');
  assert(fs.existsSync(dialogPath), 'ColophonExportDialog.ets 必须存在');
  const content = fs.readFileSync(dialogPath, 'utf8');
  assert(content.includes('struct ColophonExportDialog'), '必须导出 ColophonExportDialog 组件');
  assert(content.includes('SaveButton'), '必须包含 SaveButton 安全控件');
  assert(content.includes('PhotoExportService'), '必须调用 PhotoExportService');
});

// 3. WorkDetailPage.ets 接入题跋弹窗与操作入口
test('WorkDetailPage.ets 接入长卷题跋入口与弹窗', () => {
  const pagePath = path.join(root, 'entry/src/main/ets/pages/WorkDetailPage.ets');
  const content = fs.readFileSync(pagePath, 'utf8');
  assert(content.includes('ColophonExportDialog'), 'WorkDetailPage 必须引入 ColophonExportDialog');
  assert(content.includes('icon_scroll'), 'WorkDetailPage 必须包含题跋长卷入口图标');
  assert(content.includes('showColophonDialog'), 'WorkDetailPage 必须维护 showColophonDialog 状态');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
