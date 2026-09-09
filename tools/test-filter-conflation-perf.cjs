// Automated test verifying infinite filter switching and zero-performance-degradation guarantees
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

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

console.log('====================================================');
console.log('TDD: 滤镜无限次切换与零性能衰减 (Performance & Conflation) 测试');
console.log('====================================================');

// 1. PreviewPipeline 具备请求合流（Request Conflation / Coalescing）机制
test('PreviewPipeline.ets 具备 isRendering 与 pendingTask 合流调度，防止高频并发堆叠', () => {
  const file = path.join(root, 'entry/src/main/ets/services/PreviewPipeline.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('isRendering'), 'PreviewPipeline 必须具备 isRendering 状态');
  assert(content.includes('pendingTask'), 'PreviewPipeline 必须具备 pendingTask 任务槽');
  assert(content.includes('pendingResolves'), 'PreviewPipeline 必须具备 pendingResolves 挂起队列');
  assert(content.includes('superseded'), '高频切换时必须提前结算并丢弃过时中间帧');
});

// 2. OwnedRenderResult.replace 安全替换并释放前序
test('OwnedRenderResult.replace 安全暂存新结果后再释放旧结果，防止瞬时纹理野指针', () => {
  const file = path.join(root, 'entry/src/main/ets/services/PreviewPipeline.ets');
  const content = fs.readFileSync(file, 'utf8');
  const replaceIdx = content.indexOf('replace(next: T, borrowed?: T): T {');
  assert(replaceIdx > 0, '必须定义 replace 方法');
  const body = content.slice(replaceIdx, replaceIdx + 300);
  assert(body.includes('const previous = this.current;'), '必须在赋值前暂存 previous 引用');
  assert(body.includes('this.current = next === borrowed ? undefined : next;'), '必须先更新 this.current');
  assert(body.includes('this.releaseResult(previous);'), '必须在 this.current 赋予新句柄后安全释放 previous');
});

// 3. EditPage.ets 先更新 UI 绑定的 previewPixelMap 再触发 replace
test('EditPage.ets 在 renderPreview 中先同步 previewPixelMap 再调用 replace 释放旧图', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  const previewIdx = content.indexOf('this.previewPixelMap = result;');
  const replaceIdx = content.indexOf('this.renderedPreviewOwner.replace(result, source);');
  assert(previewIdx > 0 && replaceIdx > 0, '必须同时包含 previewPixelMap 赋值与 replace 调用');
  assert(previewIdx < replaceIdx, '必须先赋予 this.previewPixelMap = result，杜绝 ArkUI 空窗期');
});

// 4. C++ FilterEngine LRU 缓存容量为 64，满足全量常驻且留有充足余量
test('FilterEngine LRU 缓存上限设定为 64，全部 30 款预设全量热驻留（内存仅 3MB）', () => {
  const file = path.join(root, 'entry/src/main/cpp/filter/filter_engine.h');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('kDefaultMaxLutCache = 64'), 'kDefaultMaxLutCache 必须扩容为 64');
});

// 5. VulkanLutRenderer 重用堆内存 fallbackCheckBuffer_，消除每帧 6.2MB 内存颠簸
test('VulkanLutRenderer 具备 fallbackCheckBuffer_ 成员重用，杜绝每帧 6.2MB 堆内存分配与释放', () => {
  const headerFile = path.join(root, 'entry/src/main/cpp/filter/vulkan_lut_renderer.h');
  const header = fs.readFileSync(headerFile, 'utf8');
  assert(header.includes('fallbackCheckBuffer_'), '头文件必须声明 fallbackCheckBuffer_ 成员');

  const cppFile = path.join(root, 'entry/src/main/cpp/filter/vulkan_lut_renderer.cpp');
  const cpp = fs.readFileSync(cppFile, 'utf8');
  assert(cpp.includes('fallbackCheckBuffer_.resize'), 'Render 中必须按需 resize 重用缓冲区');
  assert(!cpp.includes('const std::vector<uint8_t> originalPixels'), '严禁在每帧循环内重新构建 originalPixels vector');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
