#include "filter_engine.h"

#include "cube_parser.h"
#include "lut_renderer.h"

FilterEngine::FilterEngine(size_t maxCacheSize)
    : maxCacheSize_(maxCacheSize > 0 ? maxCacheSize : kDefaultMaxLutCache) {}

void FilterEngine::TouchLru(const std::string& filterId) {
    auto it = lruIterators_.find(filterId);
    if (it != lruIterators_.end()) {
        lruOrder_.erase(it->second);
    }
    lruOrder_.push_front(filterId);
    lruIterators_[filterId] = lruOrder_.begin();
}

void FilterEngine::EvictLruIfNeeded() {
    while (luts_.size() > maxCacheSize_ && !lruOrder_.empty()) {
        const std::string victim = lruOrder_.back();
        lruOrder_.pop_back();
        lruIterators_.erase(victim);
        luts_.erase(victim);
        renderer_.RemoveLut(victim);
    }
}

bool FilterEngine::LoadLut(const std::string& filterId, const std::string& cubeContent) {
    if (filterId.empty()) {
        return false;
    }
    try {
        // Parse once at load time; strength changes only reuse this cached Lut3D.
        Lut3D parsed = CubeParser::Parse(cubeContent);
        luts_[filterId] = std::move(parsed);
        renderer_.RemoveLut(filterId);
        TouchLru(filterId);
        EvictLruIfNeeded();
        return true;
    } catch (const std::exception&) {
        RemoveLut(filterId);
        return false;
    }
}

bool FilterEngine::HasLut(const std::string& filterId) const {
    return luts_.find(filterId) != luts_.end();
}

void FilterEngine::RemoveLut(const std::string& filterId) {
    renderer_.RemoveLut(filterId);
    luts_.erase(filterId);
    auto it = lruIterators_.find(filterId);
    if (it != lruIterators_.end()) {
        lruOrder_.erase(it->second);
        lruIterators_.erase(it);
    }
}

void FilterEngine::Clear() {
    renderer_.ClearLutCache();
    luts_.clear();
    lruOrder_.clear();
    lruIterators_.clear();
}

size_t FilterEngine::CachedLutCount() const {
    return luts_.size();
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
    TouchLru(filterId);

    std::string vkError;
    if (renderer_.Render(rgba, width, height, rowBytes, filterId,
                         it->second, strength, &vkError)) {
        return true;
    }
    if (LutRenderer::Render(rgba, width, height, rowBytes, it->second, strength)) {
        return true;
    }
    if (error != nullptr) {
        *error = vkError.empty() ? "Filter render failed" : vkError;
    }
    return false;
}
