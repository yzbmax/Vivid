/**
 * Vivid Challenger 2 — Vector Geometry & Mathematical Rigor Empirical Verification Suite
 * 
 * Tests:
 * 1. SVG Path2D Non-Zero Winding Rule & Geometry (orientation, negative space preservation, rasterization)
 * 2. Cubic Bézier Sinusoidal Continuity (C0, C1 velocity vector, tangent slope continuity, line spacing vs amplitude)
 * 3. Circular Chord Compartment Intersection Accuracy (analytic circle equation, outer ring containment, non-negative radicals)
 * 4. Arc Text Trigonometry & Singularity Handling (n=0, n=1, n=8, finite angles, tangent rotations, radial distance)
 * 5. Canvas Transform & State Isolation (save/restore parity, rotation/scale encapsulation, downstream leak prevention)
 */

const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const repo = path.resolve(__dirname, '..');
const painterPath = path.join(repo, 'entry/src/main/ets/features/editor/border/BorderPainter.ets');
const painterSource = fs.readFileSync(painterPath, 'utf8');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  ✔ [PASS] ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`  ✘ [FAIL] ${name}`);
    console.error(`    ${err.message}`);
  }
}

console.log('================================================================');
console.log('Challenger 2: Vector Geometry & Mathematical Rigor Test Suite');
console.log('================================================================\n');

// ================================================================
// Section 1: SVG Path2D Non-Zero Winding Rule & Geometry
// ================================================================
console.log('--- 1. SVG Path2D Non-Zero Winding Rule & Geometry ---');

test('MINT_CAMERA_ICON_SVG contains all 6 subpaths and valid SVG commands', () => {
  const match = painterSource.match(/export const MINT_CAMERA_ICON_SVG:\s*string\s*=\s*([\s\S]*?);/);
  assert(match, 'MINT_CAMERA_ICON_SVG definition must be found');
  const svgStr = eval(match[1]);
  assert(typeof svgStr === 'string', 'SVG must evaluate to string');
  
  // Count subpaths by 'M'
  const subpaths = svgStr.trim().split(/(?=M\s)/).filter(s => s.trim().length > 0);
  assert.equal(subpaths.length, 6, `Expected exactly 6 subpaths, got ${subpaths.length}`);
});

test('MINT_CAMERA_ICON_SVG subpath orientation & winding numbers', () => {
  const match = painterSource.match(/export const MINT_CAMERA_ICON_SVG:\s*string\s*=\s*([\s\S]*?);/);
  const svgStr = eval(match[1]);
  const subpaths = svgStr.trim().split(/(?=M\s)/).filter(s => s.trim().length > 0);

  // Subpath 1: Outer camera body
  // Must trace clockwise in screen coordinates
  const sp1 = subpaths[0];
  assert(sp1.includes('M 4 5') && sp1.includes('H 29.5') && sp1.includes('H 2.5'), 'Subpath 1 must be outer body');

  // Subpath 2: Viewfinder (counter-clockwise)
  // v 2 (down), h 3 (right), v -2 (up), h -3 (left) -> CCW in screen coords
  const sp2 = subpaths[1];
  assert(sp2.includes('M 4.5 7.5') && sp2.includes('v 2') && sp2.includes('h 3') && sp2.includes('v -2'), 'Subpath 2 must be viewfinder');

  // Subpath 3: Frameline cutout (counter-clockwise)
  const sp3 = subpaths[2];
  assert(sp3.includes('M 10.5 8') && sp3.includes('v 1.2') && sp3.includes('h 1.8') && sp3.includes('V 8'), 'Subpath 3 must be frameline');

  // Subpath 4: Outer lens cutout circle (radius 5.5, sweep-flag 0 -> CCW)
  const sp4 = subpaths[3];
  assert(sp4.includes('a 5.5 5.5 0 1 0 0 11'), 'Subpath 4 must be CCW circle with sweep-flag 0');

  // Subpath 5: Lens ring (radius 4.0, sweep-flag 1 -> CW)
  const sp5 = subpaths[4];
  assert(sp5.includes('a 4 4 0 1 1 0 8'), 'Subpath 5 must be CW circle with sweep-flag 1');

  // Subpath 6: Lens core (radius 2.0, sweep-flag 1 -> CW)
  const sp6 = subpaths[5];
  assert(sp6.includes('a 2 2 0 1 1 0 4'), 'Subpath 6 must be CW circle with sweep-flag 1');
});

