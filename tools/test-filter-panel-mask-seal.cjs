const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('Task: 方案 A【印匣色签 · 文书钤印式】视觉与交互契约测试');
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

const filterPanelPath = path.join(root, 'entry/src/main/ets/components/editor/FilterPanel.ets');
assert(fs.existsSync(filterPanelPath), 'FilterPanel.ets 必须存在');
const filterPanelContent = fs.readFileSync(filterPanelPath, 'utf8');

const previewAreaPath = path.join(root, 'entry/src/main/ets/components/editor/PreviewArea.ets');
assert(fs.existsSync(previewAreaPath), 'PreviewArea.ets 必须存在');
const previewAreaContent = fs.readFileSync(previewAreaPath, 'utf8');

// 1. 缩略图全幅填充与剔除 Contain 留白
test('FilterPanel 缩略图卡片采用 ImageFit.Cover 饱满裁切，杜绝 Contain 导致的上下白边', () => {
  assert(filterPanelContent.includes('ImageFit.Cover'), 'FilterPanel 必须使用 ImageFit.Cover 进行饱满裁切');
  assert(!filterPanelContent.includes('ImageFit.Contain'), 'FilterPanel 不得使用 ImageFit.Contain 产生上下尴尬空隙');
});

// 2. 右上角微缩印章（Seal Tag）
test('FilterPanel 每张滤镜色签右上角嵌有微缩印章（首字阳文方印）', () => {
  assert(filterPanelContent.includes('charAt(0)'), '印章必须动态取滤镜预设的首字');
  assert(filterPanelContent.includes('Theme.SEAL_RED'), '印章必须使用 Theme.SEAL_RED 朱砂红');
});

// 3. 文书等宽编号标注
test('FilterPanel 具备文书典藏感的等宽编号（NO.00 ~ NO.xx）', () => {
  assert(filterPanelContent.includes('NO.') || filterPanelContent.includes('formatIndex'), '卡片必须展示等宽编号');
  assert(filterPanelContent.includes('Theme.FONT_MONO'), '编号必须采用 Theme.FONT_MONO 等宽字体');
});

// 4. 触感与按压下沉反馈（Seal Press）
test('FilterPanel 选中具备 Seal Press 触感震动与微压效果', () => {
  assert(filterPanelContent.includes('scale('), '卡片选中应具备按压下沉效果');
  assert(filterPanelContent.includes('HapticService'), '卡片点击切换应触发触感反馈');
});

// 5. 浓度滑块与数值显示
test('FilterPanel 浓度滑块具备文书标签与百分比格式', () => {
  assert(filterPanelContent.includes('浓度'), '滑块标题应为浓度');
  assert(filterPanelContent.includes('STR'), '滑块应带有 [STR] 等宽文书批注');
  assert(filterPanelContent.includes('%'), '滑块数值应带 % 百分比符号');
  assert(filterPanelContent.includes('resetStrength'), '滑块应保留双击快速复位功能');
});

// 6. 对比按钮优化至大拇指黄金触控区（右下角）
test('PreviewArea 对比浮动按钮位于右下角大拇指黄金操作区', () => {
  assert(previewAreaContent.includes("y: '100%'") || previewAreaContent.includes('y: "100%"'), '对比按钮必须定位于底侧 100% 区域');
  assert(previewAreaContent.includes("x: '100%'") || previewAreaContent.includes('x: "100%"'), '对比按钮必须定位于右侧 100% 区域');
  assert(previewAreaContent.includes('bottom:'), '对比按钮必须配置底边距避免贴底');
});

// 7. 主图画布装裱阴影
test('PreviewArea 主图画布容器配置装裱阴影以强化文稿层级', () => {
  assert(previewAreaContent.includes('shadow('), '画布容器必须配置阴影');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
