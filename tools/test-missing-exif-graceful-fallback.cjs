const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const exifReaderPath = path.join(root, 'entry/src/main/ets/services/ExifReaderService.ets');
const editPagePath = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
const borderPainterPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');

console.log('====================================================');
console.log('无 EXIF 数据留白即美（方案一）与友好说明提示专项测试');
console.log('====================================================');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✔ [PASS] ${name}`);
    passed++;
  } catch (err) {
    console.error(`  ✘ [FAIL] ${name}: ${err.message}`);
    failed++;
  }
}

const exifReaderContent = fs.readFileSync(exifReaderPath, 'utf8');
const editPageContent = fs.readFileSync(editPagePath, 'utf8');
const borderPainterContent = fs.readFileSync(borderPainterPath, 'utf8');

// 1. ExifReaderService 文件修改时间真实回退测试
test('ExifReaderService 当缺少 EXIF 拍摄时间时，智能回退至真实文件修改时间', () => {
  assert(
    exifReaderContent.includes('stat.mtime'),
    'ExifReaderService 必须探测文件的实际 stat.mtime 作为真实备用时间'
  );
  assert(
    !exifReaderContent.includes("result.timeText = '2026.09.03 16:30'"),
    '严禁在 EXIF 缺失时硬编码写死假时间'
  );
});

// 2. EditPage 无 EXIF 留白策略（方案一）
test('EditPage 在无 EXIF 数据时，清空硬编码假机型、假Logo与假参数，优雅留白', () => {
  assert(
    editPageContent.includes("current.deviceModel = ''") &&
    editPageContent.includes("current.showDevice = false") &&
    editPageContent.includes("current.logo = 'none'") &&
    editPageContent.includes("current.showLogo = false") &&
    editPageContent.includes("current.paramsText = ''") &&
    editPageContent.includes("current.showParams = false"),
    'EditPage 必须在无 EXIF 时清空机型、Logo、参数并关闭开关'
  );
});

// 3. 友好提示弹窗（说明网络下载/传输导致参数丢失）
test('EditPage 包含用户友好说明提示（明确告知网络下载或传输压缩原因）', () => {
  assert(
    editPageContent.includes('网络下载') || editPageContent.includes('社交软件'),
    '提示文案必须向用户解释为什么没有参数（如网络下载、社交软件压缩）'
  );
  assert(
    editPageContent.includes('this.toast('),
    '必须通过 toast 弹出轻量友好提示'
  );
});

// 4. BorderPainter 5 大模版参数非空保护（杜绝无参数时画出硬编码 70mm f/2.8）
test('BorderPainter 核心水印模版在 paramsText 为空时严禁渲染默认数字', () => {
  const checkSnippets = [
    'if (wm.showParams && wm.paramsText && wm.paramsText.trim().length > 0)',
  ];
  let occurrences = 0;
  for (const snippet of checkSnippets) {
    occurrences += borderPainterContent.split(snippet).length - 1;
  }
  assert(
    occurrences >= 5,
    `BorderPainter 必须在各模版中守卫 paramsText 非空，当前匹配到 ${occurrences} 处（期望 >= 5 处）`
  );
});

console.log('====================================================');
console.log(`专项测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
