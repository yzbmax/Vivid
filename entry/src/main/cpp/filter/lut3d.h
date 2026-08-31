#ifndef VIVID_LUT3D_H
#define VIVID_LUT3D_H

#include <cstddef>
#include <vector>

struct RgbFloat {
    float r;
    float g;
    float b;
};

class Lut3D {
public:
    static constexpr int SIZE = 33;
    static constexpr std::size_t NODE_COUNT =
        static_cast<std::size_t>(SIZE) * SIZE * SIZE;

    /** Cube order is R fastest, then G, then B. */
    static constexpr std::size_t Index(int r, int g, int b) {
        return static_cast<std::size_t>(b) * SIZE * SIZE +
               static_cast<std::size_t>(g) * SIZE +
               static_cast<std::size_t>(r);
    }

    std::vector<RgbFloat> data;
};

#endif  // VIVID_LUT3D_H
