const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 4: 单步撤销 / 重做 (Undo / Redo) 历史栈测试');
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

// 1. EditHistoryManager.ets 存在与契约
test('EditHistoryManager.ets 存在且具备核心历史栈 API', () => {
  const managerPath = path.join(root, 'entry/src/main/ets/models/EditHistoryManager.ets');
  assert(fs.existsSync(managerPath), 'EditHistoryManager.ets 必须存在');
  const content = fs.readFileSync(managerPath, 'utf8');
  assert(content.includes('class EditHistoryManager'), '必须导出 EditHistoryManager 类');
  assert(content.includes('pushSnapshot'), '必须包含 pushSnapshot 方法');
  assert(content.includes('undo'), '必须包含 undo 方法');
  assert(content.includes('redo'), '必须包含 redo 方法');
  assert(content.includes('canUndo'), '必须包含 canUndo 方法');
  assert(content.includes('canRedo'), '必须包含 canRedo 方法');
});

// 2. EditPage.ets 接入撤销与重做
test('EditPage.ets 接入 EditHistoryManager 与撤销重做交互', () => {
  const editPagePath = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(editPagePath, 'utf8');
  assert(content.includes('EditHistoryManager'), 'EditPage 必须引用 EditHistoryManager');
  assert(content.includes('undo()') || content.includes('performUndo()'), 'EditPage 必须提供 undo 交互');
  assert(content.includes('redo()') || content.includes('performRedo()'), 'EditPage 必须提供 redo 交互');
  assert(content.includes('canUndo'), 'EditPage 必须根据 canUndo 状态禁用/启用撤销');
  assert(content.includes('canRedo'), 'EditPage 必须根据 canRedo 状态禁用/启用重做');
});

// 3. 图标资源存在
test('icon_undo.svg 与 icon_redo.svg 图标资源存在', () => {
  const undoSvg = path.join(root, 'entry/src/main/resources/base/media/icon_undo.svg');
  const redoSvg = path.join(root, 'entry/src/main/resources/base/media/icon_redo.svg');
  assert(fs.existsSync(undoSvg), 'icon_undo.svg 必须存在');
  assert(fs.existsSync(redoSvg), 'icon_redo.svg 必须存在');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
