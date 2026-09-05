#include "../cube_parser.h"

#include <cmath>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

namespace {

int failures = 0;

void Expect(bool condition, const std::string& message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << std::endl;
        ++failures;
    }
}

void ExpectParseFailure(const std::string& cube, const std::string& name) {
    try {
        (void)CubeParser::Parse(cube);
        Expect(false, name + " should be rejected");
    } catch (const std::exception&) {
        // Expected parser rejection.
    }
}

std::string IdentityCube(int size) {
    std::ostringstream out;
    out << "# parser fixture\n"
        << "TITLE \"Identity fixture\"\n"
        << "LUT_3D_SIZE " << size << "\n"
        << "DOMAIN_MIN 0 0 0\n"
        << "DOMAIN_MAX 1 1 1\n";
    const float max = static_cast<float>(size - 1);
    for (int b = 0; b < size; ++b) {
        for (int g = 0; g < size; ++g) {
            for (int r = 0; r < size; ++r) {
                out << static_cast<float>(r) / max << ' '
                    << static_cast<float>(g) / max << ' '
                    << static_cast<float>(b) / max << '\n';
            }
        }
    }
    return out.str();
}

std::string Header() {
    return "LUT_3D_SIZE 33\n";
}

std::string ExtendedRangeCube16() {
    std::ostringstream out;
    out << "TITLE \"Extended range fixture\"\n"
        << "LUT_3D_SIZE 16\n";
    for (int b = 0; b < 16; ++b) {
        for (int g = 0; g < 16; ++g) {
            for (int r = 0; r < 16; ++r) {
                out << static_cast<float>(r) / 15.0f - 0.1f << ' '
                    << static_cast<float>(g) / 15.0f << ' '
                    << static_cast<float>(b) / 15.0f + 0.1f << '\n';
            }
        }
    }
    return out.str();
}

std::string RepeatedData(int count) {
    std::ostringstream out;
    for (int i = 0; i < count; ++i) {
        out << "0 0 0\n";
    }
    return out.str();
}

}  // namespace

int main() {
    const Lut3D lut = CubeParser::Parse(IdentityCube(33));
    Expect(lut.data.size() == 35937U, "33^3 RGB nodes are parsed");
    Expect(std::fabs(lut.data.front().r - 0.0f) < 0.0001f,
           "first node keeps its red value");
    Expect(std::fabs(lut.data.back().b - 1.0f) < 0.0001f,
           "last node keeps its blue value");

    const Lut3D lut16 = CubeParser::Parse(IdentityCube(16));
    Expect(lut16.data.size() == 35937U, "16^3 LUTs are resampled to 33^3");
    Expect(std::fabs(lut16.data[Lut3D::Index(16, 16, 16)].r - 0.5f) < 0.0001f,
           "resampled 16^3 LUT keeps the midpoint");

    const Lut3D lut2 = CubeParser::Parse(IdentityCube(2));
    Expect(lut2.data.size() == 35937U, "2^3 LUTs are resampled to 33^3");
    Expect(std::fabs(lut2.data[Lut3D::Index(16, 16, 16)].r - 0.5f) < 0.0001f,
           "resampled 2^3 LUT keeps the midpoint");

    const Lut3D extended = CubeParser::Parse(ExtendedRangeCube16());
    Expect(std::fabs(extended.data.front().r + 0.1f) < 0.0001f,
           "finite LUT output below zero is preserved");
    Expect(std::fabs(extended.data.back().b - 1.1f) < 0.0001f,
           "finite LUT output above one is preserved");

    ExpectParseFailure(Header() + RepeatedData(35936), "short data");
    ExpectParseFailure(Header() + RepeatedData(35938), "long data");
    ExpectParseFailure("LUT_3D_SIZE 17\n" + RepeatedData(35937), "size 17");
    ExpectParseFailure("LUT_3D_SIZE 65\n" + RepeatedData(35937), "size 65");
    ExpectParseFailure(Header() + "not numbers\n" + RepeatedData(35936),
                       "invalid RGB text");
    ExpectParseFailure(Header() + "nan 0 0\n" + RepeatedData(35936), "NaN");
    ExpectParseFailure(Header() + "0 inf 0\n" + RepeatedData(35936), "Infinity");
    ExpectParseFailure("LUT_1D_SIZE 33\n" + RepeatedData(35937), "1D LUT");
    ExpectParseFailure("LUT_3D_SIZE 33\nDOMAIN_MIN 0 0 0.1\n" +
                           RepeatedData(35937),
                       "non-zero DOMAIN_MIN");
    ExpectParseFailure("LUT_3D_SIZE 33\nDOMAIN_MAX 1 1 0.9\n" +
                           RepeatedData(35937),
                       "non-one DOMAIN_MAX");

    return failures == 0 ? 0 : 1;
}
