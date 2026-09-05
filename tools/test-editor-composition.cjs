// Host contract tests: actual ArkTS composition services, recording Canvas/ImageKit boundary.
// Does not validate device fonts, rasterization or album access.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const studio = process.env.DEVECO_STUDIO_HOME || path.join(process.env.ProgramFiles || 'C:/Program Files', 'Huawei/DevEco Studio');
const ts = require(path.join(studio, 'tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const cache = new Map();
const imageBackend = { source: undefined };
const nativeBackend = { loadPreset: async () => true, render: async source => new PixelMap(source.width, source.height) };
function load(relative) {
  const file = path.resolve(root, relative);
  if (file.endsWith(path.join('services', 'ImageRenderService.ets'))) {
    return { ImageRenderService: { createPreviewSource: async () => imageBackend.source, render: async () => imageBackend.source } };
  }
  if (file.endsWith(path.join('filter', 'FilterNativeBridge.ets'))) {
    return { FilterNativeBridge: nativeBackend };
  }
  if (cache.has(file)) return cache.get(file).exports;
  const module = { exports: {} };
  cache.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    fileName: file.replace(/\.ets$/, '.ts'),
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  }).outputText;
  const requireLocal = id => {
    if (id === '@ohos/hypium') return testApi;
    if (id === '@kit.ArkUI') return { LengthMetricsUnit: global.LengthMetricsUnit };
    if (!id.startsWith('.')) throw new Error('Unexpected platform dependency: ' + id);
    return load(path.resolve(path.dirname(file), id + '.ets'));
  };
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', { filename: file })(requireLocal, module, module.exports);
  return module.exports;
}
class PixelMap {
  constructor(width, height, calls = []) { this.width = width; this.height = height; this.calls = calls; this.released = false; }
  async getImageInfo() { return { size: { width: this.width, height: this.height } }; }
  release() { assert.equal(this.released, false, 'double release'); this.released = true; }
}
global.LengthMetricsUnit = { PX: 1 };
global.RenderingContextSettings = class {};
const allocated = [];
let failReadback = false;
global.OffscreenCanvasRenderingContext2D = class {
  constructor(w, h, settings, unit) {
    assert.equal(unit, 1, 'export must explicitly use pixels, not display-density vp');
    this.width = w; this.height = h; this.calls = []; this.globalAlpha = 1;
  }
  drawImage(pm, ...args) { this.calls.push({ op: 'image', pm, args }); }
  fillRect(...args) { this.calls.push({ op: 'rect', color: this.fillStyle, args }); }
  clearRect() {}
  save() {}
  restore() {}
  beginPath() {}
  rect() {}
  clip() {}
  translate(...args) { this.calls.push({ op: 'translate', args }); }
  rotate(angle) { this.calls.push({ op: 'rotate', angle }); }
  fillText(text, x, y) { this.calls.push({ op: 'text', text, x, y, alpha: this.globalAlpha, font: this.font }); }
  getPixelMap(x, y, w, h) {
    if (failReadback) throw new Error('Canvas readback unavailable');
    const result = new PixelMap(w, h, this.calls);
    allocated.push(result);
    return result;
  }
};
const { BorderCompositionService } = load('entry/src/main/ets/services/BorderCompositionService.ets');
const { TextCompositionService } = load('entry/src/main/ets/services/TextCompositionService.ets');
let passed = 0, failed = 0;
const suiteTests = [];
const testApi = {
  describe: (_name, body) => body(),
  it: (name, _level, body) => suiteTests.push({ name, body }),
  expect: value => ({
    assertEqual: expected => assert.deepEqual(value, expected),
    assertTrue: () => assert.equal(value, true),
    assertFalse: () => assert.equal(value, false),
    assertUndefined: () => assert.equal(value, undefined)
  })
};
async function test(name, body) {
  try { await body(); passed++; console.log('PASS ' + name); }
  catch (error) { failed++; console.error('FAIL ' + name + '\n' + error.stack); }
}
(async () => {
  await test('export actually expands a polaroid and uses the shared preview photo offset', async () => {
    const base = new PixelMap(1000, 1000);
    const out = await BorderCompositionService.render(base,
      { templateId: 'polaroid', widthRatio: .1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 });
    assert.notEqual(out, base);
    assert.deepEqual([out.width, out.height], [1100, 1300]);
    assert.deepEqual(out.calls.find(c => c.op === 'image').args, [50, 50, 1000, 1000]);
    assert.equal(base.released, false, 'caller owns the input');
  });
  await test('film exports actual sprocket marks outside the photo, not just a plain border', async () => {
    const out = await BorderCompositionService.render(new PixelMap(1000, 800),
      { templateId: 'film_negative', widthRatio: .1, colorArgb: 0xFF1A1A1A, shadowStrength: 0 });
    const rects = out.calls.filter(c => c.op === 'rect');
    assert.ok(rects.length > 8);
    assert.ok(out.calls.some(c => c.op === 'text' && c.text.includes('01')));
  });
  await test('export draws multiline text at its saved center and rotation', async () => {
    const base = new PixelMap(1000, 800);
    const layer = { id: 'a', content: '甲\r\n乙', fontKey: 'system_sans', colorArgb: 0xFF241918,
      fontSizeRatio: .06, centerX: .25, centerY: .75, rotationDeg: 90, opacity: .6 };
    const out = await TextCompositionService.render(base, [layer]);
    assert.notEqual(out, base);
    assert.deepEqual([out.width, out.height], [1000, 800]);
    assert.deepEqual(out.calls.find(c => c.op === 'translate').args, [250, 600]);
    assert.equal(out.calls.find(c => c.op === 'rotate').angle, Math.PI / 2);
    const lines = out.calls.filter(c => c.op === 'text');
    assert.deepEqual(lines.map(c => c.text), ['甲', '乙']);
    assert.deepEqual(lines.map(c => c.y), [-37.5, 37.5]);
    assert.equal(lines[0].alpha, .6);
    assert.equal(base.released, false);
  });
  await test('empty text and none border do not allocate or release the source', async () => {
    const base = new PixelMap(1000, 800);
    assert.equal(await TextCompositionService.render(base, []), base);
    assert.equal(await BorderCompositionService.render(base,
      { templateId: 'none', widthRatio: 0, colorArgb: 0xFFFFFFFF, shadowStrength: 0 }), base);
    assert.equal(base.released, false);
  });
  await test('thumbnail results are published before the next preset and a missing LUT does not abort the strip', async () => {
    const { renderThumbnailBatch } = load('entry/src/main/ets/features/editor/filter/ThumbnailBatch.ets');
    const seen = [], failedIds = [];
    const presets = ['first', 'missing', 'last'].map(id => ({ id, name: id, version: 1, defaultStrength: 1 }));
    await renderThumbnailBatch(presets, async preset => {
      if (preset.id === 'missing') {
        assert.deepEqual(seen, ['first']);
        throw new Error('deleted resource');
      }
      return preset.id;
    }, (preset, result) => { assert.equal(preset.id, result); seen.push(result); },
    preset => failedIds.push(preset.id), () => true);
    assert.deepEqual(seen, ['first', 'last']);
    assert.deepEqual(failedIds, ['missing']);
  });
  await test('switching from a borrowed original only releases generated previews', async () => {
    const { OwnedRenderResult } = load('entry/src/main/ets/services/PreviewPipeline.ets');
    const released = [];
    const owner = new OwnedRenderResult(value => released.push(value));
    owner.replace('filter');
    owner.replace('source', 'source');
    owner.replace('next-filter', 'source');
    assert.deepEqual(released, ['filter']);
    owner.clear();
    assert.deepEqual(released, ['filter', 'next-filter']);
  });
  await test('leaving the page while a thumbnail renders does not release its input until native work finishes', async () => {
    const { ThumbnailPipeline } = load('entry/src/main/ets/services/ThumbnailPipeline.ets');
    const source = new PixelMap(256, 200);
    imageBackend.source = source;
    const pipeline = new ThumbnailPipeline();
    await pipeline.loadSource('source', 'session');
    let finish;
    let started;
    const startedPromise = new Promise(resolve => { started = resolve; });
    nativeBackend.render = async input => {
      assert.equal(input, source);
      started();
      return new Promise(resolve => { finish = resolve; });
    };
    const pending = pipeline.renderPreset({}, { id: 'test', name: 'test', version: 1, defaultStrength: 1 });
    await startedPromise;
    pipeline.clear();
    assert.equal(source.released, false);
    const result = new PixelMap(256, 200);
    finish(result);
    assert.equal(await pending, undefined);
    assert.equal(source.released, true);
    assert.equal(result.released, true);
  });
  await test('composition releases its intermediate images but keeps the final result alive', async () => {
    const { EditorCompositionService } = load('entry/src/main/ets/services/EditorCompositionService.ets');
    const base = new PixelMap(1000, 800);
    imageBackend.source = base;
    const count = allocated.length;
    const snapshot = { schemaVersion: 1, filter: { filterId: 'original', strength: 0 },
      textLayers: [{ id: 'a', content: '字', fontKey: 'system_sans', colorArgb: 0xFF241918,
        fontSizeRatio: .06, centerX: .5, centerY: .5, rotationDeg: 0, opacity: 1 }],
      border: { templateId: 'paper_white', widthRatio: .1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 } };
    const result = await EditorCompositionService.render('source', {}, snapshot, {});
    assert.equal(base.released, true);
    assert.equal(allocated[count].released, true, 'intermediate text image');
    assert.equal(result.pixelMap.released, false, 'caller owns final image');
    assert.deepEqual([result.width, result.height], [1160, 960]);
  });
  await test('a failed border readback rejects instead of pretending the unmodified photo is exported', async () => {
    const base = new PixelMap(1000, 800);
    failReadback = true;
    try {
      await assert.rejects(() => BorderCompositionService.render(base,
        { templateId: 'paper_white', widthRatio: .1, colorArgb: 0xFFFFFFFF, shadowStrength: 0 }), /readback/);
      assert.equal(base.released, false);
    } finally { failReadback = false; }
  });
  // Existing suites stay unchanged; these checks execute their real pure behavior.
  for (const name of ['EditorCompositionModels', 'PreviewPipeline']) {
    load('entry/src/test/' + name + '.test.ets').default();
  }
  for (const entry of suiteTests) await test(entry.name, entry.body);
  console.log(`Host composition contracts: ${passed} passed, ${failed} failed; no device raster validation`);
  process.exitCode = failed ? 1 : 0;
})();
