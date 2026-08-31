#include "../lut_renderer.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <string>

namespace {

int failures = 0;

void Expect(bool condition, const std::string& message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << std::endl;
        ++failures;
    }
}

bool Near(float actual, float expected) {
    return std::fabs(actual - expected) <= 0.0002f;
}

Lut3D IdentityLut() {
    Lut3D lut;
    lut.data.resize(Lut3D::NODE_COUNT);
    for (int b = 0; b < Lut3D::SIZE; ++b) {
        for (int g = 0; g < Lut3D::SIZE; ++g) {
            for (int r = 0; r < Lut3D::SIZE; ++r) {
                lut.data[Lut3D::Index(r, g, b)] = {
                    static_cast<float>(r) / 32.0f,
                    static_cast<float>(g) / 32.0f,
                    static_cast<float>(b) / 32.0f
                };
            }
        }
    }
    return lut;
}

Lut3D InvertLut() {
    Lut3D lut;
    lut.data.resize(Lut3D::NODE_COUNT, {1.0f, 1.0f, 1.0f});
    for (int b = 0; b < Lut3D::SIZE; ++b) {
        for (int g = 0; g < Lut3D::SIZE; ++g) {
            for (int r = 0; r < Lut3D::SIZE; ++r) {
                lut.data[Lut3D::Index(r, g, b)] = {
                    1.0f - static_cast<float>(r) / 32.0f,
                    1.0f - static_cast<float>(g) / 32.0f,
                    1.0f - static_cast<float>(b) / 32.0f
                };
            }
        }
    }
    return lut;
}

}  // namespace

int main() {
    const Lut3D identity = IdentityLut();
    Expect(Near(LutRenderer::Sample(identity, 0.0f, 0.0f, 0.0f).r, 0.0f),
           "samples the lower corner");
    Expect(Near(LutRenderer::Sample(identity, 1.0f, 1.0f, 1.0f).b, 1.0f),
           "samples the upper corner");
    const RgbFloat center = LutRenderer::Sample(identity, 0.5f, 0.5f, 0.5f);
    Expect(Near(center.r, 0.5f) && Near(center.g, 0.5f) && Near(center.b, 0.5f),
           "trilinearly samples the center");
    const RgbFloat edge = LutRenderer::Sample(identity, 0.125f, 0.75f, 0.25f);
    Expect(Near(edge.r, 0.125f) && Near(edge.g, 0.75f) && Near(edge.b, 0.25f),
           "trilinearly samples an edge point");

    const Lut3D invert = InvertLut();
    uint8_t pixels[] = {64, 128, 192, 17};
    Expect(LutRenderer::Render(pixels, 1, 1, 4, invert, 0.0f),
           "strength zero render succeeds");
    Expect(pixels[0] == 64 && pixels[1] == 128 && pixels[2] == 192 && pixels[3] == 17,
           "strength zero keeps original RGBA");

    Expect(LutRenderer::Render(pixels, 1, 1, 4, invert, 1.0f),
           "strength one render succeeds");
    Expect(pixels[0] == 191 && pixels[1] == 127 && pixels[2] == 63 && pixels[3] == 17,
           "strength one applies LUT and preserves alpha");

    pixels[0] = 64;
    pixels[1] = 128;
    pixels[2] = 192;
    Expect(LutRenderer::Render(pixels, 1, 1, 4, invert, 0.5f),
           "half-strength render succeeds");
    Expect(pixels[0] == 128 && pixels[1] == 128 && pixels[2] == 128,
           "half strength mixes original and LUT output");

    return failures == 0 ? 0 : 1;
}
