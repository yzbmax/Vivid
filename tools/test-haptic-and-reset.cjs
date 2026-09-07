const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task 1: 触感反馈与滑块归零优化静态及规范测试');
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

// 1. module.json5 权限声明
test('module.json5 声明 ohos.permission.VIBRATE 权限', () => {
  const modulePath = path.join(root, 'entry/src/main/module.json5');
  const content = fs.readFileSync(modulePath, 'utf8');
  assert(content.includes('ohos.permission.VIBRATE'), 'module.json5 应声明 ohos.permission.VIBRATE');
});

// 2. HapticService.ets 存在且规范封装
test('HapticService.ets 存在且导出 triggerTick 与 triggerImpact', () => {
  const servicePath = path.join(root, 'entry/src/main/ets/services/HapticService.ets');
  assert(fs.existsSync(servicePath), 'HapticService.ets 必须存在');
  const content = fs.readFileSync(servicePath, 'utf8');
  assert(content.includes('class HapticService'), '应导出 class HapticService');
  assert(content.includes('triggerTick'), '应导出 triggerTick 方法');
  assert(content.includes('triggerImpact'), '应导出 triggerImpact 方法');
  assert(content.includes('try') && content.includes('catch'), '震动逻辑必须使用 try-catch 防御');
});

// 3. AdjustPanel.ets 归零触感与双击复位
test('AdjustPanel.ets 接入 HapticService 与双击数值归零', () => {
  const panelPath = path.join(root, 'entry/src/main/ets/components/editor/AdjustPanel.ets');
  const content = fs.readFileSync(panelPath, 'utf8');
  assert(content.includes('HapticService'), 'AdjustPanel 应引入 HapticService');
  assert(content.includes('triggerTick') || content.includes('triggerImpact'), 'AdjustPanel 应调用 HapticService');
  assert(content.includes('TapGesture') || content.includes('count: 2') || content.includes('doubleClick') || content.includes('resetCurrentParam'), 'AdjustPanel 应支持双击数值快速归零');
});

// 4. FilterPanel.ets 支持双击复位
test('FilterPanel.ets 支持双击强度复位', () => {
  const panelPath = path.join(root, 'entry/src/main/ets/components/editor/FilterPanel.ets');
  const content = fs.readFileSync(panelPath, 'utf8');
  assert(content.includes('TapGesture') || content.includes('count: 2') || content.includes('resetStrength'), 'FilterPanel 应支持双击强度复位');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
