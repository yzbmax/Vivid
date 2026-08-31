#include "../filter_engine.h"

#include <cstdint>
#include <iostream>
#include <sstream>
#include <string>

namespace {

int failures = 0;

void Expect(bool condition, const std::string& message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << std::endl;
        ++failures;
    }
}

std::string IdentityCube() {
    std::ostringstream out;
    out << "LUT_3D_SIZE 33\n";
    for (int b = 0; b < 33; ++b) {
        for (int g = 0; g < 33; ++g) {
            for (int r = 0; r < 33; ++r) {
                out << static_cast<float>(r) / 32.0f << ' '
                    << static_cast<float>(g) / 32.0f << ' '
                    << static_cast<float>(b) / 32.0f << '\n';
            }
        }
    }
    return out.str();
}

}  // namespace

int main() {
    FilterEngine engine;
    Expect(engine.LoadLut("identity", IdentityCube()), "loads a valid LUT");
    Expect(engine.HasLut("identity"), "reports cached LUT");

    uint8_t pixel[] = {12, 128, 240, 99};
    std::string renderError;
    Expect(engine.Render(pixel, 1, 1, 4, "identity", 1.0f, &renderError),
           "renders through cached LUT");
    Expect(pixel[0] == 12 && pixel[1] == 128 && pixel[2] == 240 && pixel[3] == 99,
           "identity engine render preserves pixels");
    Expect(!engine.Render(pixel, 1, 1, 4, "missing", 1.0f, &renderError),
           "unknown LUT render fails without throwing");
    Expect(renderError == "LUT not loaded: missing",
           "unknown LUT render exposes an actionable error");

    engine.RemoveLut("identity");
    Expect(!engine.HasLut("identity"), "removes one cached LUT");
    Expect(!engine.LoadLut("broken", "LUT_3D_SIZE 17\n"),
           "rejects invalid LUT without poisoning cache");
    engine.LoadLut("identity", IdentityCube());
    engine.Clear();
    Expect(!engine.HasLut("identity"), "clear releases all cached LUTs");

    return failures == 0 ? 0 : 1;
}
