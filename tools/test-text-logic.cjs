// Host-only runner for the two pure ArkTS suites. Not an ArkUI/Hypium device run.
// Uses DevEco's existing TypeScript compiler; installs no dependencies.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const repo = path.resolve(__dirname, '..');
const sourceRoot = path.resolve(process.argv[2] || repo);
const studio = process.env.DEVECO_STUDIO_HOME || path.join(process.env.ProgramFiles || 'C:/Program Files', 'Huawei/DevEco Studio');
const ts = require(path.join(studio, 'tools/hvigor/hvigor-ohos-plugin/node_modules/typescript'));
const cache = new Map();
let passed = 0;
let failed = 0;
const testApi = {
  describe: (_name, body) => body(),
  it: (name, _level, body) => {
    try {
      body();
      passed++;
      console.log('PASS ' + name);
    } catch (error) {
      failed++;
      console.error('FAIL ' + name + '\n' + error.stack);
    }
  },
  expect: value => ({
    assertEqual: expected => assert.deepStrictEqual(value, expected),
    assertTrue: () => assert.strictEqual(value, true),
    assertFalse: () => assert.strictEqual(value, false)
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
for (const suite of suites.length ? suites : ['TextLayerState', 'TextLayoutResolver']) {
  load(path.join(repo, 'entry/src/test', suite + '.test.ets')).default();
}
console.log(`Host pure-logic tests: ${passed} passed, ${failed} failed (no UI/device validation)`);
process.exitCode = failed ? 1 : 0;
