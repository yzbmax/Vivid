#include "../../napi/pixel_buffer_layout.h"

#include <cstdint>
#include <iostream>

namespace {

int failures = 0;

void Expect(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << std::endl;
        ++failures;
    }
}

}  // namespace

int main() {
    uint32_t rowBytes = 0;
    Expect(PixelBufferLayout::ResolveReadRowBytes(101, 2, 416, 808, &rowBytes),
           "accepts packed ReadPixels data when PixelMap stride is aligned");
    Expect(rowBytes == 404, "uses tight width when byte count excludes row padding");

    Expect(PixelBufferLayout::ResolveReadRowBytes(100, 2, 416, 832, &rowBytes),
           "accepts a fully strided PixelMap buffer");
    Expect(rowBytes == 416, "keeps the stride when the buffer contains padding");

    Expect(!PixelBufferLayout::ResolveReadRowBytes(100, 2, 416, 799, &rowBytes),
           "rejects a buffer shorter than one tight image");
    return failures == 0 ? 0 : 1;
}
