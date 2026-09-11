const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor-ohos-plugin/node_modules/typescript');

const repo = path.resolve(__dirname, '..');
const cache = new Map();
global.Path2D = class Path2D {
  constructor(d) {
    this.d = d;
  }
};

function load(file) {
  if (cache.has(file)) return cache.get(file).exports;
  const source = fs.readFileSync(file, 'utf8');
  const compiled = ts.transpileModule(source, {
    fileName: file.replace(/\.ets$/, '.ts'),
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  }).outputText;
  const module = { exports: {} };
  cache.set(file, module);
  const localRequire = id => {
    if (id === '@kit.ArkUI') return { LengthMetricsUnit: { PX: 1, VP: 0 } };
    if (!id.startsWith('.')) return {};
    let resolved = path.resolve(path.dirname(file), id + '.ets');
    return load(resolved);
  };
  const evaluate = vm.runInThisContext('(function(require,module,exports){\n' + compiled + '\n})', { filename: file });
  evaluate(localRequire, module, module.exports);
  return module.exports;
}

const borderPainter = load(path.join(repo, 'entry/src/main/ets/features/editor/border/BorderPainter.ets'));
const borderResolver = load(path.join(repo, 'entry/src/main/ets/features/editor/border/BorderLayoutResolver.ets'));
const borderState = load(path.join(repo, 'entry/src/main/ets/features/editor/border/BorderState.ets'));

/**
 * 测量文本宽度（严谨拟合 Canvas 字体测量模型）
 */
