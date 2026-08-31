#include "filter_engine.h"

#include "cube_parser.h"

bool FilterEngine::LoadLut(const std::string& filterId, const std::string& cubeContent) {
    if (filterId.empty()) {
        return false;
    }
    try {
        // Parse once at load time; strength changes only reuse this cached Lut3D.
        Lut3D parsed = CubeParser::Parse(cubeContent);
        luts_[filterId] = std::move(parsed);
        renderer_.RemoveLut(filterId);
        return true;
    } catch (const std::exception&) {
        luts_.erase(filterId);
        return false;
    }
}

bool FilterEngine::HasLut(const std::string& filterId) const {
    return luts_.find(filterId) != luts_.end();
}

void FilterEngine::RemoveLut(const std::string& filterId) {
    renderer_.RemoveLut(filterId);
    luts_.erase(filterId);
}

void FilterEngine::Clear() {
    renderer_.ClearLutCache();
    luts_.clear();
}

bool FilterEngine::Render(uint8_t* rgba,
                          int width,
                          int height,
                          int rowBytes,
                          const std::string& filterId,
                          float strength,
                          std::string* error) {
    const auto it = luts_.find(filterId);
    if (it == luts_.end()) {
        if (error != nullptr) {
            *error = "LUT not loaded: " + filterId;
        }
        return false;
    }
    return renderer_.Render(rgba, width, height, rowBytes, filterId,
                            it->second, strength, error);
}