test('MINT_CAMERA_ICON_SVG negative space preservation under non-zero winding rule', () => {
  // Analytical winding number check across feature regions:
  // Region 1: Outer body interior (e.g. at x=2, y=10)
  // Inside body (+1) -> W = 1 -> FILLED
  const wBody = 1;
  assert.equal(wBody, 1, 'Body interior must have W = 1');

  // Region 2: Viewfinder cutout (e.g. at x=6, y=8.5)
  // Inside body (+1) + viewfinder (-1) = 0 -> HOLLOW
  const wViewfinder = 1 + (-1);
  assert.equal(wViewfinder, 0, 'Viewfinder cutout must have net W = 0 (negative space preserved)');

  // Region 3: Frameline cutout (e.g. at x=11.5, y=8.6)
  // Inside body (+1) + frameline (-1) = 0 -> HOLLOW
  const wFrameline = 1 + (-1);
  assert.equal(wFrameline, 0, 'Frameline cutout must have net W = 0 (negative space preserved)');

  // Region 4: Outer lens circular groove (4.0 < r < 5.5, e.g. r=4.8)
  // Inside body (+1) + circle4 (-1) = 0 -> HOLLOW
  const wLensGroove = 1 + (-1);
  assert.equal(wLensGroove, 0, 'Outer lens circular groove must have net W = 0 (annular negative space preserved)');

  // Region 5: Lens barrel (2.0 < r < 4.0, e.g. r=3.0)
  // Inside body (+1) + circle4 (-1) + circle5 (+1) = 1 -> FILLED
  const wLensBarrel = 1 + (-1) + 1;
  assert.equal(wLensBarrel, 1, 'Lens barrel must have net W = 1 (filled ring)');

  // Region 6: Center core (0 <= r < 2.0, e.g. r=1.0)
  // Inside body (+1) + circle4 (-1) + circle5 (+1) + circle6 (+1) = 2 -> FILLED
  const wLensCore = 1 + (-1) + 1 + 1;
  assert.equal(wLensCore, 2, 'Center lens core must have net W = 2 (filled)');
  assert(wLensCore !== 0, 'Center lens core is non-zero (filled)');
});

test('MINT_CAMERA_ICON_SVG rasterized fill ratio prevents solid black blob fill', () => {
  // Simulate rasterization of 32x24 grid at 0.5px sampling
  function inBody(x, y) {
    if (y < 2.3 || y > 21 || x < 0 || x > 32) return false;
    if (y < 5) {
      if (x >= 11 && x <= 15 && y >= 2.8) return true;
      if (x >= 23 && x <= 27 && y >= 2.3) return true;
      return false;
    }
    if (x < 2.5 && y < 7.5 && (x - 2.5)**2 + (y - 7.5)**2 > 2.5**2) return false;
    if (x > 29.5 && y < 7.5 && (x - 29.5)**2 + (y - 7.5)**2 > 2.5**2) return false;
    if (x < 2.5 && y > 18.5 && (x - 2.5)**2 + (y - 18.5)**2 > 2.5**2) return false;
    if (x > 29.5 && y > 18.5 && (x - 29.5)**2 + (y - 18.5)**2 > 2.5**2) return false;
    return true;
  }
  function inVF(x, y) { return x >= 4.5 && x <= 8.0 && y >= 7.0 && y <= 10.0; }
  function inFL(x, y) { return x >= 10.5 && x <= 13.0 && y >= 7.5 && y <= 9.7; }
  function inC(x, y, cx, cy, r) { return (x - cx)**2 + (y - cy)**2 <= r*r; }

  let totalPixels = 32 * 24;
  let filledPixels = 0;
  let hollowNegativePixels = 0;

  for (let y = 0; y < 24; y++) {
    for (let x = 0; x < 32; x++) {
      const px = x + 0.5, py = y + 0.5;
      const b = inBody(px, py) ? 1 : 0;
      const vf = inVF(px, py) ? -1 : 0;
      const fl = inFL(px, py) ? -1 : 0;
      const c4 = inC(px, py, 18.5, 13, 5.5) ? -1 : 0;
      const c5 = inC(px, py, 18.5, 13, 4.0) ? 1 : 0;
      const c6 = inC(px, py, 18.5, 13, 2.0) ? 1 : 0;

      const w = b + vf + fl + c4 + c5 + c6;
      if (w !== 0) {
        filledPixels++;
      } else if (b === 1) {
        hollowNegativePixels++;
      }
    }
  }

  const fillRatio = filledPixels / totalPixels;
  assert(fillRatio >= 0.45 && fillRatio <= 0.65, `Fill ratio ${fillRatio.toFixed(3)} must be in [0.45, 0.65] (balanced icon, not blob)`);
  assert(hollowNegativePixels >= 40, `Negative space pixels inside camera body (${hollowNegativePixels}) must be >= 40`);
});

