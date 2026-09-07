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
console.log('Task 1: 直方图明暗分析与极端诊断测试');
console.log('====================================================');

// 1. ImageToneModels.ets 契约校验
test('ImageToneModels.ets 必须存在且导出核心接口与类型', () => {
  const modelsPath = path.join(root, 'entry/src/main/ets/models/ImageToneModels.ets');
  assert(fs.existsSync(modelsPath), 'ImageToneModels.ets 必须存在');
  const content = fs.readFileSync(modelsPath, 'utf8');
  assert(content.includes('ToneCategory'), '必须导出 ToneCategory');
  assert(content.includes('ToneMetrics'), '必须导出 ToneMetrics');
  assert(content.includes('AuditDiagnosis'), '必须导出 AuditDiagnosis');
  assert(content.includes('AuditIssueType'), '必须导出 AuditIssueType');
  assert(content.includes('dappled_contrast'), '必须包含双峰大光比（阴阳错落）');
  assert(content.includes('high_key'), '必须包含高调（极目高明）');
  assert(content.includes('low_key'), '必须包含暗调（玄冥深致）');
  assert(content.includes('soft_subtle'), '必须包含柔调（烟云冲和）');
  assert(content.includes('rich_full'), '必须包含全阶调（气脉丰匀）');
});

// 2. ImageToneAnalyzer.ets 架构校验
test('ImageToneAnalyzer.ets 必须存在并提供采样与极端诊断方法', () => {
  const analyzerPath = path.join(root, 'entry/src/main/ets/services/ImageToneAnalyzer.ets');
  assert(fs.existsSync(analyzerPath), 'ImageToneAnalyzer.ets 必须存在');
  const content = fs.readFileSync(analyzerPath, 'utf8');
  assert(content.includes('analyzeHistogramFromSamples'), '必须包含 analyzeHistogramFromSamples 纯计算方法');
  assert(content.includes('analyzeImageTone'), '必须包含 analyzeImageTone 异步采样分析');
  assert(content.includes('desiredSize: { width: 64, height: 64 }'), '必须采用 64x64 轻量级采样');
  assert(content.includes('readPixelsToBuffer'), '必须读取像素 Buffer');
});

// 3. 提取纯算法并在 Node 中实测
function extractAnalyzerLogic() {
  const analyzerPath = path.join(root, 'entry/src/main/ets/services/ImageToneAnalyzer.ets');
  let content = fs.readFileSync(analyzerPath, 'utf8');
  const startIdx = content.indexOf('analyzeHistogramFromSamples(');
  const endIdx = content.indexOf('static async analyzeImageTone');
  assert(startIdx > 0 && endIdx > startIdx, '必须能够定位 analyzeHistogramFromSamples 方法区间');
  let methodBody = content.substring(startIdx, endIdx).trim();
  methodBody = methodBody.replace(/analyzeHistogramFromSamples\([^)]*\):[^{]*/, 'function analyzeHistogramFromSamples(luminanceSamples)');
  methodBody = methodBody.replace(/:\s*ToneCategory/g, '');
  methodBody = methodBody.replace(/:\s*ToneMetrics/g, '');
  methodBody = methodBody.replace(/:\s*AuditDiagnosis/g, '');

  const fn = new Function(`
    function createDefaultToneMetrics() {
      return { meanBrightness: 128, stdDev: 40, shadowRatio: 0.1, highlightRatio: 0.1, isBimodal: false, toneCategory: 'balanced', toneLabel: '平和中正' };
    }
    function createDefaultAuditDiagnosis() {
      return { hasIssue: false, issueType: 'none', title: '官署校勘', description: '通篇阴阳适度。', recommendation: '光影得宜。', targetParam: '', suggestedDelta: 0 };
    }
    ${methodBody}
    return analyzeHistogramFromSamples;
  `);
  return fn();
}

test('直方图算法精准识别双峰大光比（草地光影：阴阳错落）', () => {
  const analyze = extractAnalyzerLogic();
  const samples = [];
  for (let i = 0; i < 500; i++) samples.push(25);
  for (let i = 0; i < 500; i++) samples.push(220);

  const result = analyze(samples);
  assert.strictEqual(result.metrics.toneCategory, 'dappled_contrast');
  assert.strictEqual(result.metrics.toneLabel, '阴阳错落');
  assert.strictEqual(result.metrics.isBimodal, true);
});

test('直方图算法精准识别极目高明与玄冥深致', () => {
  const analyze = extractAnalyzerLogic();
  const highSamples = Array(1000).fill(210);
  const highRes = analyze(highSamples);
  assert.strictEqual(highRes.metrics.toneCategory, 'high_key');
  assert.strictEqual(highRes.metrics.toneLabel, '极目高明');

  const lowSamples = Array(1000).fill(35);
  const lowRes = analyze(lowSamples);
  assert.strictEqual(lowRes.metrics.toneCategory, 'low_key');
  assert.strictEqual(lowRes.metrics.toneLabel, '玄冥深致');
});

