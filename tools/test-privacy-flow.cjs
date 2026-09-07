const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('隐私合规弹窗与 Preferences 首选项持久化测试');
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

// 1. PreferencesHelper.ets 校验
test('PreferencesHelper.ets 具备自动初始化与上下文兜底', () => {
  const filePath = path.join(root, 'entry/src/main/ets/utils/PreferencesHelper.ets');
  assert(fs.existsSync(filePath), 'PreferencesHelper.ets 必须存在');
  const content = fs.readFileSync(filePath, 'utf8');
  assert(content.includes('ensureInitialized'), 'PreferencesHelper 必须包含 ensureInitialized 保证实例化');
  assert(content.includes('preferences.getPreferences'), 'PreferencesHelper 必须调用 preferences.getPreferences');
  assert(content.includes('prefInstance.flush()'), 'PreferencesHelper 必须调用 flush() 异步刷盘');
});

// 2. Index.ets 隐私弹窗与持久化校验
test('Index.ets 首次冷启动检测并持久化 privacy_agreed', () => {
  const indexPath = path.join(root, 'entry/src/main/ets/pages/Index.ets');
  assert(fs.existsSync(indexPath), 'Index.ets 必须存在');
  const content = fs.readFileSync(indexPath, 'utf8');
  assert(content.includes('checkPrivacyStatus'), 'Index.ets 必须包含 checkPrivacyStatus');
  assert(content.includes('agreePrivacy'), 'Index.ets 必须包含 agreePrivacy');
  assert(content.includes("helper.getString('privacy_agreed'"), 'Index.ets 必须从首选项读取 privacy_agreed');
  assert(content.includes("helper.putString('privacy_agreed', 'true'"), 'Index.ets 同意时必须写入 privacy_agreed');
  assert(content.includes('helper.init(ctx)'), 'Index.ets 必须传入 UIAbilityContext 初始化首选项');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