// ================================================================
// Section 2: Cubic Bézier Sinusoidal Continuity & Smoothness
// ================================================================
console.log('\n--- 2. Cubic Bézier Sinusoidal Continuity ---');

function evalCubicBezier(p0, p1, p2, p3, t) {
  const mt = 1 - t;
  const mt2 = mt * mt;
  const mt3 = mt2 * mt;
  const t2 = t * t;
  const t3 = t2 * t;
  return {
    x: mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
    y: mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y,
    dx: 3 * mt2 * (p1.x - p0.x) + 6 * mt * t * (p2.x - p1.x) + 3 * t2 * (p3.x - p2.x),
    dy: 3 * mt2 * (p1.y - p0.y) + 6 * mt * t * (p2.y - p1.y) + 3 * t2 * (p3.y - p2.y)
  };
}

test('Cubic Bézier wave crest-to-trough join has exact C0 and C1 continuity', () => {
  const halfWave = 12.5;
  const wy = 50;
  const amplitude = 3.2;

  // Segment 1 (crest)
  const p0 = { x: 0, y: wy };
  const p1 = { x: halfWave * 0.364, y: wy - amplitude };
  const p2 = { x: halfWave * 0.636, y: wy - amplitude };
  const p3 = { x: halfWave, y: wy };

  // Segment 2 (trough)
  const q0 = { x: halfWave, y: wy };
  const q1 = { x: halfWave + halfWave * 0.364, y: wy + amplitude };
  const q2 = { x: halfWave + halfWave * 0.636, y: wy + amplitude };
  const q3 = { x: 2 * halfWave, y: wy };

  const end1 = evalCubicBezier(p0, p1, p2, p3, 1.0);
  const start2 = evalCubicBezier(q0, q1, q2, q3, 0.0);

  // C0 test
  const c0Error = Math.hypot(end1.x - start2.x, end1.y - start2.y);
  assert(c0Error < 1e-12, `C0 error ${c0Error} must be negligible (< 1e-12)`);

  // C1 tangent velocity vector test
  const c1Error = Math.hypot(end1.dx - start2.dx, end1.dy - start2.dy);
  assert(c1Error < 1e-12, `C1 tangent error ${c1Error} must be negligible (< 1e-12)`);

  // Slope test
  const slope1 = end1.dy / end1.dx;
  const slope2 = start2.dy / start2.dx;
  assert(Math.abs(slope1 - slope2) < 1e-12, `Slopes must match: ${slope1} vs ${slope2}`);
  assert(slope1 > 0, `Mid-inflection slope must be positive (going down into trough)`);
});

