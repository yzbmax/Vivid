#ifndef VIVID_FILTER_ENGINE_H
#define VIVID_FILTER_ENGINE_H

#include "lut3d.h"
#include "vulkan_lut_renderer.h"

#include <cstddef>
#include <cstdint>
#include <list>
#include <string>
#include <unordered_map>

class FilterEngine {
public:
    static constexpr size_t kDefaultMaxLutCache = 64;

    explicit FilterEngine(size_t maxCacheSize = kDefaultMaxLutCache);

    bool LoadLut(const std::string& filterId, const std::string& cubeContent);

    bool HasLut(const std::string& filterId) const;

    void RemoveLut(const std::string& filterId);

    void Clear();

    size_t CachedLutCount() const;

    bool Render(uint8_t* rgba,
                int width,
                int height,
                int rowBytes,
                const std::string& filterId,
                float strength,
                std::string* error);

private:
    void TouchLru(const std::string& filterId);
    void EvictLruIfNeeded();

    size_t maxCacheSize_;
    std::unordered_map<std::string, Lut3D> luts_;
    std::list<std::string> lruOrder_;
    std::unordered_map<std::string, std::list<std::string>::iterator> lruIterators_;
    VulkanLutRenderer renderer_;
};

#endif  // VIVID_FILTER_ENGINE_H
