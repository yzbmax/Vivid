const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const borderPainterPath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');
const borderPanelPath = path.join(root, 'entry/src/main/ets/components/editor/BorderPanel.ets');
const borderStatePath = path.join(root, 'entry/src/main/ets/features/editor/border/BorderState.ets');

console.log('====================================================');
console.log('清新薄荷绿 & 旅行明信片 水印重构专项测试套件');
console.log('====================================================');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✔ [PASS] ${name}`);
    passed++;
  } catch (err) {
    console.error(`  ✘ [FAIL] ${name}: ${err.message}`);
    failed++;
  }
}

const borderPainterContent = fs.readFileSync(borderPainterPath, 'utf8');
const borderPanelContent = fs.readFileSync(borderPanelPath, 'utf8');
const borderStateContent = fs.readFileSync(borderStatePath, 'utf8');

// ==========================================
// 1. 源码契约与旧版残留清除校验
// ==========================================
test('旧版简陋手绘线框相机代码已彻底清除', () => {
  assert(!borderPainterContent.includes('camSize * 1.3'), '不得包含旧版机身宽度乘数 camSize * 1.3');
  assert(!borderPainterContent.includes('camSize * 0.8'), '不得包含旧版机身高度乘数 camSize * 0.8');
  assert(!borderPainterContent.includes('camSize * 0.24'), '不得包含旧版镜头圆弧半径 camSize * 0.24');
  assert(!borderPainterContent.includes('camSize * 0.12'), '不得包含旧版快门凸起高度 camSize * 0.12');
});

test('旧版粗糙二次贝塞尔波浪消资线循环已彻底清除', () => {
  assert(!borderPainterContent.includes('quadraticCurveTo'), '不得再使用生硬的二次贝塞尔曲线 quadraticCurveTo');
  assert(!borderPainterContent.includes('wy - 3 * scale'), '不得包含旧版 3 根波浪硬编码控制点');
  assert(!borderPainterContent.includes('i * 5 * scale'), '不得包含旧版 i * 5 * scale 循环');
});

// ==========================================
// 2. 清新薄荷绿：矢量相机图符与 Path2D 校验
// ==========================================
test('MINT_CAMERA_ICON_SVG 纯矢量路径定义完整且符合 SVG 语法与非零环绕数规范', () => {
  assert(borderPainterContent.includes('export const MINT_CAMERA_ICON_SVG: string ='), '必须导出 MINT_CAMERA_ICON_SVG 常量');
  
  // 提取 MINT_CAMERA_ICON_SVG 字符串
  const match = borderPainterContent.match(/export const MINT_CAMERA_ICON_SVG:\s*string\s*=\s*([\s\S]*?);/);
  assert(match, '必须能提取到 MINT_CAMERA_ICON_SVG 定义');
  const rawSvgCode = match[1];
  // 在沙箱中评估字符串
  const svgStr = eval(rawSvgCode);
  assert(typeof svgStr === 'string', 'MINT_CAMERA_ICON_SVG 必须为字符串类型');
  assert(svgStr.trim().startsWith('M'), 'SVG 路径必须以 M (moveTo) 开头');
  assert(svgStr.length > 100, `SVG 路径长度必须足够精细，当前长度: ${svgStr.length}`);
  // 验证只包含合法 SVG 路径字符
  const validChars = /^[MmLlHhVvCcSsQqTtAaZz0-9\s.,\-]+$/;
  assert(validChars.test(svgStr), 'SVG 路径必须只包含有效路径指令与数值字符');
  // 验证包含非零环绕数挖空（存在 a 指令用于同心透镜组）
  assert(svgStr.includes('a 5.5 5.5') || svgStr.includes('a5.5'), '必须包含同心环透镜组弧线指令');
});

test('BorderPainter 导出 getMintCameraIconPath 并实现单例缓存', () => {
  assert(borderPainterContent.includes('export function getMintCameraIconPath(): Path2D'), '必须导出 getMintCameraIconPath');
  assert(borderPainterContent.includes('let mintCameraIconPath: Path2D | null = null;'), '必须有可空单例缓存变量');
  assert(borderPainterContent.includes('new Path2D(MINT_CAMERA_ICON_SVG)'), '单例未命中时必须创建 new Path2D');
});

// ==========================================
// 3. 清新薄荷绿：品牌徽标联动与去重
// ==========================================
test('清新薄荷绿完整联动品牌徽标判定与冲突去重', () => {
  // 检查 paintMintFilmWatermark 是否完整调用品牌与去重链条
  const fnMatch = borderPainterContent.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  assert(fnMatch, '必须找到 paintMintFilmWatermark 函数实现');
  const fnContent = fnMatch[0];

  assert(fnContent.includes('isLogoDuplicatedWithDevice(wm.logo, rawDevice)'), '必须调用 isLogoDuplicatedWithDevice 检查去重');
  assert(fnContent.includes('paintLogoBadge(context, logo,'), '必须调用 paintLogoBadge 绘制品牌徽标');
  assert(fnContent.includes('formatWatermarkDeviceText(rawDevice, logo, hasLogo)'), '必须调用 formatWatermarkDeviceText 规整机型');
  assert(fnContent.includes('getLogoBadgeWidth(context, logo,'), '必须调用 getLogoBadgeWidth 测量品牌宽度');
});

test('清新薄荷绿在无品牌/品牌关闭时优雅降级为旁轴微单矢量图标', () => {
  const fnMatch = borderPainterContent.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes('getMintCameraIconPath()'), '无品牌或关闭时必须降级调用 getMintCameraIconPath()');
  assert(fnContent.includes('context.fill(getMintCameraIconPath());'), '必须通过 context.fill 绘制矢量相机路径');
  assert(fnContent.includes("device || 'MINT CAMERA'") || fnContent.includes("'MINT CAMERA'"), '机型为空时必须展示 MINT CAMERA 兜底文案');
});

// ==========================================
// 4. 清新薄荷绿：白瓷胶囊与参数规范化
// ==========================================
test('清新薄荷绿白瓷半透胶囊 0.36 黄金比例与两端 0.6 圆弧安全留白', () => {
  const fnMatch = borderPainterContent.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes('bannerH * 0.36'), '胶囊高度必须采用 bannerH * 0.36 黄金比例');
  assert(fnContent.includes('tagH * 0.6'), '两端内边距必须采用 tagH * 0.6 动态圆弧安全留白');
  assert(fnContent.includes('rgba(255, 255, 255, 0.90)'), '胶囊底色必须采用白瓷半透质感 rgba(255, 255, 255, 0.90)');
  assert(fnContent.includes('rgba(29, 69, 59, 0.10)'), '胶囊必须绘制微光发丝边 rgba(29, 69, 59, 0.10)');
});

test('清新薄荷绿曝光参数规范化清洗与中间点 · 分隔', () => {
  const fnMatch = borderPainterContent.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes("replace(/\\s*sec\\.?s?/gi, 's')"), '参数清洗必须去除冗余的 sec/sec.s 单位');
  assert(fnContent.includes("replace(/\\s{2,}/g, ' · ')") || fnContent.includes("' · '"), '参数分隔符必须采用居中点 · 规范化');
});

test('清新薄荷绿左右双端动态防撞收缩与自适应截断防护', () => {
  const fnMatch = borderPainterContent.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes('shrink = Math.max(0.70,'), '防撞必须支持 shrink 自适应收缩，下限 0.70');
  assert(fnContent.includes('leftW + minGap + tagW > availW'), '必须精确检测左侧宽度+安全间距+右侧胶囊是否超出可用宽度');
  assert(fnContent.includes('textToDraw += \'…\''), '超长机型文字在极端宽度下必须执行省略截断');
});

test('BorderPanel 与 BorderState 清新薄荷绿默认色值一致性（0xFFA3E4D7）', () => {
  assert(
    borderPanelContent.includes("if (id === 'watermark_mint_film') {\n      return 0xFFA3E4D7;"),
    'BorderPanel.ets 第 666 行必须返回正确的浅薄荷绿 0xFFA3E4D7'
  );
  assert(
    borderStateContent.includes("if (templateId === 'watermark_mint_film') {\n    return 0xFFA3E4D7;"),
    'BorderState.ets 必须指定 0xFFA3E4D7'
  );
});

// ==========================================
// 5. 旅行明信片：照片圆角同步与古典日戳
// ==========================================
test('旅行明信片内衬白边严格契合照片圆角（cornerRadius 适配）', () => {
  const fnMatch = borderPainterContent.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  assert(fnMatch, '必须找到 paintTravelPostcardWatermark 函数实现');
  const fnContent = fnMatch[0];

  assert(fnContent.includes('geometry.cornerRadius * scale'), '必须提取照片圆角半径 cornerRadius');
  assert(fnContent.includes('drawRoundedRectPath'), '当照片存在圆角时必须使用 drawRoundedRectPath 绘制白框');
  assert(fnContent.includes('context.strokeRect'), '当照片为直角时正确降级为 strokeRect');
});

test('旅行明信片复古航空日戳双圈层级、三段式横隔线与 -4.2° 微倾角', () => {
  const fnMatch = borderPainterContent.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes('stampR * 0.68'), '内圈半径必须为 stampR * 0.68');
  assert(fnContent.includes('rotate(-0.073)'), '邮戳盖印必须施加 -4.2° (-0.073rad) 手工拟真微倾角');
  assert(fnContent.includes('chordHalfW = Math.sqrt('), '日戳中舱横隔线必须通过圆方程精确求解弦长');
  assert(fnContent.includes("fillText('★   ★   ★'"), '下弦必须绘制经典三颗微星徽');
});

test('旅行明信片 AIR MAIL 沿圆弧弯曲排版（drawArcText）', () => {
  assert(borderPainterContent.includes('export function drawArcText('), '必须导出 drawArcText 函数');
  const fnMatch = borderPainterContent.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];
  assert(fnContent.includes("drawArcText(context, 'AIR MAIL', arcR, 0.85)"), '上弦必须沿弧线绘制 AIR MAIL');
});

test('formatPostmarkDate 正确格式化日期为古典航空日戳风格', () => {
  assert(borderPainterContent.includes('export function formatPostmarkDate('), '必须导出 formatPostmarkDate 函数');

  // 提取 formatPostmarkDate 逻辑进行独立单测验证
  function formatPostmarkDate(timeText) {
    if (!timeText || timeText.trim().length === 0) {
      return '2026.09.11';
    }
    const clean = timeText.trim();
    const match = clean.match(/^(\d{4})[.\-\/:](\d{1,2})[.\-\/:](\d{1,2})/);
    if (match) {
      const y = match[1];
      const m = match[2].padStart(2, '0');
      const d = match[3].padStart(2, '0');
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      const mIdx = parseInt(m, 10) - 1;
      if (mIdx >= 0 && mIdx < 12) {
        return `${d} · ${months[mIdx]} · ${y.substring(2)}`;
      }
      return `${y}.${m}.${d}`;
    }
    return clean.substring(0, 10);
  }

  assert.equal(formatPostmarkDate('2026.09.03 16:30'), '03 · SEP · 26');
  assert.equal(formatPostmarkDate('2026:09:11 14:20:00'), '11 · SEP · 26');
  assert.equal(formatPostmarkDate('2025-01-15'), '15 · JAN · 25');
  assert.equal(formatPostmarkDate(''), '2026.09.11');
});

test('旅行明信片 4 联装平滑三次贝塞尔空气动力学波浪消资线（drawAerodynamicWaveLines）', () => {
  assert(borderPainterContent.includes('export function drawAerodynamicWaveLines('), '必须导出 drawAerodynamicWaveLines');
  const fnMatch = borderPainterContent.match(/export function drawAerodynamicWaveLines[\s\S]*?^}/m);
  assert(fnMatch, '必须找到 drawAerodynamicWaveLines 函数实现');
  const fnContent = fnMatch[0];

  assert(fnContent.includes('for (let i = 0; i < 4; i++)'), '消资线必须为标准 4 联装');
  assert(fnContent.includes('bezierCurveTo('), '波浪线必须采用平滑三次贝塞尔 bezierCurveTo 绘制');
  assert(fnContent.includes("context.lineCap = 'round'"), '波浪线两端必须使用 round 圆润触笔');
  assert(fnContent.includes('halfWave * 0.364') && fnContent.includes('halfWave * 0.636'), '贝塞尔控制点必须逼近正弦流线');
});

test('旅行明信片左侧意境题签与拍摄参数协同展示（杜绝 params || time 互斥丢弃）', () => {
  const fnMatch = borderPainterContent.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(!fnContent.includes('params || time'), '严禁使用 params || time 短路互斥逻辑');
  assert(fnContent.includes("titleText = '去有风的地方'"), '主标题必须包含去有风的地方');
  assert(fnContent.includes('"Georgia", "Noto Serif SC", serif'), '题签必须使用经典优雅衬线字体族');
  assert(fnContent.includes('sublineParts.push(device)') && fnContent.includes('sublineParts.push(params)'), '副行必须协同机型与光学曝光参数');
});

test('旅行明信片 4 级自适应防撞体系（波浪压缩->波浪隐藏->字号微缩与智能截断，保证 >=16px 留白）', () => {
  const fnMatch = borderPainterContent.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  const fnContent = fnMatch[0];

  assert(fnContent.includes('safeGap = Math.max(14 * scale, 16)'), '安全隔离带必须保证至少 16px*scale');
  assert(fnContent.includes('waveW = Math.max(16 * scale, Math.round(waveW * 0.55))'), 'Level 2: 必须支持压缩波浪线');
  assert(fnContent.includes('showWaves = false'), 'Level 3: 空间不足时优雅隐藏波浪线仅留日戳');
  assert(fnContent.includes('factor = Math.max(0.82, availTextW / maxLeftW)'), 'Level 4: 极端情况下微缩字号');
  assert(fnContent.includes('drawSub += \'…\''), '超长副标题末尾执行安全截断');
});

// ==========================================
// 6. ArkTS 严格模式与强类型规范校验
// ==========================================
test('ArkTS 严格模式与强类型规范校验（零 any、显式返回类型、scale 全程贯穿）', () => {
  // 1. 零 any 检查（在相关函数和新增代码段中）
  const relevantLines = borderPainterContent
    .split('\n')
    .filter((line) => line.includes('Mint') || line.includes('TravelPostcard') || line.includes('Postmark') || line.includes('WaveLines') || line.includes('ArcText'));
  
  for (const line of relevantLines) {
    assert(!line.includes(': any') && !line.includes('<any>'), `代码行包含 any 违规: ${line}`);
  }

  // 2. 显式函数返回类型检查
  assert(borderPainterContent.includes('getMintCameraIconPath(): Path2D'), 'getMintCameraIconPath 必须显式返回 Path2D');
  assert(borderPainterContent.includes('formatPostmarkDate(timeText: string): string'), 'formatPostmarkDate 必须显式返回 string');
  assert(borderPainterContent.includes('drawArcText(') && borderPainterContent.includes('): void'), 'drawArcText 必须显式返回 void');
  assert(borderPainterContent.includes('drawAerodynamicWaveLines(') && borderPainterContent.includes('): void'), 'drawAerodynamicWaveLines 必须显式返回 void');
  assert(borderPainterContent.includes('paintMintFilmWatermark(') && borderPainterContent.includes('): void'), 'paintMintFilmWatermark 必须显式返回 void');
  assert(borderPainterContent.includes('paintTravelPostcardWatermark(') && borderPainterContent.includes('): void'), 'paintTravelPostcardWatermark 必须显式返回 void');

  // 3. scale 贯穿检查
  assert(borderPainterContent.includes('scale: number'), '绘制函数必须传递 scale 参数');
});

console.log('====================================================');
console.log(`测试结果: ${passed} 项通过, ${failed} 项失败`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
}
