// Host-only runner for the two pure ArkTS suites. Not an ArkUI/Hypium device run.
// Uses DevEco's existing TypeScript compiler; installs no dependencies.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const repo = path.resolve(__dirname, '..');
const sourceRoot = path.resolve(process.argv[2] || repo);
const studio = process.env.DEVECO_STUDIO_HOME || (
  process.platform === 'darwin'
    ? '/Applications/DevEco-Studio.app/Contents'
    : path.join(process.env.ProgramFiles || 'C:/Program Files', 'Huawei/DevEco Studio')
);
const ts = require(path.join(studio, 'tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const cache = new Map();
let passed = 0;
let failed = 0;
global.$r = res => res;
const storageMap = new Map();
global.AppStorage = {
  get: k => storageMap.get(k),
  setOrCreate: (k, v) => { storageMap.set(k, v); return true; },
  delete: k => storageMap.delete(k),
  has: k => storageMap.has(k),
  clear: () => storageMap.clear()
};
global.PersistentStorage = {
  persistProp: (k, def) => {
    if (!storageMap.has(k)) storageMap.set(k, def);
  },
  deleteProp: k => storageMap.delete(k)
};
let beforeEachFn = null;
let testQueue = Promise.resolve();
const testApi = {
  describe: (_name, body) => body(),
  beforeAll: fn => fn(),
  afterAll: fn => fn(),
  beforeEach: fn => { beforeEachFn = fn; },
  afterEach: fn => fn(),
  it: (name, _level, body) => {
    const currentBeforeEach = beforeEachFn;
    testQueue = testQueue.then(async () => {
      try {
        if (currentBeforeEach) await currentBeforeEach();
        await body();
        passed++;
        console.log('PASS ' + name);
      } catch (error) {
        failed++;
        console.error('FAIL ' + name + '\n' + error.stack);
      }
    });
  },
  expect: value => ({
    assertEqual: expected => assert.deepStrictEqual(value, expected),
    assertTrue: () => assert.strictEqual(value, true),
    assertFalse: () => assert.strictEqual(value, false),
    assertNull: () => assert.strictEqual(value, null),
    assertUndefined: () => assert.strictEqual(value, undefined),
    assertContain: expected => assert.ok(String(value).includes(expected))
  })
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
    if (id === '@ohos/hypium') return testApi;
    if (id === 'libvivid_image.so') {
      return {
        renderLut: () => {},
        loadLut: () => true,
        hasLut: () => true,
        clearLuts: () => {}
      };
    }
    if (id === '@kit.ArkUI') return { LengthMetricsUnit: { PX: 1, VP: 0 } };
    if (id === '@kit.ImageKit') return { image: {} };
    if (id === '@kit.MediaLibraryKit') return { photoAccessHelper: {} };
    if (id === '@kit.ArkGraphics2D') return { imageColorFilter: {} };
    if (id === '@kit.ArkData') return { preferences: {} };
    if (id === '@kit.AbilityKit') return { common: {} };
    if (id === '@kit.CoreFileKit') {
      return {
        fileIo: {
          accessSync: () => false,
          openSync: () => ({ fd: 1 }),
          writeSync: () => {},
          closeSync: () => {},
          readTextSync: () => '',
          mkdirSync: () => {},
          unlinkSync: () => {},
          copyFileSync: () => {}
        }
      };
    }
    if (id === '@kit.PerformanceAnalysisKit') {
      return {
        hilog: {
          info: () => {},
          warn: () => {},
          error: () => {}
        }
      };
    }
    if (id === '@kit.ArkTS' || id === '@ohos.util') {
      return {
        util: {
          TextDecoder: {
            create: (_encoding, _options) => {
              const td = new (require('node:util').TextDecoder)();
              return {
                decodeToString: (input) => td.decode(input),
                decodeWithStream: (input) => td.decode(input),
                decode: (input) => td.decode(input)
              };
            }
          }
        }
      };
    }
    if (!id.startsWith('.')) throw new Error('Device dependency in pure suite: ' + id);
    let resolved = path.resolve(path.dirname(file), id + '.ets');
    const production = path.join(repo, 'entry/src/main');
    if (resolved.startsWith(production + path.sep)) {
      resolved = path.join(sourceRoot, path.relative(repo, resolved));
    }
    return load(resolved);
  };
  const evaluate = vm.runInThisContext('(function(require,module,exports){\n' + compiled + '\n})', { filename: file });
  evaluate(localRequire, module, module.exports);
  return module.exports;
}
const suites = process.argv.slice(3);
(async () => {
  for (const suite of suites.length ? suites : ['TextLayerState', 'TextLayoutResolver']) {
    beforeEachFn = null;
    await load(path.join(repo, 'entry/src/test', suite + '.test.ets')).default();
  }
  await testQueue;
  console.log(`Host pure-logic tests: ${passed} passed, ${failed} failed (no UI/device validation)`);
  process.exitCode = failed ? 1 : 0;
})();
