#ifndef VIVID_VULKAN_LUT_CONTRACT_H
#define VIVID_VULKAN_LUT_CONTRACT_H

#include "lut3d.h"

#include <climits>
#include <cstddef>

namespace VulkanLutContract {

constexpr std::size_t LutIndex(int r, int g, int b) {
    return static_cast<std::size_t>(b) * Lut3D::SIZE * Lut3D::SIZE +
           static_cast<std::size_t>(g) * Lut3D::SIZE +
           static_cast<std::size_t>(r);
}

constexpr bool ValidateImageLayout(int width, int height, int rowBytes) {
    return width > 0 && height > 0 && rowBytes > 0 &&
           width <= INT_MAX / 4 && rowBytes >= width * 4 &&
           rowBytes % 4 == 0 && rowBytes <= INT_MAX / height;
}

constexpr float ClampStrength(float value) {
    return value < 0.0f ? 0.0f : (value > 1.0f ? 1.0f : value);
}

constexpr bool ShouldUseCpuFallback(bool gpuPixelsChanged, float strength) {
    return !gpuPixelsChanged && ClampStrength(strength) > 0.0f;
}

}  // namespace VulkanLutContract

#endif  // VIVID_VULKAN_LUT_CONTRACT_H
