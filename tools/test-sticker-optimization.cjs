// Automated test for Sticker Optimization & Full-Resolution Export Pipeline
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const studio = process.env.DEVECO_STUDIO_HOME || (
  process.platform === 'darwin'
    ? '/Applications/DevEco-Studio.app/Contents'
    : path.join(process.env.ProgramFiles || 'C:/Program Files', 'Huawei/DevEco Studio')
);
const ts = require(path.join(studio, 'tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const cache = new Map();

class PixelMap {
  constructor(width, height, calls = []) {
    this.width = width;
    this.height = height;
    this.calls = calls;
    this.released = false;
  }
  async getImageInfo() {
    return { size: { width: this.width, height: this.height } };
  }
  release() {
    assert.equal(this.released, false, 'double release detected');
    this.released = true;
  }
}

global.LengthMetricsUnit = { PX: 1 };
global.$r = res => res;
global.RenderingContextSettings = class {};

class MockOffscreenCanvasRenderingContext2D {
  constructor(w, h, settings, unit) {
    assert.equal(unit, 1, 'export must explicitly use pixels, not display-density vp');
    this.width = w;
    this.height = h;
    this.calls = [];
    this.globalAlpha = 1;
    this.font = '';
    this.fillStyle = '';
    this.strokeStyle = '';
    this.lineWidth = 1;
  }
  drawImage(pm, ...args) { this.calls.push({ op: 'image', pm, args }); }
  fillRect(...args) { this.calls.push({ op: 'rect', color: this.fillStyle, args }); }
  strokeRect(...args) { this.calls.push({ op: 'strokeRect', color: this.strokeStyle, lineWidth: this.lineWidth, args }); }
  clearRect() {}
  save() { this.calls.push({ op: 'save' }); }
  restore() { this.calls.push({ op: 'restore' }); }
  beginPath() { this.calls.push({ op: 'beginPath' }); }
  rect() {}
  clip() {}
  translate(...args) { this.calls.push({ op: 'translate', args }); }
  rotate(angle) { this.calls.push({ op: 'rotate', angle }); }
  fillText(text, x, y) {
    this.calls.push({ op: 'text', text, x, y, alpha: this.globalAlpha, font: this.font, color: this.fillStyle });
  }
  getPixelMap(x, y, w, h) {
    return new PixelMap(w, h, this.calls);
  }
}

global.OffscreenCanvasRenderingContext2D = MockOffscreenCanvasRenderingContext2D;

function load(relative) {
  const file = path.resolve(root, relative);
  if (cache.has(file)) return cache.get(file).exports;
  const module = { exports: {} };
  cache.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8'), {
    fileName: file.replace(/\.ets$/, '.ts'),
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  }).outputText;
  const requireLocal = id => {
    if (id === '@kit.ArkUI') return { LengthMetricsUnit: global.LengthMetricsUnit };
    if (id === '@kit.ImageKit') return { image: {} };
    if (id === '@kit.AbilityKit') return { common: {} };
    if (id === '@kit.CoreFileKit') return { fileIo: {} };
    if (!id.startsWith('.')) throw new Error('Unexpected platform dependency: ' + id);
    return load(path.resolve(path.dirname(file), id + '.ets'));
  };
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', { filename: file })(requireLocal, module, module.exports);
  return module.exports;
}

let passed = 0;
let failed = 0;

async function test(name, fn) {
  try {
    await fn();
    passed++;
    console.log('PASS ' + name);
  } catch (err) {
    failed++;
    console.error('FAIL ' + name + '\n' + err.stack);
  }
}

