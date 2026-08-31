# Vulkan 3D LUT Renderer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the existing ten 33³ `.cube` presets through a Vulkan compute pipeline inside `libvivid_image.so`, producing visibly distinct previews without changing the editor UI or public ArkTS API.

**Architecture:** Keep photo decoding and PixelMap conversion in the existing ArkTS/NAPI path, then replace the `FilterEngine` render call with a reusable `VulkanLutRenderer`. The renderer owns one Vulkan compute device/pipeline, uploads cached `vec4` LUT buffers by filter ID, dispatches one shader invocation per pixel, and reads RGBA output back into the existing PixelMap creation path. SGL source is not copied or linked.

**Tech Stack:** HarmonyOS ArkTS, Node-API, C++20, Vulkan compute, GLSL 450, DevEco `glslang_validator.exe`, ImageKit PixelMap NDK

**Spec:** `docs/superpowers/specs/2026-08-31-vulkan-lut-renderer-design.md`

## Global Constraints

- Preserve the existing `libvivid_image.so` import name and the `loadLut`, `render`, and `clear` ArkTS contract.
- Preserve all ten filter IDs, names, `.cube` files, thumbnail behavior, strength values, and editor layout.
- Do not vendor, copy, or link SimpleGPULayer source; its GPLv3 license must not enter Vivid.
- Support both `x86_64` and `arm64-v8a` outputs already configured in `entry/build-profile.json5`.
- A failed non-original render must reject with an actionable error and must never return the source image as a successful filtered result.
- Keep the current photo-picker cache materialization and decode validation changes intact.
- Do not delete files, create or switch branches, commit, or push unless the user explicitly requests it.
- Execute in the current working tree because the existing filter implementation is currently uncommitted and unavailable from repository `HEAD`.

---

### Task 1: Define and compile-check the Vulkan buffer contract

**Files:**
- Create: `entry/src/main/cpp/filter/vulkan_lut_contract.h`
- Create: `entry/src/main/cpp/filter/tests/vulkan_lut_contract_test.cpp`
- Modify: `entry/src/main/cpp/CMakeLists.txt`

**Interfaces:**
- Consumes: `Lut3D::SIZE`, `Lut3D::NODE_COUNT`, and R-fastest ordering from `filter/lut3d.h`.
- Produces: `VulkanLutContract::LutIndex(int r, int g, int b)`, `VulkanLutContract::ValidateImageLayout(int width, int height, int rowBytes)`, and `VulkanLutContract::ClampStrength(float value)`.

- [ ] **Step 1: Add compile-time tests before the contract exists**

Add `vulkan_lut_contract_test.cpp` to the `vivid_image` source list, with assertions equivalent to:

```cpp
#include "../vulkan_lut_contract.h"

static_assert(VulkanLutContract::LutIndex(0, 0, 0) == 0);
static_assert(VulkanLutContract::LutIndex(1, 0, 0) == 1);
static_assert(VulkanLutContract::LutIndex(0, 1, 0) == 33);
static_assert(VulkanLutContract::LutIndex(0, 0, 1) == 1089);
static_assert(VulkanLutContract::LutIndex(32, 32, 32) == 35936);
static_assert(VulkanLutContract::ValidateImageLayout(1, 1, 4));
static_assert(VulkanLutContract::ValidateImageLayout(2, 3, 16));
static_assert(!VulkanLutContract::ValidateImageLayout(0, 1, 4));
static_assert(!VulkanLutContract::ValidateImageLayout(2, 3, 7));
static_assert(VulkanLutContract::ClampStrength(-1.0f) == 0.0f);
static_assert(VulkanLutContract::ClampStrength(0.75f) == 0.75f);
static_assert(VulkanLutContract::ClampStrength(2.0f) == 1.0f);
```

- [ ] **Step 2: Run the native module build and verify RED**

