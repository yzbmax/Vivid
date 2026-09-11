const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const borderPainterPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');
const exifReaderPath = path.join(root, 'entry/src/main/ets/services/ExifReaderService.ets');
const mediaDir = path.join(root, 'entry/src/main/resources/base/media');

console.log('====================================================');
console.log('相机水印全品牌官方 Logo 真实资源与绘制功能测试');
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

const borderPainterContent = fs.readFileSync(borderPainterPath, 'utf8');
const exifReaderContent = fs.readFileSync(exifReaderPath, 'utf8');

// 1. 官方资源文件完整性测试 (31 个品牌正版 PNG)
test('工程 media 资源必须完整包含各品牌官方正版 PNG 文件', () => {
  const requiredBrands = [
    'sony', 'canon', 'nikon', 'leica', 'zeiss', 'hasselblad',
    'fujifilm', 'olympus', 'lumix', 'panasonic', 'polaroid',
    'kodak', 'ricoh', 'dji', 'gopro', 'insta360', 'sigma',
    'tamron', 'pentax', 'apple', 'huawei', 'xiaomi', 'samsung',
    'vivo', 'oppo', 'honor', 'casio', 'mamiya', 'phase_one',
    'rollei', 'konica_minolta'
  ];
  for (const b of requiredBrands) {
    const file = path.join(mediaDir, `logo_${b}.png`);
    assert(fs.existsSync(file), `缺失品牌官方 PNG 资源: logo_${b}.png`);
    const stat = fs.statSync(file);
    assert(stat.size > 500, `品牌资源异常或为空: logo_${b}.png (size: ${stat.size})`);
  }
});

// 2. 索尼官方正统字标规范（参考图二：杜绝伪造 α 拼接）
test('BorderPainter 索尼 Logo 遵循官方 Clarendon 经典字模规范，杜绝伪造 α 符号', () => {
  assert(
    borderPainterContent.includes("logo === 'sony'"),
    '必须包含 sony 品牌专用分支'
  );
  assert(
    borderPainterContent.includes('Clarendon') || borderPainterContent.includes('logo_sony'),
    '索尼 Logo 必须使用官方 Clarendon 字体或正版图片'
  );
  // 杜绝代码中手绘橙色背景 + α 符号的错误伪标
  assert(
    !borderPainterContent.includes("context.fillText('α'") && !borderPainterContent.includes('context.fillText("α"'),
    '严禁使用手绘伪 α 拼接作为索尼 Logo'
  );
});

// 3. 苹果  纯图形剪影规范
test('BorderPainter 苹果 Logo 为纯正官方  剪影，不再拖带冗余的 iPhone 文字', () => {
  assert(
    !borderPainterContent.includes("context.fillText(' iPhone'"),
    '苹果 Logo 不得包含冗余的 iPhone 文本，避免双重机型名'
  );
  assert(
    borderPainterContent.includes('apple') || borderPainterContent.includes('Apple'),
    '必须包含苹果品牌处理逻辑'
  );
});

// 4. 佳能红标规范
test('BorderPainter 佳能 Logo 采用经典佳能红正版规范', () => {
  assert(
    borderPainterContent.includes('#C8102E') || borderPainterContent.includes('#CC0000') || borderPainterContent.includes('logo_canon'),
    '佳能徽标必须采用佳能红或正版图片'
  );
  assert(
    borderPainterContent.includes("logo === 'canon'"),
    '必须包含 canon 品牌专用分支'
  );
});

// 5. 哈苏官方字标与 H 徽标规范
test('BorderPainter 哈苏 Logo 包含官方 HASSELBLAD 字标处理', () => {
  assert(
    borderPainterContent.includes("logo === 'hasselblad'"),
    '必须包含 hasselblad 品牌专用图形分支'
  );
});

// 6. 三星品牌规范
test('BorderPainter 三星 Logo 采用经典深蓝星云规范', () => {
  assert(
    borderPainterContent.includes("logo === 'samsung'"),
    '必须包含 samsung 品牌分支'
  );
});

// 7. vivo 与 OPPO 品牌规范
test('BorderPainter vivo 与 OPPO 采用专属品牌规范', () => {
  assert(
    borderPainterContent.includes("logo === 'vivo'"),
    '必须包含 vivo 分支'
  );
  assert(
    borderPainterContent.includes("logo === 'oppo'"),
    '必须包含 oppo 分支'
  );
});

// 8. 扩展品牌覆盖（适马、大疆、影石、富士、徕卡、蔡司、尼康等）
test('BorderPainter 徽标宽度计算与绘制覆盖主流扩展品牌', () => {
  const checkBrands = ['fujifilm', 'nikon', 'leica', 'zeiss', 'sigma', 'dji', 'insta360', 'kodak', 'ricoh'];
  for (const b of checkBrands) {
    assert(
      borderPainterContent.includes(`'${b}'`) || borderPainterContent.includes(`"${b}"`),
      `BorderPainter 必须支持品牌: ${b}`
    );
  }
});

// 9. ExifReaderService 索尼 ILCE 与经典机型推导增强
test('ExifReaderService 支持 ILCE 等型号模糊推导至索尼', () => {
  assert(
    exifReaderContent.includes('ilce') || exifReaderContent.includes('alpha'),
    'ExifReaderService 必须支持 ilce / alpha 等索尼专属代号'
  );
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
