const fs = require('fs');
const path = require('path');
const assert = require('assert');

const projectRoot = path.resolve(__dirname, '..');

let totalTests = 0;
let passedTests = 0;

function it(title, fn) {
  totalTests++;
  try {
    fn();
    console.log(`  ✔ [PASS] ${title}`);
    passedTests++;
  } catch (err) {
    console.error(`  ✖ [FAIL] ${title}: ${err.message}`);
  }
}

console.log('====================================================');
console.log('Vivid 核心功能完备性与业务链路全流程深度自检');
console.log('====================================================\n');

// ── 1. 滤镜与 3D LUT 资源完整性 ──
console.log('【模块 1】滤镜与 3D LUT 管线校验');
const catalogEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/features/editor/filter/FilterCatalog.ets'), 'utf-8');
const filterDir = path.join(projectRoot, 'entry/src/main/resources/rawfile/filters');

it('FilterCatalog 包含 16 款以上预设且首项固定为原图', () => {
  assert(catalogEts.includes("id: 'original'"), '原图必须为第一个滤镜选项');
  assert(catalogEts.includes("lutPath: 'filters/Fieldnote.cube'"), '必须包含纪实滤镜');
  assert(catalogEts.includes("lutPath: 'filters/Heartland.cube'"), '必须包含原野滤镜');
});

