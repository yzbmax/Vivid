const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('TDD: 分辨率解析与作品尺寸完整性测试');
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

// 1. WorkImageUtils.ets: 必须导出 probeImageDimensions 与 ImageDimension 接口
test('WorkImageUtils 导出 probeImageDimensions 工具函数', () => {
  const file = path.join(root, 'entry/src/main/ets/utils/WorkImageUtils.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('export async function probeImageDimensions'), '必须导出 probeImageDimensions 函数');
  assert(content.includes('export interface ImageDimension'), '必须声明并导出 ImageDimension 类型');
});

// 2. PaperFrame.ets: 必须具备尺寸感知与 onImageSize 回调
test('PaperFrame 支持 onImageSize 回调并在 Image 上挂载 onComplete', () => {
  const file = path.join(root, 'entry/src/main/ets/components/common/PaperFrame.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('onImageSize?: (width: number, height: number) => void'), 'PaperFrame 必须包含 onImageSize 属性');
  assert(content.includes('.onComplete((event) =>'), 'PaperFrame 的 Image 组件必须挂载 onComplete 回调');
  assert(content.includes('this.onImageSize(event.width, event.height)'), 'onComplete 中必须调用 this.onImageSize');
});

// 3. WorkDetailPage.ets: 接入尺寸主动探测与 PaperFrame 回调自动修复老数据
test('WorkDetailPage 具备尺寸自动探测与修复机制', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/WorkDetailPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('probeImageDimensions'), 'WorkDetailPage 必须调用 probeImageDimensions 兜底');
  assert(content.includes('ensureWorkDimensions'), 'WorkDetailPage 必须包含 ensureWorkDimensions 方法');
  assert(content.includes('applyResolvedDimensions'), 'WorkDetailPage 必须包含 applyResolvedDimensions 方法');
  assert(content.includes('onImageSize: (w: number, h: number) =>'), 'WorkDetailPage 必须向 PaperFrame 传入 onImageSize');
});

// 4. EditPage.ets: loadPreviewSource 必须主动初始化 imageWidth/imageHeight
test('EditPage loadPreviewSource 初始化 imageWidth 与 imageHeight', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  const loadSourceIdx = content.indexOf('loadPreviewSource(): Promise<void>');
  assert(loadSourceIdx > 0, '必须找到 loadPreviewSource 函数');
  const loadSourceChunk = content.slice(loadSourceIdx, loadSourceIdx + 2000);
  assert(loadSourceChunk.includes('this.imageWidth ='), 'loadPreviewSource 必须给 this.imageWidth 赋值');
  assert(loadSourceChunk.includes('this.imageHeight ='), 'loadPreviewSource 必须给 this.imageHeight 赋值');
  assert(loadSourceChunk.includes('probeImageDimensions'), 'loadPreviewSource 必须主动探测原图高精尺寸');
});

// 5. EditPage.ets: saveDraft 必须保存 width 和 height
test('EditPage saveDraft 正确持久化 record.width 与 record.height', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  const draftIdx = content.indexOf('saveDraft(): Promise<void>');
  assert(draftIdx > 0, '必须找到 saveDraft 函数');
  const draftChunk = content.slice(draftIdx, draftIdx + 3500);
  assert(draftChunk.includes('record.width = this.imageWidth'), 'saveDraft 必须为 record.width 赋值');
  assert(draftChunk.includes('record.height = this.imageHeight'), 'saveDraft 必须为 record.height 赋值');
});

// 6. PreviewArea.ets: 所有图片图层均挂载 onComplete
test('PreviewArea 各 Image 分支挂载 onComplete 回调', () => {
  const file = path.join(root, 'entry/src/main/ets/components/editor/PreviewArea.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('Image(this.previewPixelMap)'), '必须有 previewPixelMap 渲染');
  const previewPixelMapMatches = content.match(/Image\(this\.previewPixelMap\)[\s\S]*?\.onComplete\(/g);
  assert(previewPixelMapMatches && previewPixelMapMatches.length >= 2, '所有 previewPixelMap 渲染分支都必须有 onComplete');
});

// 7. WorkSaveService.ets: 保存作品时补齐分辨率并优化批注
test('WorkSaveService 创建与更新作品时解析图片尺寸', () => {
  const file = path.join(root, 'entry/src/main/ets/services/WorkSaveService.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('probeImageDimensions'), 'WorkSaveService 必须引入并调用 probeImageDimensions');
  assert(content.includes('newWork.width = dims.width'), '新建作品时必须设置 width');
  assert(content.includes('newWork.height = dims.height'), '新建作品时必须设置 height');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