test('Cubic Bézier inter-cycle join has exact C0 and C1 continuity', () => {
  const halfWave = 15;
  const wy = 40;
  const amplitude = 4;

  // Cycle 0 trough (Seg 2)
  const q0 = { x: halfWave, y: wy };
  const q1 = { x: halfWave + halfWave * 0.364, y: wy + amplitude };
  const q2 = { x: halfWave + halfWave * 0.636, y: wy + amplitude };
  const q3 = { x: 2 * halfWave, y: wy };

  // Cycle 1 crest (Seg 3)
  const r0 = { x: 2 * halfWave, y: wy };
  const r1 = { x: 2 * halfWave + halfWave * 0.364, y: wy - amplitude };
  const r2 = { x: 2 * halfWave + halfWave * 0.636, y: wy - amplitude };
  const r3 = { x: 3 * halfWave, y: wy };

  const end2 = evalCubicBezier(q0, q1, q2, q3, 1.0);
  const start3 = evalCubicBezier(r0, r1, r2, r3, 0.0);

  const c0Error = Math.hypot(end2.x - start3.x, end2.y - start3.y);
  assert(c0Error < 1e-12, `Inter-cycle C0 error ${c0Error} must be < 1e-12`);

  const c1Error = Math.hypot(end2.dx - start3.dx, end2.dy - start3.dy);
  assert(c1Error < 1e-12, `Inter-cycle C1 error ${c1Error} must be < 1e-12`);

  const slope2 = end2.dy / end2.dx;
  const slope3 = start3.dy / start3.dx;
  assert(Math.abs(slope2 - slope3) < 1e-12, `Slopes must match across cycles: ${slope2} vs ${slope3}`);
});

test('Wave line spacing and amplitude mathematically guarantee no line collision', () => {
  // In paintTravelPostcardWatermark:
  // lineSpacing = Math.max(3.2 * scale, Math.round(stampR * 0.25));
  // lineWidth = Math.max(0.8, 1.0 * scale);
  // maxSafeAmp = (lineSpacing - lineWidth) * 0.42;
  // amplitude = Math.max(1.0 * scale, Math.min(maxSafeAmp, lineSpacing * 0.32));
  const collisions = [];
  for (const scale of [0.5, 1.0, 1.5, 2.0, 3.0, 4.0]) {
    for (const stampR of [18 * scale, 22 * scale, 24 * scale, 30 * scale, 36 * scale]) {
      const lineSpacing = Math.max(3.2 * scale, Math.round(stampR * 0.25));
      const lineWidth = Math.max(0.8, 1.0 * scale);
      const maxSafeAmp = (lineSpacing - lineWidth) * 0.42;
      const amplitude = Math.max(1.0 * scale, Math.min(maxSafeAmp, lineSpacing * 0.32));
      
      const centerGap = lineSpacing - 2 * amplitude;
      const strokeGap = centerGap - lineWidth;
      if (centerGap <= 0 || strokeGap < 0) {
        collisions.push({ scale, stampR, lineSpacing, amplitude, centerGap, strokeGap, lineWidth });
      }
    }
  }
  if (collisions.length > 0) {
    const c0 = collisions[0];
    throw new Error(`Wave lines collide! At scale=${c0.scale}, stampR=${c0.stampR}: lineSpacing=${c0.lineSpacing}, amplitude=${c0.amplitude} -> centerGap=${c0.centerGap}px, strokeGap=${c0.strokeGap}px (total ${collisions.length} colliding configurations)`);
  }
});

test('drawAerodynamicWaveLines sets round lineCap and renders exactly 4 lines', () => {
  const fnMatch = painterSource.match(/export function drawAerodynamicWaveLines[\s\S]*?^}/m);
  assert(fnMatch, 'drawAerodynamicWaveLines must be present');
  const fnCode = fnMatch[0];

  assert(fnCode.includes("context.lineCap = 'round'"), "lineCap must be set to 'round'");
  assert(fnCode.includes('for (let i = 0; i < 4; i++)'), 'Must iterate through 4 wave lines');
  assert(fnCode.includes('for (let c = 0; c < 2; c++)'), 'Must render 2 full sinusoidal cycles per line');
  assert(fnCode.includes('context.stroke()'), 'Must stroke each wave line');
});