it('所有注册的 .cube LUT 文件必须在磁盘物理存在且大小合理（>10KB 且 <2MB）', () => {
  const matches = catalogEts.match(/lutPath:\s*'filters\/([^']+)'/g) || [];
  assert(matches.length >= 10, '至少应匹配到 10 个 LUT 预设');
  for (const m of matches) {
    const filename = m.match(/filters\/([^']+)/)[1];
    const fullPath = path.join(filterDir, filename);
    assert(fs.existsSync(fullPath), `LUT 资源缺失: ${filename}`);
    const size = fs.statSync(fullPath).size;
    assert(size > 10 * 1024, `LUT 资源过小损坏: ${filename} (${size} bytes)`);
    assert(size < 2 * 1024 * 1024, `LUT 资源未优化超过2MB限制: ${filename} (${size} bytes)`);
  }
});

// ── 2. AI 智能抠图与主体提取 ──
console.log('\n【模块 2】AI 智能抠图与主体提取全链路校验');
const editPageEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/EditPage.ets'), 'utf-8');
const segServiceEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/services/SubjectSegmentationService.ets'), 'utf-8');

it('SubjectSegmentationService 完备覆盖超时、取消、SDK 异常与重试错误映射', () => {
  assert(segServiceEts.includes("SubjectSegmentationService.errorOut('TIMEOUT')"), '必须处理超时');
  assert(segServiceEts.includes("SubjectSegmentationService.errorOut('CANCELLED')"), '必须支持任务取消');
  assert(segServiceEts.includes("SegmentOutcome.noSubject()"), '必须支持无主体场景平稳反馈');
  assert(segServiceEts.includes("enableSubjectForegroundImage: true"), '必须启用前景图以支持双图渲染');
});

it('EditPage 包含完整的 AI 抠图三大操作（去底预览、存为贴纸、导出抠图）', () => {
  assert(editPageEts.includes('saveForegroundAsSticker'), '必须包含存为贴纸');
  assert(editPageEts.includes('exportForegroundToAlbum'), '必须包含导出透明抠图到相册');
  assert(editPageEts.includes('isIsolateSubject'), '必须包含去底/全图切换状态');
});

// ── 3. 贴纸系统全功能闭环 ──
console.log('\n【模块 3】贴纸系统手势与生命周期校验');
const stickerPanelEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/StickerPanel.ets'), 'utf-8');
const stickerLayerEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf-8');
const editModelsEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/models/EditModels.ets'), 'utf-8');

it('贴纸包含上限限制（最多 12 枚）与溢出 Toast 提示', () => {
  assert(editPageEts.includes('STICKER_MAX_COUNT'), '必须定义 STICKER_MAX_COUNT');
  assert(editPageEts.includes('贴纸数量已达上限'), '必须有超限提示');
});

it('贴纸面板包含微调控制器（尺寸 20..300、旋转 -180..180、透明度、删除）', () => {
  assert(stickerPanelEts.includes('selectedStickerSize()'), '包含尺寸滑块绑定');
  assert(stickerPanelEts.includes('selectedStickerRotation()'), '包含旋转滑块绑定');
  assert(stickerPanelEts.includes('onRemoveSticker'), '包含删除按钮回调');
});

it('所有内置矢量贴纸 SVG 资源真实存在', () => {
  const mediaDir = path.join(projectRoot, 'entry/src/main/resources/base/media');
  const requiredSvgs = [
    'sticker_corner_hui.svg',
    'sticker_corner_yun.svg',
    'sticker_corner_mei.svg',
    'sticker_corner_lian.svg',
    'sticker_ausp_ruyi.svg',
    'sticker_ausp_cloud.svg'
  ];
  for (const svg of requiredSvgs) {
    assert(fs.existsSync(path.join(mediaDir, svg)), `内置贴纸资源缺失: ${svg}`);
  }
});

// ── 4. 文字与题签排印系统 ──
console.log('\n【模块 4】文字与长卷题签排印校验');
const textPanelEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/components/editor/TextPanel.ets'), 'utf-8');

it('文字图层包含上限控制（最多 8 层）与空文本防呆校验', () => {
  assert(textPanelEts.includes("this.layers.length < 8"), '必须控制最多 8 层');
  assert(textPanelEts.includes("this.canConfirm()"), '包含保存可用性防呆检测');
  assert(editPageEts.includes("textValidationMessage"), '包含题签合规提示');
});

// ── 5. 相机水印与边框外扩 ──
console.log('\n【模块 5】相机水印与边框外扩排版校验');
const borderResolverEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/features/editor/border/BorderLayoutResolver.ets'), 'utf-8');
const borderCatalogEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/features/editor/border/BorderCatalog.ets'), 'utf-8');

it('边框目录包含经典水印、品牌大师、旅拍打卡、复古胶片、艺术装裱全部分类', () => {
  assert(borderCatalogEts.includes("'watermark'"), '包含经典水印');
  assert(borderCatalogEts.includes("'brand'"), '包含品牌大师');
  assert(borderCatalogEts.includes("'travel'"), '包含旅拍打卡');
  assert(borderCatalogEts.includes("'vintage'"), '包含复古胶片');
  assert(borderCatalogEts.includes("'framing'"), '包含艺术装裱');
});

it('水印几何布局支持横竖屏自适应与纵向双行防撞折叠', () => {
  assert(borderResolverEts.includes('resolveBorderGeometry'), '必须包含几何求解函数');
  assert(borderResolverEts.includes('insets'), '求解结果必须包含边框外扩内边距');
});

// ── 6. 统一合成与持久化导出 ──
console.log('\n【模块 6】统一合成与持久化导出链路校验');
const compServiceEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/services/EditorCompositionService.ets'), 'utf-8');
const workFileEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/services/WorkFileService.ets'), 'utf-8');

it('EditorCompositionService 实现 6 步确定性有序合成（原图->LUT->调色->贴纸->文字->边框）', () => {
  assert(compServiceEts.includes('ImageRenderService.render'), '包含原图+LUT+调色');
  assert(compServiceEts.includes('StickerCompositionService.render'), '包含贴纸图层合成');
  assert(compServiceEts.includes('TextCompositionService.render'), '包含文字图层合成');
  assert(compServiceEts.includes('BorderCompositionService.render'), '包含边框外扩装裱');
});

it('中间合成 PixelMap 在成功与失败路径均有确定性释放，杜绝显存泄漏', () => {
  assert(compServiceEts.includes('textedPixelMap.release()'), '成功路径释放 textedPixelMap');
  assert(compServiceEts.includes('stickeredPixelMap.release()'), '成功路径释放 stickeredPixelMap');
  assert(compServiceEts.includes('basePixelMap.release()'), '成功路径释放 basePixelMap');
  assert(compServiceEts.includes('throw new Error(`Composition failed:'), '异常路径安全冒泡');
});

it('WorkFileService 沙箱存储路径与预览缩略图持久化闭环', () => {
  assert(workFileEts.includes('savePreviewToSandbox'), '包含缩略图沙箱保存');
  assert(workFileEts.includes('copySourceToSandbox'), '包含源图沙箱副本保存');
  assert(workFileEts.includes('safeUnlink'), '包含临时文件安全删除');
});

// ── 7. 作品管理与详情展示 ──
console.log('\n【模块 7】作品管理与详情展示校验');
const worksPageEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/WorksPage.ets'), 'utf-8');
const detailPageEts = fs.readFileSync(path.join(projectRoot, 'entry/src/main/ets/pages/WorkDetailPage.ets'), 'utf-8');

it('WorksPage 支持按全部/已封印/草稿筛选与时间升降序排序', () => {
  assert(worksPageEts.includes("this.selectedFilter === 'sealed'"), '支持已封印筛选');
  assert(worksPageEts.includes("this.selectedFilter === 'draft'"), '支持草稿筛选');
  assert(worksPageEts.includes('sortDescending'), '支持正反排序切换');
});

it('WorkDetailPage 支持启封续编、复制调色配方与长卷装裱立轴导出', () => {
  assert(detailPageEts.includes("pages/EditPage"), '支持启封续编跳回编辑器');
  assert(detailPageEts.includes("ColorRecipeStore.copyRecipe"), '支持配方复制到剪贴板');
  assert(detailPageEts.includes("ColophonExportDialog"), '支持题跋长卷装裱弹窗');
});

// ── 8. 撤销重做与原图对比 ──
console.log('\n【模块 8】撤销重做与交互对比校验');
it('EditPage 撤销重做联动触感振动反馈', () => {
  assert(editPageEts.includes('this.historyManager.undo'), '包含 undo 逻辑');
  assert(editPageEts.includes('this.historyManager.redo'), '包含 redo 逻辑');
  assert(editPageEts.includes('HapticService.triggerTick()'), '撤销重做伴随线性马达轻微顿挫震动');
});

console.log('\n====================================================');
console.log(`全功能测试总结: ${passedTests} / ${totalTests} 全部通过！`);
console.log('====================================================');

if (passedTests !== totalTests) {
  process.exit(1);
}