test('极端直方图诊断：高光溢出触发官署校勘并建议降低曝光', () => {
  const analyze = extractAnalyzerLogic();
  const samples = [];
  for (let i = 0; i < 250; i++) samples.push(252);
  for (let i = 0; i < 750; i++) samples.push(120);

  const result = analyze(samples);
  assert(result.audit.hasIssue, '必须检测出高光溢出异常');
  assert.strictEqual(result.audit.issueType, 'highlight_clipping');
  assert.strictEqual(result.audit.targetParam, 'exposure');
  assert(result.audit.suggestedDelta < 0, '曝光必须建议负向调整');
  assert(result.audit.recommendation.includes('曝光'), '建议文案必须提及曝光');
});

test('极端直方图诊断：暗部死黑触发官署校勘并建议提亮阴影/亮度', () => {
  const analyze = extractAnalyzerLogic();
  const samples = [];
  for (let i = 0; i < 300; i++) samples.push(5);
  for (let i = 0; i < 700; i++) samples.push(130);

  const result = analyze(samples);
  assert(result.audit.hasIssue, '必须检测出暗部死黑');
  assert.strictEqual(result.audit.issueType, 'shadow_clipping');
  assert.strictEqual(result.audit.targetParam, 'brightness');
  assert(result.audit.suggestedDelta > 0, '必须建议正向提亮');
});

test('极端直方图诊断：灰蒙乏力触发官署校勘并建议增加对比度', () => {
  const analyze = extractAnalyzerLogic();
  const samples = Array(1000).fill(120);
  const result = analyze(samples);
  assert(result.audit.hasIssue, '必须检测出反差不足');
  assert.strictEqual(result.audit.issueType, 'low_contrast');
  assert.strictEqual(result.audit.targetParam, 'contrast');
  assert(result.audit.suggestedDelta > 0, '必须建议增加对比');
});

console.log('====================================================');
console.log('Task 2: 拍摄时间、光学参数与题跋生成器全向融合测试');
console.log('====================================================');

// 校验 WorkDescriptionGenerator.ets
test('WorkDescriptionGenerator 导出 DescriptionContext 与全能生成方法', () => {
  const file = path.join(root, 'entry/src/main/ets/models/WorkDescriptionGenerator.ets');
  assert(fs.existsSync(file), 'WorkDescriptionGenerator.ets 必须存在');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('DescriptionContext'), '必须声明并导出 DescriptionContext 接口');
  assert(content.includes('describeSolarTermAndTime'), '必须包含 describeSolarTermAndTime 方法');
  assert(content.includes('describeLensAndOptics'), '必须包含 describeLensAndOptics 方法');
  assert(content.includes('describeToneAndLight'), '必须包含 describeToneAndLight 方法');
  assert(content.includes('generateAuditSuggestion'), '必须包含 generateAuditSuggestion 方法');
});

function extractGeneratorLogic() {
  const file = path.join(root, 'entry/src/main/ets/models/WorkDescriptionGenerator.ets');
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/import\s+[\s\S]*?from\s+['"][^'"]+['"];?/g, '');
  content = content.replace(/export\s+interface\s+[A-Za-z0-9_]+\s*\{[\s\S]*?\}/g, '');
  content = content.replace(/export\s+type\s+[A-Za-z0-9_]+\s*=[\s\S]*?;/g, '');
  content = content.replace(/export\s+function\s+/g, 'function ');
  content = content.replace(/([a-zA-Z0-9_]+)\?\s*:\s*[A-Za-z0-9_<>[\]\s|]+(?=[,\)\{=])/g, '$1');
  content = content.replace(/:\s*[A-Za-z0-9_<>[\]\s|]+(?=[,\)\{=])/g, '');
  content = content.replace(/as\s+[A-Za-z0-9_<>[\]]+/g, '');

  const fn = new Function(`
    ${content}
    return {
      describeSolarTermAndTime,
      describeLensAndOptics,
      describeToneAndLight,
      generateWorkDescription,
      generateAuditSuggestion
    };
  `);
  return fn();
}

test('时间解析：2025.11.29 16:18 映射为初冬晚晴', () => {
  const gen = extractGeneratorLogic();
  const desc = gen.describeSolarTermAndTime('2025.11.29 16:18');
  assert(desc.includes('初冬') || desc.includes('冬月'), '11月下旬应识别为初冬/冬月');
  assert(desc.includes('申末') || desc.includes('晚晴') || desc.includes('斜照'), '16点应识别为申末/晚晴斜照');
});

test('参数解析：50mm f/1.8 1/500s 映射为标头与大光圈', () => {
  const gen = extractGeneratorLogic();
  const desc = gen.describeLensAndOptics('SONY ILCE-7', '50mm  f/1.8  1/500s  ISO320');
  assert(desc.includes('标头') || desc.includes('五旬'), '50mm 应识别为标头');
  assert(desc.includes('大光圈') || desc.includes('虚实'), 'f/1.8 应识别为大光圈虚实');
  assert(desc.includes('疾光') || desc.includes('定格'), '1/500s 应识别为高速定格');
});