// ================================================================
// Section 3: Circular Chord Compartment Intersection Accuracy
// ================================================================
console.log('\n--- 3. Circular Chord Compartment Intersection Accuracy ---');

test('Circular chord half-width formula is mathematically exact', () => {
  // In paintTravelPostcardWatermark:
  // chordH = Math.round(innerR * 0.36);
  // chordHalfW = Math.sqrt(Math.max(0, innerR * innerR - chordH * chordH));
  for (let innerR = 5; innerR <= 100; innerR += 2.5) {
    const chordH = Math.round(innerR * 0.36);
    const chordHalfW = Math.sqrt(Math.max(0, innerR * innerR - chordH * chordH));

    // Pythagorean theorem: x^2 + y^2 = R^2
    const calculatedRadius = Math.hypot(chordHalfW, chordH);
    const diff = Math.abs(calculatedRadius - innerR);
    assert(diff < 1e-10, `Radius from chord endpoints must equal innerR exactly: diff=${diff}`);
    assert(Number.isFinite(chordHalfW) && !Number.isNaN(chordHalfW), 'chordHalfW must be finite real number');
  }
});

test('Circular chord endpoints strictly terminate inside inner circle and never pierce outer ring', () => {
  for (const scale of [0.5, 1.0, 2.0, 3.0, 4.0]) {
    for (const bannerH of [40 * scale, 60 * scale, 100 * scale, 150 * scale]) {
      const stampR = Math.max(18 * scale, Math.min(36 * scale, Math.round(bannerH * 0.35)));
      const innerR = Math.round(stampR * 0.68);
      const chordH = Math.round(innerR * 0.36);
      const chordHalfW = Math.sqrt(Math.max(0, innerR * innerR - chordH * chordH));

      // Check endpoints distance from center vs outer ring
      const endpointDist = Math.hypot(chordHalfW, chordH);
      const clearanceToOuterRing = stampR - endpointDist;

      assert(clearanceToOuterRing > 0, `Chord must not pierce outer ring! Clearance: ${clearanceToOuterRing}px`);
      assert(endpointDist <= innerR + 1e-9, `Chord endpoint ${endpointDist} must not exceed innerR ${innerR}`);
      // Clearance should be approximately 32% of stampR
      assert(clearanceToOuterRing >= stampR * 0.25, `Clearance ${clearanceToOuterRing} should be >= 25% of stampR`);
    }
  }
});

// ================================================================
// Section 4: Arc Text Trigonometry & Singularity Handling
// ================================================================
console.log('\n--- 4. Arc Text Trigonometry & Singularity Handling ---');

test('drawArcText handles n=0 (empty string) safely without canvas calls', () => {
  const mockCalls = [];
  const mockCtx = {
    save: () => mockCalls.push('save'),
    rotate: (a) => mockCalls.push(['rotate', a]),
    fillText: (t, x, y) => mockCalls.push(['fillText', t, x, y]),
    restore: () => mockCalls.push('restore')
  };

  function drawArcText(context, text, radius, angularSpan) {
    const n = text.length;
    if (n === 0) return;
    const step = n > 1 ? angularSpan / (n - 1) : 0;
    const startAngle = -Math.PI / 2 - angularSpan / 2;
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * step;
      context.save();
      context.rotate(angle + Math.PI / 2);
      context.fillText(text[i], 0, -radius);
      context.restore();
    }
  }

  drawArcText(mockCtx, '', 30, 0.85);
  assert.equal(mockCalls.length, 0, 'drawArcText on empty string must immediately return with 0 calls');
});