Run:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default -p module=entry@default -p buildMode=debug 'default@BuildNativeWithCmake' --no-daemon --no-incremental
```

Expected: FAIL because `filter/vulkan_lut_contract.h` does not exist.

- [ ] **Step 3: Implement the minimal constexpr contract**

Create a header-only contract. `ValidateImageLayout` must avoid `width * 4` signed overflow by first requiring `width <= INT_MAX / 4`, then require `rowBytes >= width * 4`, positive height, and `rowBytes <= INT_MAX / height`.

- [ ] **Step 4: Re-run the native module build and verify GREEN**

Expected: native compilation succeeds and all `static_assert` checks compile.

- [ ] **Step 5: Review only Task 1 changes**

Run `git diff --check` and inspect the three Task 1 paths. Do not commit.

---

### Task 2: Add and validate the 3D LUT compute shader

**Files:**
- Create: `entry/src/main/cpp/filter/shaders/lut3d.comp`
- Create: `entry/src/main/cpp/filter/generated/lut3d_spv.h`

**Interfaces:**
- Consumes: packed little-endian RGBA8888 input, a `vec4` array of 35,937 LUT nodes in R-fastest order, image width/height/row stride, LUT size/domain, and strength.
- Produces: packed RGBA8888 output with source alpha preserved.

- [ ] **Step 1: Write the GLSL 450 compute source**

Use `layout(local_size_x = 16, local_size_y = 16) in`. Define storage-buffer bindings `0=input uint[]`, `1=output uint[]`, and `2=LUT vec4[]`. Define scalar push constants in this exact order:

```glsl
uint width;
uint height;
uint rowPixels;
uint lutSize;
float strength;
float domainMinR;
float domainMinG;
float domainMinB;
float domainMaxR;
float domainMaxG;
float domainMaxB;
```

The shader must return for invocations outside width/height, unpack RGBA from the low-to-high bytes of a `uint`, perform domain normalization and trilinear interpolation using index `b*N*N + g*N + r`, mix only RGB by strength, and preserve alpha exactly.

- [ ] **Step 2: Verify the shader fails when deliberately given an invalid entry point**

Temporarily invoke the validator with `-e missing_main` and confirm a non-zero exit. Do not change the checked-in shader.

- [ ] **Step 3: Generate the SPIR-V header**

Run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\glslang_validator.exe' -V 'entry\src\main\cpp\filter\shaders\lut3d.comp' -e main --vn kVividLut3dShader -o 'entry\src\main\cpp\filter\generated\lut3d_spv.h'
```

Expected: exit code 0 and a generated `kVividLut3dShader` array whose first word is SPIR-V magic `0x07230203`.

- [ ] **Step 4: Validate the generated artifact**

Search the header for `kVividLut3dShader` and `0x07230203`, then run `git diff --check` for the GLSL source and generated header. Do not hand-edit the generated header.

---

### Task 3: Implement the reusable Vulkan compute renderer

**Files:**
- Create: `entry/src/main/cpp/filter/vulkan_lut_renderer.h`
- Create: `entry/src/main/cpp/filter/vulkan_lut_renderer.cpp`
- Modify: `entry/src/main/cpp/CMakeLists.txt`

**Interfaces:**
- Consumes: `uint8_t* rgba`, `width`, `height`, `rowBytes`, filter ID, `const Lut3D&`, and strength.
- Produces: `bool Render(..., std::string* error)` and `void ClearLutCache()`.

- [ ] **Step 1: Add the renderer source to CMake before it exists and verify RED**

Add `filter/vulkan_lut_renderer.cpp` to `vivid_image`, add C++20, add `filter/generated` to private includes, link `vulkan` and `hilog_ndk.z`, and define `NODE_GYP_MODULE_NAME=vivid_image`.

Run the native module build. Expected: FAIL because the renderer source is absent.

- [ ] **Step 2: Declare a move-disabled renderer with explicit ownership**

Declare:

```cpp
class VulkanLutRenderer {
public:
    VulkanLutRenderer() = default;
    ~VulkanLutRenderer();
    VulkanLutRenderer(const VulkanLutRenderer&) = delete;
    VulkanLutRenderer& operator=(const VulkanLutRenderer&) = delete;

    bool Render(uint8_t* rgba, int width, int height, int rowBytes,
                const std::string& filterId, const Lut3D& lut,
                float strength, std::string* error);
    void ClearLutCache();
};
```

Private members own instance, physical device, device, compute queue/family, command pool, descriptor layout/pool, shader module, pipeline layout/pipeline, and a filter-ID map of LUT `VkBuffer`/`VkDeviceMemory` pairs.

- [ ] **Step 3: Implement lazy Vulkan initialization**

Initialize in this order: instance, physical device with compute queue, logical device/queue, descriptor-set layout, shader module from `kVividLut3dShader`, pipeline layout with 44-byte compute push constants, compute pipeline, command pool, descriptor pool. On every failure, include the stage and numeric `VkResult` in `error` and destroy partial state safely.

- [ ] **Step 4: Implement checked buffer allocation and LUT upload**

Select a `HOST_VISIBLE | HOST_COHERENT` memory type. Validate all multiplication before allocating. Pack each `RgbFloat` into four floats `{r,g,b,1}` before upload. Cache the resulting LUT buffer by filter ID; replacing a LUT invalidates only that ID.

- [ ] **Step 5: Implement dispatch and readback**

