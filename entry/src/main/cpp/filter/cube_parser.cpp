#include "cube_parser.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {

constexpr float kDomainMin = 0.0f;
constexpr float kDomainMax = 1.0f;
constexpr float kEpsilon = 0.000001f;

std::string Trim(const std::string& value) {
    const std::size_t first = value.find_first_not_of(" \t\r");
    if (first == std::string::npos) {
        return "";
    }
    const std::size_t last = value.find_last_not_of(" \t\r");
    return value.substr(first, last - first + 1);
}

bool NearlyEqual(float left, float right) {
    return std::fabs(left - right) <= kEpsilon;
}

bool IsFiniteRgb(const RgbFloat& rgb) {
    // .cube output samples may intentionally overshoot the input domain.
    // Preserve finite extended-range values and clamp only the final pixels.
    return std::isfinite(rgb.r) && std::isfinite(rgb.g) &&
           std::isfinite(rgb.b);
}

std::size_t SourceIndex(int size, int r, int g, int b) {
    return static_cast<std::size_t>(b) * static_cast<std::size_t>(size) * size +
           static_cast<std::size_t>(g) * size + static_cast<std::size_t>(r);
}

RgbFloat Mix(const RgbFloat& first, const RgbFloat& second, float amount) {
    return {
        first.r * (1.0f - amount) + second.r * amount,
        first.g * (1.0f - amount) + second.g * amount,
        first.b * (1.0f - amount) + second.b * amount
    };
}

RgbFloat SampleGrid(const std::vector<RgbFloat>& nodes, int size,
                    float r, float g, float b) {
    const float maxCoordinate = static_cast<float>(size - 1);
    const float x = std::clamp(r, 0.0f, 1.0f) * maxCoordinate;
    const float y = std::clamp(g, 0.0f, 1.0f) * maxCoordinate;
    const float z = std::clamp(b, 0.0f, 1.0f) * maxCoordinate;
    const int r0 = static_cast<int>(std::floor(x));
    const int g0 = static_cast<int>(std::floor(y));
    const int b0 = static_cast<int>(std::floor(z));
    const int r1 = std::min(r0 + 1, size - 1);
    const int g1 = std::min(g0 + 1, size - 1);
    const int b1 = std::min(b0 + 1, size - 1);
    const float tr = x - static_cast<float>(r0);
    const float tg = y - static_cast<float>(g0);
    const float tb = z - static_cast<float>(b0);

    const auto at = [&](int ir, int ig, int ib) {
        return nodes[SourceIndex(size, ir, ig, ib)];
    };
    const RgbFloat x00 = Mix(at(r0, g0, b0), at(r1, g0, b0), tr);
    const RgbFloat x10 = Mix(at(r0, g1, b0), at(r1, g1, b0), tr);
    const RgbFloat x01 = Mix(at(r0, g0, b1), at(r1, g0, b1), tr);
    const RgbFloat x11 = Mix(at(r0, g1, b1), at(r1, g1, b1), tr);
    return Mix(Mix(x00, x10, tg), Mix(x01, x11, tg), tb);
}

Lut3D ResampleToOutputGrid(const std::vector<RgbFloat>& nodes, int sourceSize) {
    Lut3D result;
    result.data.reserve(Lut3D::NODE_COUNT);
    for (int b = 0; b < Lut3D::SIZE; ++b) {
        for (int g = 0; g < Lut3D::SIZE; ++g) {
            for (int r = 0; r < Lut3D::SIZE; ++r) {
                result.data.push_back(SampleGrid(
                    nodes, sourceSize,
                    static_cast<float>(r) / (Lut3D::SIZE - 1),
                    static_cast<float>(g) / (Lut3D::SIZE - 1),
                    static_cast<float>(b) / (Lut3D::SIZE - 1)));
            }
        }
    }
    return result;
}

void EnsureNoExtraTokens(std::istringstream& line, const std::string& context) {
    std::string extra;
    if (line >> extra) {
        throw std::runtime_error("CubeParser: extra token in " + context);
    }
}

RgbFloat ParseRgb(const std::string& source) {
    std::istringstream line(source);
    RgbFloat rgb{};
    if (!(line >> rgb.r >> rgb.g >> rgb.b)) {
        throw std::runtime_error("CubeParser: RGB row must contain three numbers");
    }
    EnsureNoExtraTokens(line, "RGB row");
    if (!IsFiniteRgb(rgb)) {
        throw std::runtime_error("CubeParser: RGB row contains a non-finite value");
    }
    return rgb;
}

}  // namespace

