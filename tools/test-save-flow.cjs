const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('SaveButton 免弹窗静默导出架构与安全合规校验');
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

// 1. EditPage.ets 校验
const editPagePath = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
const editPageContent = fs.readFileSync(editPagePath, 'utf8');

test('EditPage 顶栏使用 SaveButton 替代原生 Text(\'导出\')', () => {
  assert(editPageContent.includes('SaveButton'), 'EditPage 应包含 SaveButton 组件');
  assert(!editPageContent.includes("Text('导出')"), "EditPage 顶栏不应再使用原始 Text('导出')");
  assert(editPageContent.includes('SaveDescription.SAVE'), 'EditPage 顶栏应使用 SaveDescription.SAVE');
});

test('EditPage 的 SaveButton 不直接调用非法方法 (如 layoutWeight, shadow)', () => {
  const saveBtnMatch = editPageContent.match(/SaveButton\(\{[\s\S]*?\}\)([\s\S]*?)\.onClick/);
  assert(saveBtnMatch, '找不到 EditPage 中的 SaveButton 链式调用');
  const chain = saveBtnMatch[1];
  assert(!chain.includes('.layoutWeight('), 'SaveButton 原生不支持 layoutWeight');
  assert(!chain.includes('.shadow('), 'SaveButton 原生不支持 shadow');
});

test('EditPage executeSave 支持 SaveButton 免弹窗直接保存', () => {
  assert(editPageContent.includes('PhotoExportService.saveViaSaveButton'), 'executeSave 应支持调用 saveViaSaveButton');
});

// 2. ExportSettingsDialog.ets 校验
const dialogPath = path.join(root, 'entry/src/main/ets/components/common/ExportSettingsDialog.ets');
const dialogContent = fs.readFileSync(dialogPath, 'utf8');

test('ExportSettingsDialog 底部操作按钮使用 SaveButton', () => {
  assert(dialogContent.includes('SaveButton'), 'ExportSettingsDialog 应包含 SaveButton 组件');
  assert(!dialogContent.includes("Button('确认落印导出')"), "不应再使用原始 Button('确认落印导出')");
  assert(dialogContent.includes('SaveDescription.EXPORT_TO_GALLERY') || dialogContent.includes('SaveDescription.SAVE_TO_GALLERY') || dialogContent.includes('SaveDescription.SAVE_IMAGE'), '应使用合规的 SaveDescription 枚举');
});

test('ExportSettingsDialog 回调支持透传 useSaveButton 授权状态', () => {
  assert(dialogContent.includes('useSaveButton'), 'ExportSettingsDialog 应包含 useSaveButton 参数');
});

// 3. PhotoExportService.ets 校验
const servicePath = path.join(root, 'entry/src/main/ets/services/PhotoExportService.ets');
const serviceContent = fs.readFileSync(servicePath, 'utf8');

test('PhotoExportService.saveViaSaveButton 存在且具备容错能力', () => {
  assert(serviceContent.includes('static async saveViaSaveButton'), 'PhotoExportService 应导出 saveViaSaveButton');
  assert(serviceContent.includes('cleanUpOnError'), 'saveViaSaveButton 应支持 cleanUpOnError 控制降级清理');
});

// 4. 引用完整性校验
test('所有使用 ExportResult 的页面必须正确 import ExportResult', () => {
  const pages = [
    'entry/src/main/ets/pages/EditPage.ets',
    'entry/src/main/ets/pages/WorkDetailPage.ets',
    'entry/src/main/ets/pages/WorksPage.ets'
  ];
  for (const p of pages) {
    const content = fs.readFileSync(path.join(root, p), 'utf8');
    assert(/import\s*\{[^}]*ExportResult[^}]*\}\s*from/.test(content), `${p} 必须正确 import ExportResult`);
  }
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