Allocate per-render input/output storage buffers sized `rowBytes * height`, map/copy input, update three descriptors, record one dispatch with groups `(width+15)/16` and `(height+15)/16`, submit with a fence, wait, map output, and copy exactly `rowBytes * height` bytes back. Release per-render descriptors, buffers, memory, command buffer, and fence on every exit path.

- [ ] **Step 6: Add native logs without leaking image data**

Log one initialization success containing device name and queue family, one LUT-upload success containing filter ID and node count, and one dispatch success containing width/height/filter ID. Log failures with stage and `VkResult`; never log pixel data or full LUT content.

- [ ] **Step 7: Build the native module and review warnings**

Expected: `BuildNativeWithCmake` succeeds for both configured ABIs. Any Vulkan compile/link error is resolved before integration. Run `git diff --check` for Task 3 files.

---

### Task 4: Route FilterEngine and NAPI errors through Vulkan

**Files:**
- Modify: `entry/src/main/cpp/filter/filter_engine.h`
- Modify: `entry/src/main/cpp/filter/filter_engine.cpp`
- Modify: `entry/src/main/cpp/napi/filter_napi.cpp`
- Modify: `entry/src/main/cpp/CMakeLists.txt`

**Interfaces:**
- Consumes: `VulkanLutRenderer::Render` and existing parsed LUT map.
- Produces: existing NAPI `Promise<PixelMap>` with stage-specific rejection text.

- [ ] **Step 1: Add a failing FilterEngine contract test**

Extend `filter/tests/filter_engine_test.cpp` to require a render error output parameter and to assert that an unloaded filter reports `"LUT not loaded: <id>"`. Add or retain it in the native compile-check source list.

- [ ] **Step 2: Build and verify RED**

Expected: FAIL because the existing `FilterEngine::Render` signature has no error parameter.

- [ ] **Step 3: Integrate `VulkanLutRenderer`**

Make `FilterEngine::Render` non-const and accept `std::string* error`. Call the Vulkan renderer for every loaded non-original LUT. `LoadLut` invalidates that filter's cached GPU buffer after successful replacement; `RemoveLut` and `Clear` release the matching cache entries.

- [ ] **Step 4: Preserve detailed errors in the NAPI worker**

Pass `&context->error` to `FilterEngine::Render`. Only use the generic `"Native filter render failed"` text when the renderer did not provide a message. Keep promise rejection and PixelMap ownership behavior unchanged.

- [ ] **Step 5: Build and verify GREEN**

Run the native module build, then the full ArkTS unit test task. Expected: both succeed; the previous native module-name mismatch warning is absent after defining `NODE_GYP_MODULE_NAME=vivid_image`.

---

### Task 5: Verify package contents and emulator behavior

**Files:**
- Verify only: `entry/build/default/outputs/default/entry-default-unsigned.hap`
- Verify only: runtime logs from `com.example.vivid`

**Interfaces:**
- Consumes: complete ArkTS + native implementation.
- Produces: evidence that import, Vulkan initialization, LUT upload, dispatch, and distinct filter outputs work on the emulator.

- [ ] **Step 1: Run clean project verification**

Run the existing unit-test command and then:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:Path='C:\Program Files\Huawei\DevEco Studio\tools\node;' + $env:Path
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode project -p product=default -p buildMode=debug assembleApp --no-daemon --no-incremental
```

Expected: both commands report `BUILD SUCCESSFUL`.

- [ ] **Step 2: Inspect both ABI payloads**

List the HAP archive and confirm these paths exist:

```text
libs/x86_64/libvivid_image.so
libs/arm64-v8a/libvivid_image.so
```

- [ ] **Step 3: Install and start on the current emulator**

Use the DevEco SDK `hdc.exe` to install with `-r`, clear `hilog`, and start `EntryAbility` for `com.example.vivid`. Expected: install and ability start succeed without ABI parse errors or process crash.

- [ ] **Step 4: Verify import before filters**

Import one image. Confirm `PhotoPickerService` materializes and validates the cached file, the editor shows the image, and logs do not contain `Photo import failed` or `Failed to decode editor preview`.

- [ ] **Step 5: Verify visibly distinct GPU results**

At strength 100, select Original, Matinee, Postcard, and NightMarket. Confirm the main preview changes between each non-original preset and thumbnails are not copies of the original. Capture logs containing Vulkan initialization once, LUT upload per selected preset, and successful dispatches.

- [ ] **Step 6: Verify failure behavior and final diff**

Confirm no “filter success” is shown when a native render rejects. Run `git diff --check`, `git status --short`, and review only task-related paths. Do not commit or push.
