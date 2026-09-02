#ifndef VIVID_VULKAN_LUT_RENDERER_H
#define VIVID_VULKAN_LUT_RENDERER_H

#include "lut3d.h"

#include <vulkan/vulkan.h>

#include <cstdint>
#include <string>
#include <unordered_map>

class VulkanLutRenderer {
public:
    VulkanLutRenderer() = default;
    ~VulkanLutRenderer();

    VulkanLutRenderer(const VulkanLutRenderer&) = delete;
    VulkanLutRenderer& operator=(const VulkanLutRenderer&) = delete;

    bool Render(uint8_t* rgba,
                int width,
                int height,
                int rowBytes,
                const std::string& filterId,
                const Lut3D& lut,
                float strength,
                std::string* error);

    void RemoveLut(const std::string& filterId);
    void ClearLutCache();

private:
    struct Buffer {
        VkBuffer handle = VK_NULL_HANDLE;
        VkDeviceMemory memory = VK_NULL_HANDLE;
        VkDeviceSize size = 0;
    };

    bool Initialize(std::string* error);
    bool CreateBuffer(VkDeviceSize size,
                      VkBufferUsageFlags usage,
                      Buffer* output,
                      std::string* error);
    bool WriteBuffer(const Buffer& buffer,
                     const void* data,
                     VkDeviceSize size,
                     std::string* error);
    bool ReadBuffer(const Buffer& buffer,
                    void* data,
                    VkDeviceSize size,
                    std::string* error);
    bool EnsureLut(const std::string& filterId,
                   const Lut3D& lut,
                   Buffer** output,
                   std::string* error);
    bool FindHostMemoryType(uint32_t typeBits, uint32_t* memoryType) const;
    bool SetVulkanError(const char* stage, VkResult result, std::string* error) const;
    bool SetError(const std::string& message, std::string* error) const;
    void DestroyBuffer(Buffer* buffer);
    void Cleanup();

    bool initialized_ = false;
    VkInstance instance_ = VK_NULL_HANDLE;
    VkPhysicalDevice physicalDevice_ = VK_NULL_HANDLE;
    VkDevice device_ = VK_NULL_HANDLE;
    VkQueue computeQueue_ = VK_NULL_HANDLE;
    uint32_t computeQueueFamily_ = 0;
    VkDescriptorSetLayout descriptorSetLayout_ = VK_NULL_HANDLE;
    VkShaderModule shaderModule_ = VK_NULL_HANDLE;
    VkPipelineLayout pipelineLayout_ = VK_NULL_HANDLE;
    VkPipeline pipeline_ = VK_NULL_HANDLE;
    VkCommandPool commandPool_ = VK_NULL_HANDLE;
    VkDescriptorPool descriptorPool_ = VK_NULL_HANDLE;
    std::unordered_map<std::string, Buffer> lutBuffers_;
};

#endif  // VIVID_VULKAN_LUT_RENDERER_H