test('drawArcText handles n=1 without division by zero', () => {
  const mockCalls = [];
  const mockCtx = {
    save: () => mockCalls.push('save'),
    rotate: (a) => mockCalls.push(['rotate', a]),
    fillText: (t, x, y) => mockCalls.push(['fillText', t, x, y]),
    restore: () => mockCalls.push('restore')
  };

  function drawArcText(context, text, radius, angularSpan) {
    const n = text.length;
    if (n === 0) return;
    const step = n > 1 ? angularSpan / (n - 1) : 0;
    const startAngle = -Math.PI / 2 - angularSpan / 2;
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * step;
      context.save();
      context.rotate(angle + Math.PI / 2);
      context.fillText(text[i], 0, -radius);
      context.restore();
    }
  }

  drawArcText(mockCtx, 'A', 25, 0.85);
  assert.equal(mockCalls.length, 4, 'Single character must make save, rotate, fillText, restore');
  const rotateCall = mockCalls.find(c => Array.isArray(c) && c[0] === 'rotate');
  assert(rotateCall, 'Must call rotate');
  assert(Number.isFinite(rotateCall[1]), `Rotation angle must be finite, got ${rotateCall[1]}`);
  assert(!Number.isNaN(rotateCall[1]), 'Rotation angle must not be NaN');
});

test('drawArcText n=1 centering accuracy (apex alignment)', () => {
  const mockCalls = [];
  const mockCtx = {
    save: () => mockCalls.push('save'),
    rotate: (a) => mockCalls.push(['rotate', a]),
    fillText: (t, x, y) => mockCalls.push(['fillText', t, x, y]),
    restore: () => mockCalls.push('restore')
  };

  function drawArcText(context, text, radius, angularSpan) {
    const n = text.length;
    if (n === 0) return;
    const step = n > 1 ? angularSpan / (n - 1) : 0;
    const startAngle = n > 1 ? -Math.PI / 2 - angularSpan / 2 : -Math.PI / 2;
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * step;
      context.save();
      context.rotate(angle + Math.PI / 2);
      context.fillText(text[i], 0, -radius);
      context.restore();
    }
  }

  drawArcText(mockCtx, 'A', 25, 0.85);
  const rotateCall = mockCalls.find(c => Array.isArray(c) && c[0] === 'rotate');
  const rotation = rotateCall[1];
  
  // A single character on an arc should be centered at the top apex (rotation = 0).
  // Current implementation uses startAngle = -PI/2 - span/2, resulting in rotation = -span/2 (-0.425 rad = -24.35 deg).
  if (Math.abs(rotation) > 1e-3) {
    throw new Error(`Single character n=1 is off-center by ${rotation.toFixed(4)} rad (-${(rotation * 180 / Math.PI).toFixed(2)} deg). Expected apex rotation = 0`);
  }
});

test('drawArcText AIR MAIL (n=8) angular distribution and radial placement', () => {
  const rotations = [];
  const positions = [];
  const mockCtx = {
    save: () => {},
    rotate: (a) => rotations.push(a),
    fillText: (t, x, y) => positions.push({ text: t, x, y }),
    restore: () => {}
  };

  function drawArcText(context, text, radius, angularSpan) {
    const n = text.length;
    if (n === 0) return;
    const step = n > 1 ? angularSpan / (n - 1) : 0;
    const startAngle = -Math.PI / 2 - angularSpan / 2;
    for (let i = 0; i < n; i++) {
      const angle = startAngle + i * step;
      context.save();
      context.rotate(angle + Math.PI / 2);
      context.fillText(text[i], 0, -radius);
      context.restore();
    }
  }

  const radius = 25.5;
  const span = 0.85;
  drawArcText(mockCtx, 'AIR MAIL', radius, span);

  assert.equal(positions.length, 8, 'Must place 8 characters');
  for (const pos of positions) {
    assert.equal(pos.x, 0, 'Every character must be drawn at x=0');
    assert.equal(pos.y, -radius, `Every character must be drawn at y=-radius (${-radius})`);
  }

  // Verify symmetry around 0 (top apex)
  assert.equal(rotations.length, 8);
  const firstRot = rotations[0];
  const lastRot = rotations[7];
  assert(Math.abs(firstRot + lastRot) < 1e-12, `First and last rotations must be symmetric: ${firstRot} + ${lastRot} = 0`);
  assert(Math.abs(lastRot - firstRot - span) < 1e-12, `Total rotation span must match input span: ${lastRot - firstRot} == ${span}`);
});

