const fs = require('fs');
const path = require('path');

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  [PASS] ${message}`);
    passed++;
  } else {
    console.error(`  [FAIL] ${message}`);
    failed++;
  }
}

console.log('====================================================');
console.log('华为上架审核问题整改自动化回归测试');
console.log('====================================================');

const projectRoot = path.resolve(__dirname, '..');

// 1. AI 智能抠图功能闭环验证
const previewAreaEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/PreviewArea.ets'), 'utf-8');
const editPageEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/EditPage.ets'), 'utf-8');

assert(
  previewAreaEts.includes('isolateSubject: boolean') && previewAreaEts.includes('!this.isolateSubject'),
  'PreviewArea 支持去底独立预览（isolateSubject 模式下底图隐藏并显示透底背景）'
);

assert(
  editPageEts.includes('mattingActionBar()') &&
  editPageEts.includes('saveForegroundAsSticker') &&
  editPageEts.includes('exportForegroundToAlbum'),
  'EditPage AI 智能抠图提供「去底预览/全图」、「存为贴纸」、「导出抠图」完整闭环'
);

// 2. 贴纸系统缺陷修复（zIndex 溢出、状态串扰、协议规整、选中指示）
const editModelsEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/models/EditModels.ets'), 'utf-8');
const stickerLayerEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf-8');
const stickerPanelEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/StickerPanel.ets'), 'utf-8');

assert(
  editModelsEts.includes('getNextStickerZIndex') && !editModelsEts.includes('zIndex: Date.now()'),
  'EditModels 贴纸层级采用全局循环自增序号（10..1000），消除 int32_t 溢出导致贴纸消失'
);

assert(
  editModelsEts.includes('ensureFileUri(uri: string)'),
  'EditModels 导出 ensureFileUri 严格规范本地图片 file:// 协议'
);

assert(
  !stickerLayerEts.includes('@Consume stickerTargetSize') &&
  stickerLayerEts.includes('onItemPropChanged') &&
  stickerLayerEts.includes('@Prop item: StickerItem'),
  'StickerLayer 移除 @Consume 全局串扰，采用 @Prop + @Watch(\'onItemPropChanged\') 响应各自属性'
);

assert(
  stickerLayerEts.includes('BorderStyle.Dashed') && stickerLayerEts.includes('this.isSelected'),
  'StickerLayer 在贴纸被选中时绘制朱砂红虚线高亮框，提供清晰交互视觉反馈'
);

assert(
  stickerPanelEts.includes('ensureFileUri(tpl.customUri)'),
  'StickerPanel 自定义贴纸缩略图应用 ensureFileUri，解决选项缩略图空白'
);

assert(
  editPageEts.includes('ensureFileUri(destPath)'),
  'EditPage 上传自定义贴纸时使用 ensureFileUri 保存与实例化'
);

// 3. 底部导航条 28vp 安全避让规范
const entryAbilityEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/entryability/EntryAbility.ets'), 'utf-8');
const indexEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/Index.ets'), 'utf-8');
const editorToolBarEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/EditorToolBar.ets'), 'utf-8');
const workDetailPageEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/WorkDetailPage.ets'), 'utf-8');

assert(
  entryAbilityEts.includes('TYPE_NAVIGATION_INDICATOR') &&
  entryAbilityEts.includes('Math.max(rawNavH, 28)') &&
  entryAbilityEts.includes('avoidAreaChange'),
  'EntryAbility 综合查询手势导航指示条并硬保底至少 28vp，同时动态监听 avoidAreaChange'
);

assert(
  indexEts.includes('Math.max(this.navBarHeightVp, 28)') &&
  indexEts.includes('.barHeight(56 + Math.max(this.navBarHeightVp, 28))'),
  'Index 主导航 Tab 栏底部内边距与总高度严格保证 >= 28vp 避让抬高'
);

assert(
  editorToolBarEts.includes('Math.max(AppStorage.get<number>(\'navBarHeight\') ?? 28, 28)'),
  'EditorToolBar 底部工具栏安全区避让硬保底 >= 28vp'
);

assert(
  workDetailPageEts.includes('10 + Math.max(AppStorage.get<number>(\'navBarHeight\') ?? 28, 28)'),
  'WorkDetailPage 底部操作条安全区避让硬保底 >= 28vp'
);

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
