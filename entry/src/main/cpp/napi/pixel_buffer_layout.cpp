#include "pixel_buffer_layout.h"

#include <limits>

namespace PixelBufferLayout {

bool ResolveReadRowBytes(uint32_t width,
                         uint32_t height,
                         uint32_t rowStride,
                         uint32_t byteCount,
                         uint32_t* rowBytes) {
    const uint64_t tightRowBytes = static_cast<uint64_t>(width) * 4U;
    if (rowBytes == nullptr || width == 0 || height == 0 ||
        tightRowBytes > std::numeric_limits<uint32_t>::max() ||
        rowStride < tightRowBytes) {
        return false;
    }

    const uint64_t tightSize = tightRowBytes * height;
    const uint64_t stridedSize = static_cast<uint64_t>(rowStride) * height;
    if (tightSize > std::numeric_limits<uint32_t>::max() || byteCount < tightSize) {
        return false;
    }

    // ReadPixels/GetByteCount expose packed image bytes on aligned PixelMaps.
    // Keep the wider stride only when the returned buffer actually contains it.
    *rowBytes = byteCount >= stridedSize ? rowStride : static_cast<uint32_t>(tightRowBytes);
    return true;
}

}  // namespace PixelBufferLayout
