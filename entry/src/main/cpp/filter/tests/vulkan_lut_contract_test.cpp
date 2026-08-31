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
static_assert(!VulkanLutContract::ValidateImageLayout(2, 3, 10));

static_assert(VulkanLutContract::ClampStrength(-1.0f) == 0.0f);
static_assert(VulkanLutContract::ClampStrength(0.75f) == 0.75f);
static_assert(VulkanLutContract::ClampStrength(2.0f) == 1.0f);

static_assert(VulkanLutContract::ShouldUseCpuFallback(false, 0.75f));
static_assert(!VulkanLutContract::ShouldUseCpuFallback(true, 0.75f));
static_assert(!VulkanLutContract::ShouldUseCpuFallback(false, 0.0f));
