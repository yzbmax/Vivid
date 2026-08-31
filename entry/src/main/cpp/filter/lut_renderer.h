#ifndef VIVID_LUT_RENDERER_H
#define VIVID_LUT_RENDERER_H

#include "lut3d.h"

#include <cstdint>

class LutRenderer {
public:
    static RgbFloat Sample(const Lut3D& lut, float r, float g, float b);

    /** Render an RGBA8888 buffer in place; alpha is preserved. */
    static bool Render(uint8_t* rgba,
                       int width,
                       int height,
                       int rowBytes,
                       const Lut3D& lut,
                       float strength);
};

#endif  // VIVID_LUT_RENDERER_H