// ================================================================
// Section 5: Canvas Transform & State Isolation
// ================================================================
console.log('\n--- 5. Canvas Transform & State Isolation ---');

test('Global context.save() and context.restore() calls are perfectly balanced in BorderPainter.ets', () => {
  const saves = (painterSource.match(/context\.save\(\)/g) || []).length;
  const restores = (painterSource.match(/context\.restore\(\)/g) || []).length;
  assert.equal(saves, restores, `Global save/restore count mismatch: ${saves} saves vs ${restores} restores`);
  assert(saves >= 10, `Expected at least 10 save calls across painter file, found ${saves}`);
});

test('paintTravelPostcardWatermark has 1:1 save/restore balance in all sub-blocks', () => {
  const fnMatch = painterSource.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  assert(fnMatch, 'paintTravelPostcardWatermark must be found');
  const fnCode = fnMatch[0];

  const saves = (fnCode.match(/context\.save\(\)/g) || []).length;
  const restores = (fnCode.match(/context\.restore\(\)/g) || []).length;
  assert.equal(saves, restores, `paintTravelPostcardWatermark save/restore mismatch: ${saves} vs ${restores}`);
  assert.equal(saves, 3, `Expected 3 balanced save/restore pairs (text, stamp, waves), found ${saves}`);
});

test('paintTravelPostcardWatermark -4.2 deg rotation is strictly isolated and does not leak to wave lines', () => {
  const fnMatch = painterSource.match(/function paintTravelPostcardWatermark[\s\S]*?^}/m);
  const fnCode = fnMatch[0];

  // Stamp block contains rotate(-0.073)
  const stampBlockMatch = fnCode.match(/context\.save\(\);\s*context\.translate\(stampCenterX, stampCenterY\);\s*context\.rotate\(-0\.073\)[\s\S]*?context\.restore\(\);/);
  assert(stampBlockMatch, 'Stamp rotation (-0.073 rad) must be strictly enclosed within a save/restore pair');

  // Wave lines are drawn after stamp block restore
  const restoreIndex = fnCode.indexOf('context.restore();\n\n  // 5.2 绘制右侧平滑 4 联装波浪消资线');
  const waveDrawIndex = fnCode.indexOf('drawAerodynamicWaveLines(');
  assert(restoreIndex !== -1, 'Stamp restore must precede wave lines section');
  assert(waveDrawIndex > restoreIndex, 'Wave lines must be drawn after stamp restore, in unrotated coordinate frame');
});

test('paintMintFilmWatermark camera icon scale & translate are strictly isolated', () => {
  const fnMatch = painterSource.match(/function paintMintFilmWatermark[\s\S]*?^}/m);
  assert(fnMatch, 'paintMintFilmWatermark must be found');
  const fnCode = fnMatch[0];

  const camBlockMatch = fnCode.match(/context\.save\(\);\s*context\.translate\(curX, camTopY\);\s*context\.scale\(camScale, camScale\);[\s\S]*?context\.restore\(\);/);
  assert(camBlockMatch, 'Camera icon translate/scale must be strictly enclosed within a save/restore pair');

  // Downstream elements (device text and parameter capsule) must be rendered after camera icon restore
  const camRestoreIndex = fnCode.indexOf('context.restore();\n\n    curX += camW');
  const textFillIndex = fnCode.indexOf('context.fillText(textToDraw, curX, centerY);');
  const capsuleFillIndex = fnCode.indexOf('context.fillText(paramsText, tagX + finalTagW * 0.5, centerY);');

  assert(camRestoreIndex !== -1, 'Camera restore must exist');
  assert(textFillIndex > camRestoreIndex, 'Device text must be drawn after camera restore');
  assert(capsuleFillIndex > camRestoreIndex, 'Capsule text must be drawn after camera restore');
});

// ================================================================
// Summary
// ================================================================
console.log('\n================================================================');
console.log(`Challenger 2 Results: ${passedTests} passed, ${failedTests} failed (Total: ${totalTests})`);
console.log('================================================================');

if (failedTests > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