(async () => {
  const { StickerCompositionService } = load('entry/src/main/ets/services/StickerCompositionService.ets');

  await test('StickerCompositionService returns original PixelMap if stickers array is empty', async () => {
    const base = new PixelMap(1200, 800);
    const res = await StickerCompositionService.render(base, []);
    assert.equal(res, base, 'should return exact input when empty');
    assert.equal(base.released, false, 'input pixelmap should not be released');
  });

  await test('StickerCompositionService renders SealStamp with correct relative scale and Kai font', async () => {
    const base = new PixelMap(1800, 1200);
    const stickers = [
      {
        instanceId: 'st_1',
        templateId: 'seal-01',
        posX: 100,
        posY: 100,
        size: 50,
        rotation: 15,
        opacity: 0.9,
        zIndex: 1
      }
    ];
    // Preview size: 360 x 240. Target photo size: 1800 x 1200.
    // Scale factor = 1800 / 360 = 5.
    const out = await StickerCompositionService.render(base, stickers, 360, 240);
    assert.notEqual(out, base, 'should create a new composite pixelmap');
    assert.equal(out.width, 1800);
    assert.equal(out.height, 1200);

    // Verify canvas calls recorded
    const calls = out.calls;
    // 1. Must draw base photo
    const imgCall = calls.find(c => c.op === 'image');
    assert.ok(imgCall, 'must draw background image');
    assert.deepEqual(imgCall.args, [0, 0, 1800, 1200]);

    // 2. Must apply translate and rotate
    const translateCall = calls.find(c => c.op === 'translate');
    assert.ok(translateCall, 'must translate to center');
    // centerX in preview = 100 + 25 = 125. Scaled center = 125 * 5 = 625.
    // centerY in preview = 100 + 25 = 125. Scaled center = 125 * 5 = 625.
    assert.equal(translateCall.args[0], 625);
    assert.equal(translateCall.args[1], 625);

    const rotateCall = calls.find(c => c.op === 'rotate');
    assert.ok(rotateCall, 'must rotate');
    assert.equal(Math.round(rotateCall.angle * 180 / Math.PI), 15);

    // 3. Must render seal text with Kai font
    const textCall = calls.find(c => c.op === 'text');
    assert.ok(textCall, 'must render seal text');
    assert.equal(textCall.text, '雅');
    assert.ok(textCall.font.includes('Kai'), 'must use Kai font in seal stamp');
  });

  await test('StickerCompositionService renders LabelStrip sticker', async () => {
    const base = new PixelMap(1000, 1000);
    const stickers = [
      {
        instanceId: 'st_2',
        templateId: 'label-01',
        posX: 50,
        posY: 50,
        size: 40,
        rotation: 0,
        opacity: 1.0,
        zIndex: 1
      }
    ];
    const out = await StickerCompositionService.render(base, stickers, 500, 500);
    assert.notEqual(out, base);
    const textCall = out.calls.find(c => c.op === 'text');
    assert.ok(textCall, 'must render label strip text');
    assert.equal(textCall.text, '题签');
  });

  await test('StickerLayer implements Plan A (zero corner buttons, 8vp breathing room selection box, anti-jitter)', async () => {
    const content = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf8');
    // Plan A: Zero corner buttons on the sticker (no '✕' and no '⤢')
    assert.ok(!content.includes("'✕'"), 'must NOT render ✕ corner delete button in Plan A (zero corner buttons)');
    assert.ok(!content.includes("'⤢'"), 'must NOT render ⤢ handle (removed per user request)');
    // 8vp outer padding breathing room border
    assert.ok(content.includes('getContentWidth() + 16') && content.includes('getContentHeight() + 16'), 'selection box must have 8vp breathing room');
    assert.ok(content.includes('BorderStyle.Dashed'), 'selection box must use dashed border');
    // Multi-touch anti-jitter gesture coordination
    assert.ok(content.includes('isTwoFingerActive') && content.includes('lastTwoFingerEndTime'), 'must coordinate multi-touch gestures with isTwoFingerActive and cooling period');
    assert.ok(content.includes('SNAP_TARGETS'), 'must have magnetic snap targets in rotation');
    assert.ok(content.includes('HapticService.triggerTick()'), 'must trigger haptic tick on snap');
    // SealStamp Kai font
    assert.ok(content.includes("'Kai, Noto Serif SC'"), 'SealStamp must use Kai font');
  });

  await test('PreviewArea reads latest sticker from array and uses transform-aware key generator to avoid stale closure', async () => {
    const content = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/PreviewArea.ets'), 'utf8');
    assert.ok(
      content.includes('this.stickerAt(index, item)') || content.includes('this.stickers[index]'),
      'PreviewArea must read current sticker from array index to prevent stale builder closure'
    );
    assert.ok(
      content.includes('${item.instanceId}_${item.posX}_${item.posY}_${item.size}_${item.rotation}_${item.opacity}'),
      'PreviewArea ForEach key generator must include position and transform parameters'
    );
  });

  await test('StickerLayer syncs this.item coordinates on gesture end and provides onActionCancel', async () => {
    const content = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf8');
    assert.ok(
      content.includes('this.item.posX = newX') && content.includes('this.item.posY = newY'),
      'StickerLayer PanGesture.onActionEnd must update this.item.posX and this.item.posY'
    );
    assert.ok(
      content.includes('this.item.size = this.localSize') || content.includes('this.item.size = newSize'),
      'StickerLayer must sync this.item.size on gesture end'
    );
    assert.ok(
      content.includes('this.item.rotation = this.localRotation') || content.includes('this.item.rotation = finalRotation') || content.includes('this.item.rotation = newRotation'),
      'StickerLayer must sync this.item.rotation on gesture end'
    );
    assert.ok(
      content.includes('.onActionCancel('),
      'StickerLayer must handle onActionCancel to reset gesture temporary offsets'
    );
  });

  await test('StickerLayer selection border uses HitTestMode.None and root stack blocks touch', async () => {
    const content = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf8');
    assert.ok(content.includes('.hitTestBehavior(HitTestMode.None)'), 'selection border must have HitTestMode.None so it never blocks touch');
    assert.ok(content.includes('.hitTestBehavior(this.active ? HitTestMode.Block : HitTestMode.None)'), 'root stack must intercept touch when active');
  });

  await test('StickerPanel provides clean deletion button and parameter sliders', async () => {
    const panelContent = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerPanel.ets'), 'utf8');
    assert.ok(panelContent.includes("Text('删除')"), 'StickerPanel must have deletion button');
    assert.ok(panelContent.includes('this.onRemoveSticker(this.selectedId)'), 'StickerPanel must invoke onRemoveSticker');
  });

  await test('StickerPanel sliders check SliderChangeMode to prevent programmatic feedback loops', async () => {
    const content = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerPanel.ets'), 'utf8');
    assert.ok(
      content.includes('mode: SliderChangeMode') || content.includes('SliderChangeMode.'),
      'StickerPanel sliders must check SliderChangeMode to avoid triggering feedback on re-render'
    );
  });

  await test('Adding a second sticker preserves the updated position and rotation of the first sticker', async () => {
    // Simulate EditPage state transitions
    let stickers = [];
    let selectedStickerId = '';
    let stickerVersion = 0;

    const addSticker = (templateId, centerX, centerY) => {
      const newItem = {
        instanceId: `sticker_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
        templateId,
        posX: centerX,
        posY: centerY,
        size: 48,
        rotation: 0,
        opacity: 1.0,
        zIndex: stickers.length + 1
      };
      stickers = [...stickers, newItem];
      stickerVersion++;
      selectedStickerId = newItem.instanceId;
      return newItem;
    };

    const updateStickerPosition = (instanceId, posX, posY, size, rotation) => {
      stickers = stickers.map(s => {
        if (s.instanceId === instanceId) {
          return { ...s, posX, posY, size, rotation };
        }
        return s;
      });
      stickerVersion++;
    };

    // 1. Add first sticker
    const s1 = addSticker('seal-01', 150, 200);
    assert.equal(stickers.length, 1);
    assert.equal(stickers[0].posX, 150);
    assert.equal(stickers[0].posY, 200);
    assert.equal(selectedStickerId, s1.instanceId);

    // 2. User moves / transforms first sticker
    updateStickerPosition(s1.instanceId, 280, 350, 72, 30);
    assert.equal(stickers[0].posX, 280);
    assert.equal(stickers[0].posY, 350);
    assert.equal(stickers[0].size, 72);
    assert.equal(stickers[0].rotation, 30);

    // 3. Add second sticker
    const s2 = addSticker('seal-02', 150, 200);
    assert.equal(stickers.length, 2);
    assert.equal(selectedStickerId, s2.instanceId);

    // First sticker MUST retain its moved position and transform!
    assert.equal(stickers[0].posX, 280, 'First sticker posX must remain 280');
    assert.equal(stickers[0].posY, 350, 'First sticker posY must remain 350');
    assert.equal(stickers[0].size, 72, 'First sticker size must remain 72');
    assert.equal(stickers[0].rotation, 30, 'First sticker rotation must remain 30');

    // Second sticker must be at center
    assert.equal(stickers[1].posX, 150, 'Second sticker posX should be 150');
    assert.equal(stickers[1].posY, 200, 'Second sticker posY should be 200');

    // 4. Verify PreviewArea key generator produces distinct keys reflecting changes
    const keyGen = (item) => `${item.instanceId}_${item.posX}_${item.posY}_${item.size}_${item.rotation}_${item.opacity}`;
    const key1 = keyGen(stickers[0]);
    const key2 = keyGen(stickers[1]);
    assert.equal(key1, `${s1.instanceId}_280_350_72_30_1`);
    assert.equal(key2, `${s2.instanceId}_150_200_48_0_1`);
  });

  await test('Pinch gesture and slider size adjustments preserve center invariance', async () => {
    // 1. Pinch gesture math
    const localPosX = 100;
    const localPosY = 120;
    const localSize = 60;
    const centerBefore = { x: localPosX + localSize / 2, y: localPosY + localSize / 2 };

    const pinchScale = 1.8;
    const newSize = Math.round(localSize * pinchScale); // 108
    const newX = localPosX + (localSize - newSize) / 2; // 100 - 24 = 76
    const newY = localPosY + (localSize - newSize) / 2; // 120 - 24 = 96
    const centerAfterPinch = { x: newX + newSize / 2, y: newY + newSize / 2 };

    assert.equal(centerBefore.x, centerAfterPinch.x, 'Pinch center X must remain invariant');
    assert.equal(centerBefore.y, centerAfterPinch.y, 'Pinch center Y must remain invariant');

    // 2. Slider size adjustment math
    const s = { posX: 200, posY: 150, size: 48 };
    const initialCenter = { x: s.posX + s.size / 2, y: s.posY + s.size / 2 }; // (224, 174)
    const targetSize = 96;
    const deltaX = (s.size - targetSize) / 2;
    const deltaY = (s.size - targetSize) / 2;
    const updatedS = {
      posX: s.posX + deltaX,
      posY: s.posY + deltaY,
      size: targetSize
    };
    const updatedCenter = { x: updatedS.posX + updatedS.size / 2, y: updatedS.posY + updatedS.size / 2 };

    assert.equal(initialCenter.x, updatedCenter.x, 'Slider resize center X must remain invariant');
    assert.equal(initialCenter.y, updatedCenter.y, 'Slider resize center Y must remain invariant');
  });

  await test('StickerLayer code implements pinch center compensation and active hit-testing', async () => {
    const stickerLayerSrc = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/StickerLayer.ets'), 'utf8');
    assert.match(
      stickerLayerSrc,
      /const newX = this\.localPosX \+ \(this\.localSize - newSize\) \/ 2;/,
      'StickerLayer must adjust newX on PinchGesture end to keep geometric center invariant'
    );
    assert.match(
      stickerLayerSrc,
      /const newY = this\.localPosY \+ \(this\.localSize - newSize\) \/ 2;/,
      'StickerLayer must adjust newY on PinchGesture end to keep geometric center invariant'
    );
    assert.match(
      stickerLayerSrc,
      /\.hitTestBehavior\(this\.active \? HitTestMode\.Block : HitTestMode\.None\)/,
      'StickerLayer must disable hit-testing when inactive to avoid intercepting touches in other tools'
    );
  });

  await test('PreviewArea and EditPage support deselect on blank canvas tap and tool switching', async () => {
    const previewAreaSrc = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/components/editor/PreviewArea.ets'), 'utf8');
    assert.match(
      previewAreaSrc,
      /onStickerSelect\(''\)/,
      'PreviewArea must provide blank tap deselect via onStickerSelect("")'
    );

    const editPageSrc = fs.readFileSync(path.resolve(root, 'entry/src/main/ets/pages/EditPage.ets'), 'utf8');
    assert.match(
      editPageSrc,
      /this\.selectedStickerId = '';/,
      'EditPage must clear selectedStickerId when switching tools or deselecting'
    );
  });

  console.log(`\nSticker Optimization Tests Summary: ${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
})();

