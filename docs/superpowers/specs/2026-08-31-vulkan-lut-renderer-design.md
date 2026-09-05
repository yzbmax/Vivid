# Vulkan 3D LUT Renderer Design

## Goal

Replace the current CPU-only LUT execution path with a Vulkan compute renderer while preserving the existing editor UI, the ten `.cube` resources, filter IDs, thumbnail pipeline, strength control, and export flow.

The implementation follows the GPU-compute architecture described by SimpleGPULayer, but it does not copy or link SGL source code. This avoids depending on SGL's currently incomplete NAPI layer and avoids introducing GPLv3 code into Vivid.

## Scope

### Included

- Add a Vulkan compute backend inside the existing `libvivid_image.so` module.
- Upload decoded RGBA pixels and the selected 3D LUT to GPU-visible buffers.
- Run trilinear 3D LUT interpolation and strength blending in a compute shader.
- Return a new RGBA `PixelMap` through the existing asynchronous NAPI contract.
- Cache Vulkan device/pipeline objects and uploaded LUT buffers across renders.
- Support `x86_64` for the DevEco emulator and `arm64-v8a` for target devices.
- Report initialization, shader, allocation, dispatch, and readback failures with actionable messages.
- Keep the corrected photo-picker materialization and image validation path as the source of editor pixels.

### Excluded

- Vendoring or linking the SGL repository.
- Replacing the ten current LUT presets with SGL artistic filters.
- UI redesign, filter renaming, or changing navigation/authentication behavior.
- Large-image tiling, layer blending, AI inference, or the other SGL subsystems.
- Automatic fallback that silently returns the unfiltered source image.

## Architecture

### Native boundaries

`FilterEngine` remains the owner of parsed LUT data and filter-ID lookup. A new `VulkanLutRenderer` implements the render operation. The existing NAPI module continues exposing `loadLut`, `render`, and `clear`, so ArkTS callers do not need a new public API.

`VulkanLutRenderer` owns:

- `VkInstance`, selected physical device, logical device, and compute queue;
- command pool and reusable command buffer;
- descriptor-set layout, descriptor pool, and compute pipeline;
- cached GPU LUT buffers keyed by filter ID;
- a mutex-protected lifecycle because the current NAPI worker may receive concurrent thumbnail and preview requests.

The current CPU `LutRenderer` remains only as an independently testable reference implementation. It is not used as a silent runtime fallback for non-original filters.

### Render data flow

1. ArkTS sends an editable RGBA/BGRA `PixelMap`, filter ID, and strength to `FilterNativeBridge.render`.
2. `filter_napi.cpp` reads the PixelMap into a tightly validated RGBA byte buffer and normalizes BGRA input.
3. `FilterEngine` resolves the already parsed LUT and calls `VulkanLutRenderer`.
4. The renderer creates or reuses host-visible coherent storage buffers for input pixels, output pixels, and LUT values.
5. The compute shader executes one invocation per pixel:
   - unpack RGBA channels;
   - normalize RGB to `[0, 1]`;
   - map through LUT domain min/max;
   - sample the eight surrounding LUT entries using R-fastest `.cube` ordering;
   - perform trilinear interpolation;
   - blend source and filtered RGB by clamped strength;
   - preserve source alpha and write packed RGBA output.
6. Native code waits for the submitted fence, copies the output bytes back, and the existing completion callback creates the output PixelMap.
7. Any Vulkan error rejects the promise. ArkTS shows the existing “滤镜预览失败” feedback and logs the native stage and Vulkan result code.

### Shader packaging

The GLSL compute source lives beside the native renderer for review. A checked-in generated SPIR-V header is produced with the DevEco SDK's `glslang_validator.exe`, allowing reproducible offline builds without loading shader files from an application-private runtime path.

The generated header is treated as build output derived from the checked-in GLSL source. Its generator command and source hash are documented in the header comment.

## Error handling

- Vulkan initialization is lazy and happens on the first non-original render.
- Lack of a Vulkan-capable physical device, compute queue, supported memory type, or valid shader module is a hard filter-render failure.
- Invalid dimensions, stride, LUT size, or arithmetic overflow fail before allocation or dispatch.
- Every Vulkan handle is released in reverse ownership order. Partially initialized instances are safe to destroy.
- `clear()` releases cached LUT buffers but keeps reusable device and pipeline state. Module/process destruction releases all Vulkan objects.
- Original-filter rendering continues bypassing native LUT work at the ArkTS layer.
- Failed non-original thumbnails never reuse the original thumbnail, so failures cannot masquerade as identical filters.

## Tests and verification

### Automated native contract tests

- Shader-facing LUT packing preserves R-fastest ordering.
- Pixel count and buffer-size validation rejects zero, overflow, invalid stride, and undersized buffers.
- Strength is clamped to `[0, 1]`.
- Distinct LUTs produce distinct CPU-reference outputs for a fixed set of representative pixels.
- Vulkan result-to-error formatting includes the failing stage and numeric result.

### Project verification

- Run the existing ArkTS unit test suite.
- Run a full debug build because native sources, shader assets, CMake, and ABI output change.
- Inspect the HAP to confirm both `x86_64` and `arm64-v8a` contain `libvivid_image.so`.
- Install on the current x86_64 emulator.
- Import one image, confirm editor decode succeeds, then compare Original, Matinee, Postcard, and NightMarket at 100% strength.
- Capture logs proving Vulkan initialization, LUT upload, and successful dispatch.
- Confirm a second filter selection reuses the Vulkan device/pipeline and produces a visibly different output.

## Compatibility and rollout

No ArkTS route, model, or UI interface changes are required. The native shared-library name remains `libvivid_image.so`, preventing another module-name or install-ABI mismatch. The change remains local and uncommitted unless the user later asks for a commit.

If the emulator exposes no usable Vulkan compute queue, implementation stops with a precise runtime error rather than substituting the old CPU result. Device support can then be assessed separately.
