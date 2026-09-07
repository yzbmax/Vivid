const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 2: 全局长按对比浮标功能测试');
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

const previewPath = path.join(root, 'entry/src/main/ets/components/editor/PreviewArea.ets');
const previewContent = fs.readFileSync(previewPath, 'utf8');

test('PreviewArea 移除画布全局侵入式 onTouch 避免普通触摸误触闪烁', () => {
  // 不应该在外层容器全局绑定 onTouch(event.type === TouchType.Down => onCompareChange(true))
  assert(!/Stack\([^)]*\)[\s\S]*?\.onTouch\(\(event:\s*TouchEvent\)\s*=>\s*\{[\s\S]*?if\s*\(this\.stickerMode[\s\S]*?onCompareChange\(true\)/.test(previewContent),
    '外层容器不应无差别截获全屏 touch 触发原图对比');
});

test('PreviewArea 提供显式的悬浮对比操作控件', () => {
  assert(previewContent.includes('compareFloatingButton') || previewContent.includes('icon_compare') || previewContent.includes('Text(\'对比\')') || previewContent.includes('Text("对比")'),
    'PreviewArea 必须包含显式的对比按钮组件');
  assert(previewContent.includes('TouchType.Down') && previewContent.includes('onCompareChange(true)'),
    '对比控件必须在 TouchType.Down 时触发 onCompareChange(true)');
  assert((previewContent.includes('TouchType.Up') || previewContent.includes('TouchType.Cancel')) && previewContent.includes('onCompareChange(false)'),
    '对比控件必须在 TouchType.Up/Cancel 时触发 onCompareChange(false)');
});

test('PreviewArea 对比态显示文人印章微章提示', () => {
  assert(previewContent.includes('isComparing'), '必须使用 isComparing 状态');
  assert(previewContent.includes('原图'), '对比态必须渲染「原图」标识');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