test('直方图光影：阴阳错落与高调空灵', () => {
  const gen = extractGeneratorLogic();
  const dappledDesc = gen.describeToneAndLight({ toneCategory: 'dappled_contrast', toneLabel: '阴阳错落' });
  assert(dappledDesc.includes('阴阳') || dappledDesc.includes('光斑') || dappledDesc.includes('错落'), '应包含阴阳错落描述');
});

test('全要素融合生成真实照片案卷批注（完美吻合用户草地样例）', () => {
  const gen = extractGeneratorLogic();
  const context = {
    adjustments: { exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 0 },
    width: 538,
    height: 360,
    exif: {
      deviceModel: 'SONY ILCE-7',
      timeText: '2025.11.29 16:18',
      paramsText: '50mm  f/1.8  1/500s  ISO320'
    },
    toneMetrics: {
      toneCategory: 'dappled_contrast',
      toneLabel: '阴阳错落',
      meanBrightness: 125,
      stdDev: 68,
      shadowRatio: 0.3,
      highlightRatio: 0.25,
      isBimodal: true
    }
  };

  const result = gen.generateWorkDescription(context);
  assert(result.includes('初冬') || result.includes('冬月'), '必须包含岁时信息');
  assert(result.includes('标头') || result.includes('五旬'), '必须包含镜头信息');
  assert(result.includes('阴阳') || result.includes('浓荫') || result.includes('碎金'), '必须包含直方图光影特征');
});

test('老签名保持 100% 向后兼容', () => {
  const gen = extractGeneratorLogic();
  const legacyResult = gen.generateWorkDescription({ exposure: 0, brightness: 0, contrast: 0, saturation: 0, temperature: 0 }, 538, 360);
  assert(typeof legacyResult === 'string' && legacyResult.length > 0, '旧签名必须正常返回字符串');
  assert(legacyResult.includes('此帧'), '旧签名输出符合既有规范');
});

console.log('====================================================');
console.log('Task 3: 案卷批注卡排版与详情页/保存服务动态集成测试');
console.log('====================================================');

// 1. WorkRecord.ets
test('WorkRecord 包含 toneLabel 与 auditSuggestion 持久化字段', () => {
  const file = path.join(root, 'entry/src/main/ets/models/WorkRecord.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('toneLabel: string'), 'WorkRecord 必须声明 toneLabel 字段');
  assert(content.includes('auditSuggestion: string'), 'WorkRecord 必须声明 auditSuggestion 字段');
});

// 2. NotesCard.ets
test('NotesCard 支持 toneLabel 调性印记与 suggestion 官署校勘便签渲染', () => {
  const file = path.join(root, 'entry/src/main/ets/components/common/NotesCard.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('toneLabel: string'), 'NotesCard 必须支持 toneLabel 属性');
  assert(content.includes('suggestion: string'), 'NotesCard 必须支持 suggestion 属性');
  assert(content.includes('官署校勘'), 'NotesCard 必须渲染官署校勘标题');
  assert(content.includes('调性 ·'), 'NotesCard 必须渲染调性标签');
});

// 3. WorkDetailPage.ets
test('WorkDetailPage 接入 ensureWorkAnnotation 异步分析与 NotesCard 参数传递', () => {
  const file = path.join(root, 'entry/src/main/ets/pages/WorkDetailPage.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('ensureWorkAnnotation'), 'WorkDetailPage 必须包含 ensureWorkAnnotation 方法');
  assert(content.includes('ImageToneAnalyzer.analyzeImageTone'), 'WorkDetailPage 必须调用 ImageToneAnalyzer');
  assert(content.includes('ExifReaderService.extractWatermarkInfo'), 'WorkDetailPage 必须调用 ExifReaderService');
  assert(content.includes('toneLabel: this.work?.toneLabel'), 'WorkDetailPage 必须向 NotesCard 传入 toneLabel');
  assert(content.includes('suggestion: this.work?.auditSuggestion'), 'WorkDetailPage 必须向 NotesCard 传入 suggestion');
});

// 4. WorkSaveService.ets
test('WorkSaveService 新建作品时自动分析直方图并生成智能批注', () => {
  const file = path.join(root, 'entry/src/main/ets/services/WorkSaveService.ets');
  const content = fs.readFileSync(file, 'utf8');
  assert(content.includes('ImageToneAnalyzer.analyzeImageTone'), 'WorkSaveService 必须调用 ImageToneAnalyzer');
  assert(content.includes('newWork.toneLabel ='), 'WorkSaveService 必须持久化 toneLabel');
  assert(content.includes('newWork.auditSuggestion ='), 'WorkSaveService 必须持久化 auditSuggestion');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
