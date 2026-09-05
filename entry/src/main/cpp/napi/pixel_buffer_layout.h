#ifndef VIVID_PIXEL_BUFFER_LAYOUT_H
#define VIVID_PIXEL_BUFFER_LAYOUT_H

#include <cstdint>

namespace PixelBufferLayout {

/**
 * Resolve the row width of the buffer returned by OH_PixelmapNative_ReadPixels.
 * GetByteCount reports the image bytes without alignment padding, while the
 * PixelMap image info may expose an aligned row stride.
 */
bool ResolveReadRowBytes(uint32_t width,
                         uint32_t height,
                         uint32_t rowStride,
                         uint32_t byteCount,
                         uint32_t* rowBytes);

}  // namespace PixelBufferLayout

#endif  // VIVID_PIXEL_BUFFER_LAYOUT_H
