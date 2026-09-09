const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");

const root = path.resolve(__dirname, "..");

console.log("====================================================");
console.log("对比键稳定性与双层瞬显机制自动化测试");
console.log("====================================================");

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

const previewPath = path.join(root, "entry/src/main/ets/components/editor/PreviewArea.ets");
const previewContent = fs.readFileSync(previewPath, "utf8");

test("PreviewArea 具备底层原图三级兜底（originalPixelMap > baseImage > resolvedImageSrc）", () => {
  assert(previewContent.includes("originalPixelMap !== undefined"), "原图层必须优先使用 originalPixelMap");
  assert(previewContent.includes("baseImage !== undefined"), "原图层必须次级兜底 baseImage");
  assert(previewContent.includes("resolvedImageSrc()"), "原图层必须三级兜底 resolvedImageSrc()");
});

test("PreviewArea 渲染层全部启用 syncLoad(true) 杜绝切图异步白屏", () => {
  const syncMatches = previewContent.match(/\.syncLoad\(true\)/g);
  assert(syncMatches && syncMatches.length >= 5, "预览区各主要图片分支必须启用 syncLoad(true)");
});

test("compareFloatingButton 配置 responseRegion 扩大触控热区", () => {
  assert(previewContent.includes(".responseRegion("), "对比按钮必须配置 responseRegion 扩大触摸热区防止微小抖动取消");
  assert(previewContent.includes("HitTestMode.Block"), "对比按钮必须配置 HitTestMode.Block 阻止底层手势抢占");
});

test("compareFloatingButton 采用 offset 规避绝对定位边界截断", () => {
  assert(previewContent.includes(".offset({ x: -16, y: -16 })"), "对比按钮必须使用 offset 代替 margin 避免绝对定位裁剪");
});

test("PreviewArea 具备 resolvedImageSrc() 规整 file:// 协议", () => {
  assert(previewContent.includes("resolvedImageSrc"), "必须提供 resolvedImageSrc 函数");
  assert(previewContent.includes("file://${this.imageSrc}"), "必须对裸沙箱路径自动补齐 file://");
});

console.log("====================================================");
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log("====================================================");

if (failed > 0) {
  process.exit(1);
}
