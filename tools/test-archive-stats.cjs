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
console.log('Task: 卷宗案牍志（本地创作数据看板）统计算法测试');
console.log('====================================================');

const statsPath = path.join(root, 'entry/src/main/ets/models/ArchiveStats.ets');

// 1. 文件存在性验证
test('ArchiveStats.ets 必须存在且包含核心类型与算法函数', () => {
  assert(fs.existsSync(statsPath), 'ArchiveStats.ets 必须存在');
  const content = fs.readFileSync(statsPath, 'utf8');
  assert(content.includes('interface ArchiveStats'), '必须导出 ArchiveStats 接口');
  assert(content.includes('computeArchiveStats'), '必须导出 computeArchiveStats 函数');
  assert(content.includes('numberToChineseNumeral'), '必须包含大写中文数字转换函数');
});

// 动态提取/执行逻辑
function getArchiveStatsModule() {
  let cleanCode = fs.readFileSync(statsPath, 'utf8');
  cleanCode = cleanCode.replace(/export\s+interface\s+[\s\S]*?}/g, '');
  cleanCode = cleanCode.replace(/import\s+[\s\S]*?;/g, '');
  cleanCode = cleanCode.replace(/:\s*Record<[^>]+>/g, '');
  cleanCode = cleanCode.replace(/:\s*string\[\]/g, '');
  cleanCode = cleanCode.replace(/:\s*WorkRecord\[\]/g, '');
  cleanCode = cleanCode.replace(/:\s*ArchiveStats/g, '');
  cleanCode = cleanCode.replace(/:\s*WorkRecord/g, '');
  cleanCode = cleanCode.replace(/:\s*number/g, '');
  cleanCode = cleanCode.replace(/:\s*string/g, '');
  cleanCode = cleanCode.replace(/:\s*boolean/g, '');
  cleanCode = cleanCode.replace(/export\s+function/g, 'function');

  const moduleScope = { console, WorkStatus: { Sealed: 'sealed', Draft: 'draft' } };
  const wrapper = new Function('scope', 'WorkStatus', `${cleanCode}; scope.computeArchiveStats = computeArchiveStats; scope.numberToChineseNumeral = numberToChineseNumeral;`);
  wrapper(moduleScope, moduleScope.WorkStatus);
  return moduleScope;
}

// 2. 空卷宗（0 作品）边界测试
test('空卷宗边界：0 卷时优雅降级并返回素宣待启文案', () => {
  const { computeArchiveStats } = getArchiveStatsModule();
  const stats = computeArchiveStats([]);
  assert.equal(stats.totalCount, 0);
  assert.equal(stats.totalCountChinese, '零');
  assert.equal(stats.sealedCount, 0);
  assert.equal(stats.draftCount, 0);
  assert.equal(stats.dominantTone, '山河待绘');
  assert(stats.dominantTonePoetic.includes('待启') || stats.dominantTonePoetic.includes('虚席'));
  assert.equal(stats.temperatureBias, '素宣中正');
  assert(stats.poeticSummary.includes('长卷未染') || stats.poeticSummary.includes('素宣'));
});

// 3. 中文传统大写数字转换测试
test('大写中文数字转换：1~100 转换准确', () => {
  const { numberToChineseNumeral } = getArchiveStatsModule();
  assert.equal(numberToChineseNumeral(0), '零');
  assert.equal(numberToChineseNumeral(1), '壹');
  assert.equal(numberToChineseNumeral(5), '伍');
  assert.equal(numberToChineseNumeral(10), '拾');
  assert.equal(numberToChineseNumeral(11), '拾壹');
  assert.equal(numberToChineseNumeral(12), '拾贰');
  assert.equal(numberToChineseNumeral(20), '贰拾');
  assert.equal(numberToChineseNumeral(25), '贰拾伍');
  assert.equal(numberToChineseNumeral(30), '叁拾');
});

// 4. 多作品主流影调频次判定测试
test('多作品统计：准确判定出现频率最高的影调', () => {
  const { computeArchiveStats } = getArchiveStatsModule();
  const mockWorks = [
    { id: '1', toneLabel: '阴阳错落', status: 'sealed', adjustments: { temperature: 0 } },
    { id: '2', toneLabel: '阴阳错落', status: 'sealed', adjustments: { temperature: 5 } },
    { id: '3', toneLabel: '极目高明', status: 'draft', adjustments: { temperature: -2 } },
    { id: '4', toneLabel: '阴阳错落', status: 'sealed', adjustments: { temperature: 10 } }
  ];
  const stats = computeArchiveStats(mockWorks);
  assert.equal(stats.totalCount, 4);
  assert.equal(stats.totalCountChinese, '肆');
  assert.equal(stats.sealedCount, 3);
  assert.equal(stats.draftCount, 1);
  assert.equal(stats.dominantTone, '阴阳错落');
  assert.equal(stats.dominantTonePoetic, '明晦相生 · 虚实合度');
});

// 5. 色温均值风骨测试（偏暖、偏冷、中正）
test('色温风骨：偏暖/偏冷/中正区间计算正确', () => {
  const { computeArchiveStats } = getArchiveStatsModule();
  
  // 偏暖 (均值 > 8)
  const warmWorks = [
    { id: '1', toneLabel: '浑厚华滋', status: 'sealed', adjustments: { temperature: 20 } },
    { id: '2', toneLabel: '浑厚华滋', status: 'sealed', adjustments: { temperature: 16 } }
  ];
  const warmStats = computeArchiveStats(warmWorks);
  assert.equal(warmStats.temperatureBias, '日暮微曛');
  assert(warmStats.temperatureDetail.includes('偏暖'));

  // 偏冷 (均值 < -8)
  const coldWorks = [
    { id: '1', toneLabel: '温润柔和', status: 'sealed', adjustments: { temperature: -15 } },
    { id: '2', toneLabel: '温润柔和', status: 'sealed', adjustments: { temperature: -25 } }
  ];
  const coldStats = computeArchiveStats(coldWorks);
  assert.equal(coldStats.temperatureBias, '雪岭霜晨');
  assert(coldStats.temperatureDetail.includes('偏冷'));

  // 中正 (-8 <= 均值 <= 8)
  const neutralWorks = [
    { id: '1', toneLabel: '玄冥幽微', status: 'sealed', adjustments: { temperature: 2 } },
    { id: '2', toneLabel: '玄冥幽微', status: 'sealed', adjustments: { temperature: -1 } }
  ];
  const neutralStats = computeArchiveStats(neutralWorks);
  assert.equal(neutralStats.temperatureBias, '素宣中正');
  assert(neutralStats.temperatureDetail.includes('中正'));
});

// 6. 空 toneLabel 历史数据容错
test('历史旧作品无 toneLabel 时平滑容错不崩溃', () => {
  const { computeArchiveStats } = getArchiveStatsModule();
  const legacyWorks = [
    { id: 'legacy-1', toneLabel: '', status: 'draft', adjustments: { temperature: 0 } },
    { id: 'legacy-2', status: 'sealed', adjustments: { temperature: 5 } }
  ];
  const stats = computeArchiveStats(legacyWorks);
  assert.equal(stats.totalCount, 2);
  assert.equal(stats.sealedCount, 1);
  assert.equal(stats.draftCount, 1);
  assert(stats.dominantTone.length > 0);
});

console.log('====================================================');
console.log(`测试完成: ${passed} 通过, ${failed} 失败`);
console.log('====================================================');
if (failed > 0) {
  process.exit(1);
}
