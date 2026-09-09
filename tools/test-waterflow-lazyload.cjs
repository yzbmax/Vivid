const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');

console.log('====================================================');
console.log('TDD: WorkGrid 瀑布流 LazyForEach 虚拟化与 Native 滤镜 LRU 测试');
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

// 1. WorkDataSource.ets 存在且实现 IDataSource 规范
test('WorkDataSource.ets 存在且规范实现 IDataSource', () => {
  const file = path.join(root, 'entry/src/main/ets/components/works/WorkDataSource.ets');
  assert(fs.existsSync(file), 'WorkDataSource.ets 必须存在');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('implements IDataSource'), 'WorkDataSource 必须实现 IDataSource 接口');
  assert(content.includes('totalCount(): number'), '必须实现 totalCount 方法');
  assert(content.includes('getData(index: number): WorkRecord'), '必须实现 getData 方法');
  assert(content.includes('registerDataChangeListener'), '必须实现 registerDataChangeListener');
  assert(content.includes('unregisterDataChangeListener'), '必须实现 unregisterDataChangeListener');
  assert(content.includes('notifyDataReload'), '必须提供数据重载通知方法');
});

// 2. WorkGrid.ets 双列自适应高度均衡瀑布流
test('WorkGrid.ets 双列自适应高度均衡瀑布流与外层 Scroll 完美融为一体', () => {
  const file = path.join(root, 'entry/src/main/ets/components/works/WorkGrid.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('Row({ space: Theme.GUTTER })'), '必须配置双列行容器与 Theme.GUTTER 间隙');
  assert(content.includes('Column({ space: Theme.GUTTER })'), '列内部必须使用 Theme.GUTTER 间距');
  assert(content.includes('.layoutWeight(1)'), '左右两列必须均分 layoutWeight(1)');
  assert(content.includes('padding({ left: Theme.MARGIN_MOBILE, right: Theme.MARGIN_MOBILE })'), '必须配置移动端两翼边距 Theme.MARGIN_MOBILE');
  assert(content.includes('splitColumns'), '必须包含高度智能贪心分流逻辑 splitColumns');
  const cardFile = path.join(root, 'entry/src/main/ets/components/works/WorkCard.ets');
  const cardContent = fs.readFileSync(cardFile, 'utf8');
  assert(cardContent.includes('.borderRadius(Theme.RADIUS_DEFAULT)'), 'WorkCard 必须配置 Theme.RADIUS_DEFAULT 圆角');
});

// 3. FilterEngine.h / FilterEngine.cpp 具备 LRU 缓存淘汰
test('FilterEngine 具备 LRU 缓存上限与淘汰逻辑', () => {
  const headerFile = path.join(root, 'entry/src/main/cpp/filter/filter_engine.h');
  const cppFile = path.join(root, 'entry/src/main/cpp/filter/filter_engine.cpp');
  const header = fs.readFileSync(headerFile, 'utf8');
  const cpp = fs.readFileSync(cppFile, 'utf8');
  assert(header.includes('maxCacheSize_'), 'FilterEngine 必须包含 maxCacheSize_ 成员');
  assert(header.includes('lruOrder_'), 'FilterEngine 必须包含 lruOrder_ 双向链表追踪使用热度');
  assert(header.includes('TouchLru'), 'FilterEngine 必须包含 TouchLru 私有方法');
  assert(cpp.includes('renderer_.RemoveLut('), 'LRU 淘汰时必须同步释放 Vulkan 纹理');
});

// 4. NAPI 导出 hasLut 与 FilterNativeBridge 同步探查
test('filter_napi.cpp 与 FilterNativeBridge.ets 导出并对接 hasLut', () => {
  const napiFile = path.join(root, 'entry/src/main/cpp/napi/filter_napi.cpp');
  const bridgeFile = path.join(root, 'entry/src/main/ets/features/editor/filter/FilterNativeBridge.ets');
  const napi = fs.readFileSync(napiFile, 'utf8');
  const bridge = fs.readFileSync(bridgeFile, 'utf8');
  assert(napi.includes('"hasLut"'), 'NAPI 导出表必须包含 hasLut');
  assert(bridge.includes('hasLut(filterId: string): boolean;'), 'FilterNativeBridge 必须声明 hasLut 接口');
  assert(bridge.includes('nativeApi.hasLut'), 'FilterNativeBridge.loadPreset 必须检查 nativeApi.hasLut');
});

// 5. EditPage.ets 在 aboutToDisappear 显式调用 FilterNativeBridge.clear()
test('EditPage.ets 退出时主动调用 FilterNativeBridge.clear()', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  const disappearIdx = content.indexOf('aboutToDisappear(): void {');
  assert(disappearIdx > 0, '必须找到 aboutToDisappear');
  const body = content.slice(disappearIdx, disappearIdx + 1200);
  assert(body.includes('FilterNativeBridge.clear()'), 'aboutToDisappear 必须显式调用 FilterNativeBridge.clear()');
});

// 6. EditPage.ets 与 FilterNativeBridge.hasLut 保持严格同步，防止 LRU 淘汰后状态失步
test('EditPage.ets 使用 FilterNativeBridge.hasLut 进行热探测，杜绝本地数组缓存脱节', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/EditPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(!content.includes('this.loadedFilterIds.includes'), '不得使用本地 loadedFilterIds.includes 阻断滤镜重载');
  assert(content.includes('FilterNativeBridge.hasLut'), 'EditPage 必须直接使用 FilterNativeBridge.hasLut 探查');
  const headerFile = path.join(root, 'entry/src/main/cpp/filter/filter_engine.h');
  const header = fs.readFileSync(headerFile, 'utf8');
  assert(header.includes('kDefaultMaxLutCache = 32') || header.includes('kDefaultMaxLutCache = 64'), 'LRU 缓存容量必须至少为 32');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