function measureTextWidth(fontStr, text) {
  if (!text) return 0;
  const m = String(fontStr).match(/(\d+(?:\.\d+)?)px/);
  const size = m ? parseFloat(m[1]) : 14;
  const isMonospace = /monospace/i.test(fontStr);
  let w = 0;
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    if (code >= 0x4e00 && code <= 0x9fff) {
      w += size * 1.0; // CJK 汉字全角
    } else if (isMonospace) {
      w += size * 0.60;
    } else if (/[mwWMQ#@]/.test(text[i])) {
      w += size * 0.80;
    } else if (/[ijlI!|:;.,' ]/.test(text[i])) {
      w += size * 0.30;
    } else {
      w += size * 0.55;
    }
  }
  return w;
}

/**
 * 创建高保真追踪 Mock Canvas Context
 */
function createInstrumentedContext() {
  const stateStack = [];
  let currentState = {
    tx: 0,
    ty: 0,
    sx: 1,
    sy: 1,
    rot: 0,
    font: '10px sans-serif',
    textAlign: 'left',
    textBaseline: 'alphabetic',
    fillStyle: '#000',
    strokeStyle: '#000',
    lineWidth: 1
  };

  const logs = {
    texts: [],
    roundedRects: [],
    rects: [],
    arcs: []
  };

  const ctx = {
    get font() { return currentState.font; },
    set font(v) { currentState.font = v; },
    get textAlign() { return currentState.textAlign; },
    set textAlign(v) { currentState.textAlign = v; },
    get textBaseline() { return currentState.textBaseline; },
    set textBaseline(v) { currentState.textBaseline = v; },
    get fillStyle() { return currentState.fillStyle; },
    set fillStyle(v) { currentState.fillStyle = v; },
    get strokeStyle() { return currentState.strokeStyle; },
    set strokeStyle(v) { currentState.strokeStyle = v; },
    get lineWidth() { return currentState.lineWidth; },
    set lineWidth(v) { currentState.lineWidth = v; },
    get lineCap() { return currentState.lineCap; },
    set lineCap(v) { currentState.lineCap = v; },
    get shadowColor() { return currentState.shadowColor; },
    set shadowColor(v) { currentState.shadowColor = v; },
    get shadowBlur() { return currentState.shadowBlur; },
    set shadowBlur(v) { currentState.shadowBlur = v; },
    get shadowOffsetY() { return currentState.shadowOffsetY; },
    set shadowOffsetY(v) { currentState.shadowOffsetY = v; },

    save() {
      stateStack.push({ ...currentState });
    },
    restore() {
      if (stateStack.length > 0) {
        currentState = stateStack.pop();
      }
    },
    translate(x, y) {
      currentState.tx += x * currentState.sx;
      currentState.ty += y * currentState.sy;
    },
    scale(sx, sy) {
      currentState.sx *= sx;
      currentState.sy *= sy;
    },
    rotate(rad) {
      currentState.rot += rad;
    },
    beginPath() {},
    closePath() {},
    moveTo(_x, _y) {},
    lineTo(_x, _y) {},
    bezierCurveTo(_cp1x, _cp1y, _cp2x, _cp2y, _x, _y) {},
    arc(x, y, r, _sAngle, _eAngle) {
      logs.arcs.push({
        x: currentState.tx + x * currentState.sx,
        y: currentState.ty + y * currentState.sy,
        r: r * currentState.sx,
        strokeStyle: currentState.strokeStyle
      });
    },
    arcTo(_x1, _y1, _x2, _y2, _radius) {},
    stroke() {},
    fill(_path) {},
    strokeRect(x, y, w, h) {
      logs.rects.push({
        type: 'stroke',
        x: currentState.tx + x * currentState.sx,
        y: currentState.ty + y * currentState.sy,
        w: w * currentState.sx,
        h: h * currentState.sy,
        strokeStyle: currentState.strokeStyle
      });
    },
    fillRect(x, y, w, h) {
      logs.rects.push({
        type: 'fill',
        x: currentState.tx + x * currentState.sx,
        y: currentState.ty + y * currentState.sy,
        w: w * currentState.sx,
        h: h * currentState.sy,
        fillStyle: currentState.fillStyle
      });
    },
    rect(x, y, w, h) {
      logs.rects.push({
        type: 'path',
        x: currentState.tx + x * currentState.sx,
        y: currentState.ty + y * currentState.sy,
        w: w * currentState.sx,
        h: h * currentState.sy
      });
    },
    measureText(text) {
      return { width: measureTextWidth(currentState.font, text) };
    },
    fillText(text, x, y) {
      const w = measureTextWidth(currentState.font, text);
      const absX = currentState.tx + x * currentState.sx;
      const absY = currentState.ty + y * currentState.sy;
      let startX = absX;
      if (currentState.textAlign === 'center') {
        startX = absX - w * 0.5;
      } else if (currentState.textAlign === 'right') {
        startX = absX - w;
      }
      const endX = startX + w;
      logs.texts.push({
        text,
        absX,
        absY,
        startX,
        endX,
        w,
        font: currentState.font,
        textAlign: currentState.textAlign,
        fillStyle: currentState.fillStyle,
        rot: currentState.rot
      });
    }
  };

  return { ctx, logs };
}

console.log('================================================================');
console.log('CHALLENGER 1: 对抗压力测试 (Anti-Collision & Edge Cases)');
console.log('================================================================');

let totalTests = 0;
let passedTests = 0;
let violations = [];

function runAdversarialCase(testName, setupFn, verifyFn) {
  totalTests++;
  const { ctx, logs } = createInstrumentedContext();
  try {
    const { geometry, state, scale } = setupFn();
    borderPainter.paintBorder(ctx, geometry, state, scale);
    const failureReason = verifyFn(logs, geometry, state, scale);
    if (!failureReason) {
      passedTests++;
      console.log(`  ✔ [PASS] ${testName}`);
    } else {
      violations.push({ testName, reason: failureReason });
      console.log(`  ✘ [FAIL] ${testName}: ${failureReason}`);
    }
  } catch (err) {
    violations.push({ testName, reason: `EXCEPTION: ${err.message}\n${err.stack}` });
    console.log(`  ✘ [CRASH] ${testName}: ${err.message}`);
  }
}

// -----------------------------------------------------------------------------
// 测试矩阵定义
// -----------------------------------------------------------------------------
const aspectRatios = [
  { name: '9:16 Portrait (Narrow)', w: 1080, h: 1920 },
  { name: '1:2 Ultra-Narrow Portrait', w: 1000, h: 2000 },
  { name: '3:4 Standard Portrait', w: 1500, h: 2000 },
  { name: '1:1 Square', w: 1600, h: 1600 },
  { name: '4:3 Standard Landscape', w: 2000, h: 1500 },
  { name: '16:9 Landscape', w: 1920, h: 1080 },
  { name: '21:9 Ultra-Wide Landscape', w: 2560, h: 1080 },
  { name: '3:1 Extreme Panoramic Landscape', w: 3000, h: 1000 },
  { name: 'Small Screen 9:16 (Preview)', w: 360, h: 640 },
  { name: 'Tiny Screen 1:2 (Preview)', w: 240, h: 480 }
];

const stringVariants = [
  {
    name: 'Normal Standard Strings',
    device: 'Sony A7M4',
    params: '50mm f/1.4  1/250s  ISO 100',
    time: '2026-09-11 10:30'
  },
  {
    name: 'Extreme Long Strings (Dispatched Prompt Spec)',
    device: 'Hasselblad X2D 100C Earth Explorer Edition Limited Dual Lens Kit',
    params: '24-70mm f/2.8 GM II  1/8000s  ISO 100  +1.7EV  AWB Vivid Sunset',
    time: '2026.09.11 16:45:00'
  },
  {
    name: 'Empty Strings / Missing Fields',
    device: '',
    params: '',
    time: ''
  },
  {
    name: 'Single Long Device Only',
    device: 'Hasselblad X2D 100C Earth Explorer Edition Limited Dual Lens Kit',
    params: '',
    time: '2026-09-11'
  },
  {
    name: 'Single Long Params Only',
    device: '',
    params: '24-70mm f/2.8 GM II  1/8000s  ISO 100  +1.7EV  AWB Vivid Sunset',
    time: '2026-09-11'
  }
];

const scales = [0.1, 0.5, 1.0, 2.0, 4.0];

// =============================================================================
// 1. 清新薄荷绿 (Fresh Mint: watermark_mint_film) 压力测试
// =============================================================================
console.log('\n--- 1. 清新薄荷绿 (Fresh Mint) 防撞与边界压力测试 ---');

for (const ar of aspectRatios) {
  for (const sv of stringVariants) {
    for (const scale of [0.5, 1.0, 2.0]) {
      const testName = `[Mint] ${ar.name} | ${sv.name} | scale=${scale}`;
      runAdversarialCase(testName, () => {
        const rawState = {
          templateId: 'watermark_mint_film',
          widthRatio: 0.08,
          cornerRadiusRatio: 0,
          colorArgb: 0xFFA3E4D7,
          shadowStrength: 0,
          watermark: {
            showDevice: true,
            deviceModel: sv.device,
            showParams: true,
            paramsText: sv.params,
            showTime: true,
            timeText: sv.time,
            showLogo: true,
            logo: 'none'
          }
        };
        const state = borderState.sanitizeBorderState(rawState);
        const geometry = borderResolver.resolveBorderGeometry({
          photoWidth: ar.w,
          photoHeight: ar.h,
          border: state
        });
        return { geometry, state, scale };
      }, (logs, geometry, state, scale) => {
        const px = geometry.photoRect.x * scale;
        const pw = geometry.photoRect.width * scale;
        const rightEdge = px + pw;

        // 寻找机型文字与胶囊文字
        // 机型文字 fillStyle 为 '#1D453B'
        // 胶囊文字 fillStyle 为 '#154035'
        const deviceTexts = logs.texts.filter(t => t.fillStyle === '#1D453B');
        const capsuleTexts = logs.texts.filter(t => t.fillStyle === '#154035');

        let deviceEnd = px;
        if (deviceTexts.length > 0) {
          deviceEnd = Math.max(...deviceTexts.map(t => t.endX));
        }

        let capsuleStart = rightEdge;
        let capsuleEnd = rightEdge;
        if (capsuleTexts.length > 0) {
          // 胶囊文字居中，胶囊本身比文字两端大约扩展 0.6 * tagH
          const capText = capsuleTexts[0];
          // 计算胶囊背景矩形的实际左右端点
          // 在 BorderPainter 中：
          // tagX = px + pw - finalTagW
          // capText.absX = tagX + finalTagW * 0.5
          // 因此 tagX = 2 * capText.absX - (px + pw)
          // finalTagW = 2 * (px + pw - capText.absX)
          capsuleEnd = rightEdge;
          const finalTagW = 2 * (rightEdge - capText.absX);
          capsuleStart = rightEdge - finalTagW;
        }

        // 检查 1: 胶囊是否越界溢出到照片右边缘之外
        if (capsuleEnd > rightEdge + 1) {
          return `胶囊右边缘溢出: capsuleEnd=${capsuleEnd} > rightEdge=${rightEdge}`;
        }

        // 检查 2: 胶囊是否溢出到照片左边缘之外 (严重畸形)
        if (capsuleTexts.length > 0 && capsuleStart < px) {
          return `胶囊超大倒灌溢出到左侧: capsuleStart=${capsuleStart} < px=${px}`;
        }

        // 检查 3: 机型文字与胶囊是否存在物理碰撞/重叠
        if (deviceTexts.length > 0 && capsuleTexts.length > 0) {
          const overlap = deviceEnd - capsuleStart;
          if (overlap > 0) {
            return `【严重碰撞】机型文字与参数胶囊发生物理重合！overlap=${overlap.toFixed(1)}px (deviceEnd=${deviceEnd.toFixed(1)}, capsuleStart=${capsuleStart.toFixed(1)})`;
          }
        }

        // 检查 4: 文字是否超越了照片右边界
        if (deviceEnd > rightEdge) {
          return `机型文字溢出照片右边界: deviceEnd=${deviceEnd} > rightEdge=${rightEdge}`;
        }

        return null;
      });
    }
  }
}

// =============================================================================
// 2. 旅行明信片 (Travel Postcard: watermark_travel_postcard) 压力测试
// =============================================================================
console.log('\n--- 2. 旅行明信片 (Travel Postcard) 防撞与边界压力测试 ---');

for (const ar of aspectRatios) {
  for (const sv of stringVariants) {
    for (const scale of [0.5, 1.0, 2.0]) {
      const testName = `[Postcard] ${ar.name} | ${sv.name} | scale=${scale}`;
      runAdversarialCase(testName, () => {
        const rawState = {
          templateId: 'watermark_travel_postcard',
          widthRatio: 0.08,
          cornerRadiusRatio: 0,
          colorArgb: 0xFFEBF3F5,
          shadowStrength: 0,
          watermark: {
            showDevice: true,
            deviceModel: sv.device,
            showParams: true,
            paramsText: sv.params,
            showTime: true,
            timeText: sv.time || '2026-09-11 12:00',
            showLogo: false,
            logo: 'none'
          }
        };
        const state = borderState.sanitizeBorderState(rawState);
        const geometry = borderResolver.resolveBorderGeometry({
          photoWidth: ar.w,
          photoHeight: ar.h,
          border: state
        });
        return { geometry, state, scale };
      }, (logs, geometry, state, scale) => {
        const px = geometry.photoRect.x * scale;
        const pw = geometry.photoRect.width * scale;
        const rightEdge = px + pw;

        // 查找邮戳中心（通过圆弧判定）
        const stampArcs = logs.arcs.filter(a => a.strokeStyle === '#476375');
        if (stampArcs.length === 0) {
          return '未检测到邮戳绘制';
        }
        const outerArc = stampArcs.reduce((prev, curr) => (curr.r > prev.r ? curr : prev), stampArcs[0]);
        const stampCenterX = outerArc.x;
        const stampR = outerArc.r;
        const stampLeft = stampCenterX - stampR;

        // 查找左侧主标题与副标题
        // 主标题: #243A47 ('去有风的地方')
        // 副标题: #5A7382 (机型与参数)
        const titleTexts = logs.texts.filter(t => t.fillStyle === '#243A47');
        const sublineTexts = logs.texts.filter(t => t.fillStyle === '#5A7382');

        const titleEnd = titleTexts.length > 0 ? Math.max(...titleTexts.map(t => t.endX)) : px;
        const sublineEnd = sublineTexts.length > 0 ? Math.max(...sublineTexts.map(t => t.endX)) : px;
        const maxTextEnd = Math.max(titleEnd, sublineEnd);

        // 校验要求：text end coordinate x <= stampLeft - 16px clearance
        // 允许亚像素级误差 (0.5px)
        const requiredClearance = Math.max(14 * scale, 16);
        const actualClearance = stampLeft - maxTextEnd;

        if (actualClearance < -0.5) {
          return `【严重碰撞】左侧文字与邮戳发生重叠碰撞！stampLeft=${stampLeft.toFixed(1)}, maxTextEnd=${maxTextEnd.toFixed(1)}, 侵入=${(-actualClearance).toFixed(1)}px`;
        }

        // 严格安全留白检查
        if (actualClearance < 15.5) {
          return `【安全间距不足】保留间隙为 ${actualClearance.toFixed(1)}px，低于最低要求的 16px 安全隔离带 (stampLeft=${stampLeft.toFixed(1)}, maxTextEnd=${maxTextEnd.toFixed(1)})`;
        }

        return null;
      });
    }
  }
}

// =============================================================================
// 3. 极端极端比例与微缩尺寸极限压测 (Scale = 0.1, 4.0, 极端长图 1:3, 3:1)
// =============================================================================
console.log('\n--- 3. 极限微缩与巨幅尺寸压测 (scale=0.1, 4.0) ---');

const boundaryCases = [
  { name: 'Scale=0.1 Tiny Canvas (Thumbnail)', w: 800, h: 1200, scale: 0.1, template: 'watermark_mint_film' },
  { name: 'Scale=4.0 Ultra-HD 8K Export', w: 3840, h: 2160, scale: 4.0, template: 'watermark_mint_film' },
  { name: 'Scale=0.1 Tiny Canvas (Thumbnail)', w: 800, h: 1200, scale: 0.1, template: 'watermark_travel_postcard' },
  { name: 'Scale=4.0 Ultra-HD 8K Export', w: 3840, h: 2160, scale: 4.0, template: 'watermark_travel_postcard' },
  { name: 'Zero Dimensions Protection (w=0, h=0)', w: 0, h: 0, scale: 1.0, template: 'watermark_mint_film' },
  { name: 'Zero Dimensions Protection (w=0, h=0)', w: 0, h: 0, scale: 1.0, template: 'watermark_travel_postcard' }
];

for (const bc of boundaryCases) {
  const testName = `[Boundary] ${bc.template} | ${bc.name}`;
  runAdversarialCase(testName, () => {
    const rawState = {
      templateId: bc.template,
      widthRatio: 0.08,
      cornerRadiusRatio: 0,
      watermark: {
        showDevice: true,
        deviceModel: 'Hasselblad X2D 100C Earth Explorer Edition Limited Dual Lens Kit',
        showParams: true,
        paramsText: '24-70mm f/2.8 GM II  1/8000s  ISO 100  +1.7EV',
        showTime: true,
        timeText: '2026-09-11',
        showLogo: true,
        logo: 'none'
      }
    };
    const state = borderState.sanitizeBorderState(rawState);
    let geometry;
    if (bc.w === 0 && bc.h === 0) {
      geometry = {
        outputWidth: 0,
        outputHeight: 0,
        photoRect: { x: 0, y: 0, width: 0, height: 0 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
        shadowSpread: 0,
        decorations: [],
        templateId: bc.template,
        cornerRadius: 0
      };
    } else {
      geometry = borderResolver.resolveBorderGeometry({
        photoWidth: bc.w,
        photoHeight: bc.h,
        border: state
      });
    }
    return { geometry, state, scale: bc.scale };
  }, (logs) => {
    // 确保没有崩溃，没有 NaN
    for (const t of logs.texts) {
      if (isNaN(t.absX) || isNaN(t.absY) || isNaN(t.w)) {
        return `文本坐标出现 NaN: ${JSON.stringify(t)}`;
      }
    }
    for (const a of logs.arcs) {
      if (isNaN(a.x) || isNaN(a.y) || isNaN(a.r)) {
        return `圆弧坐标出现 NaN: ${JSON.stringify(a)}`;
      }
    }
    return null;
  });
}

// =============================================================================
// 总结与违规分析
// =============================================================================
console.log('\n================================================================');
console.log(`压力测试统计: ${totalTests} 项测试，通过: ${passedTests}，违规/失败: ${violations.length}`);
console.log('================================================================');

if (violations.length > 0) {
  console.log('\n发现违规项详情:');
  violations.forEach((v, idx) => {
    console.log(`\n[#${idx + 1}] ${v.testName}`);
    console.log(`    原因: ${v.reason}`);
  });
}

process.exit(violations.length > 0 ? 1 : 0);
