#include "lut_renderer.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <stdexcept>

namespace {

constexpr float kGridMax = 32.0f;

float Clamp01(float value) {
    return std::max(0.0f, std::min(1.0f, value));
}

RgbFloat Mix(const RgbFloat& original, const RgbFloat& lut, float strength) {
    return {
        original.r * (1.0f - strength) + lut.r * strength,
        original.g * (1.0f - strength) + lut.g * strength,
        original.b * (1.0f - strength) + lut.b * strength
    };
}

uint8_t ToByte(float value) {
    const float clamped = Clamp01(value);
    return static_cast<uint8_t>(std::lround(clamped * 255.0f));
}

}  // namespace

RgbFloat LutRenderer::Sample(const Lut3D& lut, float r, float g, float b) {
    if (lut.data.size() != Lut3D::NODE_COUNT) {
        throw std::invalid_argument("LutRenderer: LUT must contain 35937 nodes");
    }

    const float x = Clamp01(r) * kGridMax;
    const float y = Clamp01(g) * kGridMax;
    const float z = Clamp01(b) * kGridMax;
    const int r0 = static_cast<int>(std::floor(x));
    const int g0 = static_cast<int>(std::floor(y));
    const int b0 = static_cast<int>(std::floor(z));
    const int r1 = std::min(r0 + 1, Lut3D::SIZE - 1);
    const int g1 = std::min(g0 + 1, Lut3D::SIZE - 1);
    const int b1 = std::min(b0 + 1, Lut3D::SIZE - 1);
    const float tr = x - static_cast<float>(r0);
    const float tg = y - static_cast<float>(g0);
    const float tb = z - static_cast<float>(b0);

    const RgbFloat c000 = lut.data[Lut3D::Index(r0, g0, b0)];
    const RgbFloat c100 = lut.data[Lut3D::Index(r1, g0, b0)];
    const RgbFloat c010 = lut.data[Lut3D::Index(r0, g1, b0)];
    const RgbFloat c110 = lut.data[Lut3D::Index(r1, g1, b0)];
    const RgbFloat c001 = lut.data[Lut3D::Index(r0, g0, b1)];
    const RgbFloat c101 = lut.data[Lut3D::Index(r1, g0, b1)];
    const RgbFloat c011 = lut.data[Lut3D::Index(r0, g1, b1)];
    const RgbFloat c111 = lut.data[Lut3D::Index(r1, g1, b1)];

    const RgbFloat r00 = Mix(c000, c100, tr);
    const RgbFloat r10 = Mix(c010, c110, tr);
    const RgbFloat r01 = Mix(c001, c101, tr);
    const RgbFloat r11 = Mix(c011, c111, tr);
    const RgbFloat g0Value = Mix(r00, r10, tg);
    const RgbFloat g1Value = Mix(r01, r11, tg);
    return Mix(g0Value, g1Value, tb);
}

bool LutRenderer::Render(uint8_t* rgba,
                         int width,
                         int height,
                         int rowBytes,
                         const Lut3D& lut,
                         float strength) {
    if (rgba == nullptr || width <= 0 || height <= 0 || rowBytes < width * 4 ||
        lut.data.size() != Lut3D::NODE_COUNT) {
        return false;
    }

    const float normalizedStrength = Clamp01(strength);
    for (int y = 0; y < height; ++y) {
        uint8_t* row = rgba + static_cast<std::ptrdiff_t>(y) * rowBytes;
        for (int x = 0; x < width; ++x) {
            uint8_t* pixel = row + static_cast<std::ptrdiff_t>(x) * 4;
            const RgbFloat original = {
                static_cast<float>(pixel[0]) / 255.0f,
                static_cast<float>(pixel[1]) / 255.0f,
                static_cast<float>(pixel[2]) / 255.0f
            };
            const RgbFloat sampled = Sample(lut, original.r, original.g, original.b);
            const RgbFloat result = Mix(original, sampled, normalizedStrength);
            pixel[0] = ToByte(result.r);
            pixel[1] = ToByte(result.g);
            pixel[2] = ToByte(result.b);
        }
    }
    return true;
}
