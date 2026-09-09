const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");

const root = path.resolve(__dirname, "..");
const filterDir = path.join(root, "entry/src/main/resources/rawfile/filters");
const backupDir = path.join(root, "tools/filters_backup");

console.log("====================================================");
console.log("TDD: 3D LUT filter package optimization test");
console.log("====================================================");

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log("  [PASS] " + name);
    passed++;
  } catch (err) {
    console.error("  [FAIL] " + name + ": " + err.message);
    failed++;
  }
}

const resampledFiles = [
  "Canopy.cube",
  "DuskTide.cube",
  "Fieldnote.cube",
  "Heartland.cube",
  "Lowsun.cube",
  "Matinee.cube",
  "Meridian.cube",
  "NightMarket.cube",
  "Postcard.cube",
  "Skylight.cube",
  "VEL_Film_Fade.cube",
  "VEL_Mono_Contrast.cube",
  "VEL_Moody_Blue.cube",
  "VEL_Vintage_Chrome.cube",
  "VEL_Warm_Film.cube",
  "VEL_Warm_Pastel.cube",
  "YT_Moody_Dark.cube"
];

// 1. Backup verification
test("Original large LUT files are backed up to tools/filters_backup", () => {
  assert(fs.existsSync(backupDir), "tools/filters_backup directory must exist");
  for (const file of resampledFiles) {
    const bFile = path.join(backupDir, file);
    assert(fs.existsSync(bFile), "Backup file " + file + " must exist");
    assert(fs.statSync(bFile).size > 500000, "Backup file " + file + " must be large (>500KB)");
  }
});

// 2. Directory size <= 3.5MB
test("Total filter assets size is reduced below 3.5MB", () => {
  let totalBytes = 0;
  const files = fs.readdirSync(filterDir);
  for (const file of files) {
    const p = path.join(filterDir, file);
    if (fs.statSync(p).isFile()) {
      totalBytes += fs.statSync(p).size;
    }
  }
  const totalMb = totalBytes / (1024 * 1024);
  console.log("     Current filters dir size: " + totalMb.toFixed(2) + " MB (target <= 3.5 MB)");
  assert(totalBytes < 3.5 * 1024 * 1024, "Total size " + totalMb.toFixed(2) + "MB must be < 3.5MB");
});

// 3. Resampled files are LUT_3D_SIZE 16 with 4096 data lines
test("Resampled CUBE files follow LUT_3D_SIZE 16 with 4096 RGB nodes", () => {
  for (const file of resampledFiles) {
    const p = path.join(filterDir, file);
    assert(fs.existsSync(p), "Filter file " + file + " must exist");
    const content = fs.readFileSync(p, "utf8");
    assert(content.includes("LUT_3D_SIZE 16"), file + " must have LUT_3D_SIZE 16");
    
    const lines = content.split("\n").map(l => l.trim()).filter(l => l.length > 0 && !l.startsWith("#"));
    const dataLines = lines.filter(l => !l.startsWith("TITLE") && !l.startsWith("LUT_3D_SIZE") && !l.startsWith("DOMAIN_"));
    assert.equal(dataLines.length, 4096, file + " must have 4096 lines, found " + dataLines.length);
    
    const firstTokens = dataLines[0].split(/\s+/).map(Number);
    assert.equal(firstTokens.length, 3, file + " first line must have 3 numbers");
    assert(!isNaN(firstTokens[0]) && !isNaN(firstTokens[1]) && !isNaN(firstTokens[2]), file + " numbers must be valid");
  }
});

// 4. Catalog integrity
test("All presets in FilterCatalog.ets match existing local files", () => {
  const catalogPath = path.join(root, "entry/src/main/ets/features/editor/filter/FilterCatalog.ets");
  assert(fs.existsSync(catalogPath), "FilterCatalog.ets must exist");
  const catalogContent = fs.readFileSync(catalogPath, "utf8");
  
  const matches = catalogContent.matchAll(/lutPath:\s*['"]filters\/([^'"]+)['"]/g);
  let count = 0;
  for (const match of matches) {
    count++;
    const lutFile = match[1];
    const fullPath = path.join(filterDir, lutFile);
    assert(fs.existsSync(fullPath), "Referenced lut file " + lutFile + " must exist");
  }
  assert(count >= 29, "Catalog must reference at least 29 LUTs, found " + count);
});

console.log("====================================================");
console.log("Test result: " + passed + " passed, " + failed + " failed");
console.log("====================================================");

if (failed > 0) {
  process.exit(1);
}
