#ifndef VIVID_FILTER_ENGINE_H
#define VIVID_FILTER_ENGINE_H

#include "lut3d.h"
#include "vulkan_lut_renderer.h"

#include <cstdint>
#include <string>
#include <unordered_map>

class FilterEngine {
public:
    bool LoadLut(const std::string& filterId, const std::string& cubeContent);

    bool HasLut(const std::string& filterId) const;

    void RemoveLut(const std::string& filterId);

    void Clear();

    bool Render(uint8_t* rgba,
                int width,
                int height,
                int rowBytes,
                const std::string& filterId,
                float strength,
                std::string* error);

private:
    std::unordered_map<std::string, Lut3D> luts_;
    VulkanLutRenderer renderer_;
};

#endif  // VIVID_FILTER_ENGINE_H
