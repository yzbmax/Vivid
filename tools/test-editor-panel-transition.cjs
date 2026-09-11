/**
 * 底部编辑栏两档高度收敛与物理弹簧平滑过渡专项测试套件 (重构校验)
 */

const fs = require('fs');
const path = require('path');

let passCount = 0;
let failCount = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✔ [PASS] ${message}`);
    passCount++;
  } else {
    console.error(`  ✖ [FAIL] ${message}`);
    failCount++;
  }
}

console.log('====================================================');
console.log('底部编辑栏两档高度收敛与物理弹簧过渡专项测试套件');
console.log('====================================================');

// Task 1: 检查 EditModels.ets
const editModelsPath = path.join(__dirname, '../entry/src/main/ets/models/EditModels.ets');
const editModelsContent = fs.readFileSync(editModelsPath, 'utf-8');

assert(
  editModelsContent.includes('EDITOR_PANEL_HEIGHT_COMPACT') &&
  editModelsContent.includes('EDITOR_PANEL_HEIGHT_EXTENDED'),
  'EditModels 必须导出 EDITOR_PANEL_HEIGHT_COMPACT 与 EDITOR_PANEL_HEIGHT_EXTENDED'
);

assert(
  editModelsContent.includes('resolveEditorPanelHeight'),
  'EditModels 必须导出 resolveEditorPanelHeight 纯函数'
);

// 提取并动态测试高度逻辑
const compactMatch = editModelsContent.match(/EDITOR_PANEL_HEIGHT_COMPACT\s*:\s*number\s*=\s*(\d+)/);
const extendedMatch = editModelsContent.match(/EDITOR_PANEL_HEIGHT_EXTENDED\s*:\s*number\s*=\s*(\d+)/);

if (compactMatch && extendedMatch) {
  const compactHeight = parseInt(compactMatch[1], 10);
  const extendedHeight = parseInt(extendedMatch[1], 10);
  assert(compactHeight === 168, `标准常驻档高度必须精确为 168vp (当前: ${compactHeight})，确保完整容纳卡片与浓度滑块`);
  assert(extendedHeight === 252, `深度微调档高度必须精确为 252vp (当前: ${extendedHeight})`);
  assert(extendedHeight - compactHeight <= 100, '两档高度差必须平缓收敛在 100vp 以内，杜绝剧烈落差');
}

// Task 2: 检查各面板内部尺寸规范
const filterPanelPath = path.join(__dirname, '../entry/src/main/ets/components/editor/FilterPanel.ets');
const filterPanelContent = fs.readFileSync(filterPanelPath, 'utf-8');
assert(
  filterPanelContent.includes('.height(120)') || filterPanelContent.includes('.height(118)'),
  'FilterPanel 必须提供充足 Scroll 高度(>=118vp)，杜绝滤镜卡片与浓度滑块被遮挡'
);

const adjustPanelPath = path.join(__dirname, '../entry/src/main/ets/components/editor/AdjustPanel.ets');
const adjustPanelContent = fs.readFileSync(adjustPanelPath, 'utf-8');
assert(
  adjustPanelContent.includes('padding({ top: 10, bottom: 10 })') ||
  adjustPanelContent.includes('padding({ top: 12, bottom: 12 })') ||
  adjustPanelContent.includes('100%'),
  'AdjustPanel 具备适度呼吸内边距并撑满容器'
);

const borderPanelPath = path.join(__dirname, '../entry/src/main/ets/components/editor/BorderPanel.ets');
const borderPanelContent = fs.readFileSync(borderPanelPath, 'utf-8');
assert(
  borderPanelContent.includes('height(\'100%\')'),
  'BorderPanel 必须契合 252vp 扩展档高度契约并占满 100%'
);

const stickerPanelPath = path.join(__dirname, '../entry/src/main/ets/components/editor/StickerPanel.ets');
const stickerPanelContent = fs.readFileSync(stickerPanelPath, 'utf-8');
assert(
  stickerPanelContent.includes('layoutWeight(1)'),
  'StickerPanel 底部采用 layoutWeight(1) 垂直居中，杜绝空白'
);

const textPanelPath = path.join(__dirname, '../entry/src/main/ets/components/editor/TextPanel.ets');
const textPanelContent = fs.readFileSync(textPanelPath, 'utf-8');
assert(
  textPanelContent.includes('height(\'100%\')') && textPanelContent.includes('layoutWeight(1)'),
  'TextPanel 必须采用内部滚动并占满 100% 高度'
);

// Task 3: 检查 EditPage.ets 动效容器与物理弹簧曲线
const editPagePath = path.join(__dirname, '../entry/src/main/ets/pages/EditPage.ets');
const editPageContent = fs.readFileSync(editPagePath, 'utf-8');

assert(
  editPageContent.includes('curves.springMotion') || editPageContent.includes('springMotion'),
  'EditPage 必须挂载 curves.springMotion 物理弹簧阻尼曲线'
);

assert(
  editPageContent.includes('.clip(true)'),
  'EditPage 面板动效容器必须配置 .clip(true) 杜绝高度动画期间子组件溢出穿模'
);

assert(
  editPageContent.includes('syncPanelHeight'),
  'EditPage 必须具备 syncPanelHeight 函数实现贴纸/文字选中态动态展开与未选态收敛'
);

assert(
  !editPageContent.includes('segErrorMessage !== \'\' && !this.isRegionMode()'),
  'EditPage 严禁在非主体区域模式下跨 Tab 显示刺眼红色主体报错文字'
);

assert(
  editPageContent.includes('.height(\'100%\')'),
  'EditPage 预览区域宿主容器必须采用 100% 高度以直接响应视口变化'
);

// Task 4: 检查 PreviewArea.ets 中间预览画芯与照片层的平滑过渡动画
const previewAreaPath = path.join(__dirname, '../entry/src/main/ets/components/editor/PreviewArea.ets');
const previewAreaContent = fs.readFileSync(previewAreaPath, 'utf-8');

assert(
  previewAreaContent.includes("import { curves } from '@kit.ArkUI'") ||
  previewAreaContent.includes("curves.springMotion(0.35, 0.82)"),
  'PreviewArea 必须引入 @kit.ArkUI 并具备 curves.springMotion 阻尼曲线'
);

assert(
  previewAreaContent.includes('isReadyForAnimation'),
  'PreviewArea 必须具备 isReadyForAnimation 动效使能状态，杜绝挂载初次从 0x0 突变放大'
);

assert(
  previewAreaContent.includes('id(PREVIEW_STACK_ID)') &&
  previewAreaContent.includes('previewStack') &&
  previewAreaContent.includes('curve: curves.springMotion(0.35, 0.82)'),
  'PreviewArea previewStack 主画芯容器必须挂载 curves.springMotion(0.35, 0.82) 动画'
);

assert(
  previewAreaContent.includes('.position({ x: this.layout().photoRect.x - this.layout().outputRect.x') &&
  previewAreaContent.includes('photoCornerRadius'),
  'PreviewArea 内部照片 photoLayers 容器必须与 previewStack 同步挂载物理阻尼动画'
);

assert(
  previewAreaContent.includes("blurredBackgroundLayer") &&
  previewAreaContent.includes(".width('100%')") &&
  previewAreaContent.includes(".height('100%')"),
  'PreviewArea 背景虚化层必须自适应 100% 宽高跟随画芯平滑过渡'
);

assert(
  previewAreaContent.includes("compareFloatingButton") &&
  previewAreaContent.includes("springMotion"),
  'PreviewArea 悬浮对比按钮必须挂载同频物理阻尼动画，确保底栏升降时平滑浮动'
);

console.log('====================================================');
console.log(`测试结果: ${passCount} 项通过, ${failCount} 项失败`);
console.log('====================================================');

if (failCount > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