Lut3D CubeParser::Parse(const std::string& text) {
    std::istringstream input(text);
    std::vector<RgbFloat> nodes;
    nodes.reserve(Lut3D::NODE_COUNT);

    bool hasSize = false;
    int cubeSize = 0;
    bool hasDomainMin = false;
    bool hasDomainMax = false;
    std::string rawLine;
    std::size_t lineNumber = 0;

    while (std::getline(input, rawLine)) {
        ++lineNumber;
        const std::string lineText = Trim(rawLine);
        if (lineText.empty() || lineText[0] == '#') {
            continue;
        }
        if (lineText.find("LUT_1D_SIZE") != std::string::npos) {
            throw std::runtime_error("CubeParser: LUT_1D_SIZE and shaper LUTs are unsupported");
        }

        std::istringstream directive(lineText);
        std::string keyword;
        directive >> keyword;
        if (keyword == "TITLE") {
            // TITLE is metadata; keep the rest opaque but require a line.
            continue;
        }
        if (keyword == "LUT_3D_SIZE") {
            int size = 0;
            if (hasSize || !(directive >> size)) {
                throw std::runtime_error("CubeParser: invalid LUT_3D_SIZE at line " +
                                         std::to_string(lineNumber));
            }
            EnsureNoExtraTokens(directive, "LUT_3D_SIZE");
            if (size != 2 && size != 16 && size != Lut3D::SIZE) {
                throw std::runtime_error("CubeParser: only LUT_3D_SIZE 2, 16 or 33 is supported");
            }
            cubeSize = size;
            hasSize = true;
            continue;
        }
        if (keyword == "DOMAIN_MIN" || keyword == "DOMAIN_MAX") {
            float r = 0.0f;
            float g = 0.0f;
            float b = 0.0f;
            if (!(directive >> r >> g >> b)) {
                throw std::runtime_error("CubeParser: invalid domain at line " +
                                         std::to_string(lineNumber));
            }
            EnsureNoExtraTokens(directive, keyword);
            const bool isMin = keyword == "DOMAIN_MIN";
            const bool valid = isMin ? NearlyEqual(r, 0.0f) && NearlyEqual(g, 0.0f) &&
                                            NearlyEqual(b, 0.0f)
                                      : NearlyEqual(r, 1.0f) && NearlyEqual(g, 1.0f) &&
                                            NearlyEqual(b, 1.0f);
            if (!valid) {
                throw std::runtime_error("CubeParser: domain must be 0..1");
            }
            if (isMin) {
                if (hasDomainMin) {
                    throw std::runtime_error("CubeParser: duplicate DOMAIN_MIN");
                }
                hasDomainMin = true;
            } else {
                if (hasDomainMax) {
                    throw std::runtime_error("CubeParser: duplicate DOMAIN_MAX");
                }
                hasDomainMax = true;
            }
            continue;
        }

        if (!hasSize) {
            throw std::runtime_error("CubeParser: LUT_3D_SIZE must precede RGB data");
        }
        const std::size_t expectedNodeCount = static_cast<std::size_t>(cubeSize) * cubeSize * cubeSize;
        if (nodes.size() >= expectedNodeCount) {
            throw std::runtime_error("CubeParser: too many RGB rows");
        }
        try {
            nodes.push_back(ParseRgb(lineText));
        } catch (const std::exception& error) {
            throw std::runtime_error("CubeParser: line " + std::to_string(lineNumber) +
                                     ": " + error.what());
        }
    }

    if (!hasSize) {
        throw std::runtime_error("CubeParser: missing LUT_3D_SIZE");
    }
    const std::size_t expectedNodeCount = static_cast<std::size_t>(cubeSize) * cubeSize * cubeSize;
    if (nodes.size() != expectedNodeCount) {
        throw std::runtime_error("CubeParser: RGB row count does not match LUT_3D_SIZE");
    }

    if (cubeSize == Lut3D::SIZE) {
        Lut3D result;
        result.data = std::move(nodes);
        return result;
    }
    return ResampleToOutputGrid(nodes, cubeSize);
}
