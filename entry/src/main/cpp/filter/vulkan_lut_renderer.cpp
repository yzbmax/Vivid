#include "vulkan_lut_renderer.h"

#include "lut3d_spv.h"
#include "lut_renderer.h"
#include "vulkan_lut_contract.h"

#include <hilog/log.h>

#include <algorithm>
#include <array>
#include <cstring>
#include <limits>
#include <string>
#include <vector>

namespace {

constexpr uint32_t kLogDomain = 0xFF00;
constexpr const char* kLogTag = "VividVulkan";
constexpr uint64_t kFenceTimeoutNanoseconds = 5'000'000'000ULL;

struct PushConstants {
    uint32_t width;
    uint32_t height;
    uint32_t rowPixels;
    uint32_t lutSize;
    float strength;
    float domainMinR;
    float domainMinG;
    float domainMinB;
    float domainMaxR;
    float domainMaxG;
    float domainMaxB;
};

static_assert(sizeof(PushConstants) == 44, "Shader push constants must remain 44 bytes");

struct alignas(16) GpuLutNode {
    float r;
    float g;
    float b;
    float a;
};

void LogInfo(const char* message) {
    OH_LOG_Print(LOG_APP, LOG_INFO, kLogDomain, kLogTag, "%{public}s", message);
}

void LogError(const char* message) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, kLogDomain, kLogTag, "%{public}s", message);
}

}  // namespace

VulkanLutRenderer::~VulkanLutRenderer() {
    Cleanup();
}

bool VulkanLutRenderer::SetError(const std::string& message, std::string* error) const {
    if (error != nullptr) {
        *error = message;
    }
    LogError(message.c_str());
    return false;
}

bool VulkanLutRenderer::SetVulkanError(const char* stage,
                                       VkResult result,
                                       std::string* error) const {
    return SetError(std::string(stage) + " failed (VkResult=" +
                    std::to_string(static_cast<int>(result)) + ")", error);
}

bool VulkanLutRenderer::Initialize(std::string* error) {
    if (initialized_) {
        return true;
    }

    VkApplicationInfo applicationInfo{};
    applicationInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    applicationInfo.pApplicationName = "Vivid";
    applicationInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    applicationInfo.pEngineName = "VividLut";
    applicationInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
    applicationInfo.apiVersion = VK_API_VERSION_1_1;

    VkInstanceCreateInfo instanceInfo{};
    instanceInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instanceInfo.pApplicationInfo = &applicationInfo;
    VkResult result = vkCreateInstance(&instanceInfo, nullptr, &instance_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateInstance", result, error);
    }

    uint32_t deviceCount = 0;
    result = vkEnumeratePhysicalDevices(instance_, &deviceCount, nullptr);
    if (result != VK_SUCCESS || deviceCount == 0) {
        Cleanup();
        return result == VK_SUCCESS
                   ? SetError("No Vulkan physical device is available", error)
                   : SetVulkanError("vkEnumeratePhysicalDevices", result, error);
    }
    std::vector<VkPhysicalDevice> devices(deviceCount);
    result = vkEnumeratePhysicalDevices(instance_, &deviceCount, devices.data());
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkEnumeratePhysicalDevices", result, error);
    }

    bool queueFound = false;
    for (const VkPhysicalDevice candidate : devices) {
        uint32_t queueCount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(candidate, &queueCount, nullptr);
        std::vector<VkQueueFamilyProperties> queues(queueCount);
        vkGetPhysicalDeviceQueueFamilyProperties(candidate, &queueCount, queues.data());
        for (uint32_t index = 0; index < queueCount; ++index) {
            if (queues[index].queueCount > 0 &&
                (queues[index].queueFlags & VK_QUEUE_COMPUTE_BIT) != 0) {
                physicalDevice_ = candidate;
                computeQueueFamily_ = index;
                queueFound = true;
                break;
            }
        }
        if (queueFound) {
            break;
        }
    }
    if (!queueFound) {
        Cleanup();
        return SetError("No Vulkan compute queue is available", error);
    }

    constexpr float kQueuePriority = 1.0f;
    VkDeviceQueueCreateInfo queueInfo{};
    queueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueInfo.queueFamilyIndex = computeQueueFamily_;
    queueInfo.queueCount = 1;
    queueInfo.pQueuePriorities = &kQueuePriority;

    VkDeviceCreateInfo deviceInfo{};
    deviceInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    deviceInfo.queueCreateInfoCount = 1;
    deviceInfo.pQueueCreateInfos = &queueInfo;
    result = vkCreateDevice(physicalDevice_, &deviceInfo, nullptr, &device_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateDevice", result, error);
    }
    vkGetDeviceQueue(device_, computeQueueFamily_, 0, &computeQueue_);

    std::array<VkDescriptorSetLayoutBinding, 3> bindings{};
    for (uint32_t index = 0; index < bindings.size(); ++index) {
        bindings[index].binding = index;
        bindings[index].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        bindings[index].descriptorCount = 1;
        bindings[index].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    }
    VkDescriptorSetLayoutCreateInfo descriptorLayoutInfo{};
    descriptorLayoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    descriptorLayoutInfo.bindingCount = static_cast<uint32_t>(bindings.size());
    descriptorLayoutInfo.pBindings = bindings.data();
    result = vkCreateDescriptorSetLayout(device_, &descriptorLayoutInfo, nullptr,
                                         &descriptorSetLayout_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateDescriptorSetLayout", result, error);
    }

    VkShaderModuleCreateInfo shaderInfo{};
    shaderInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    shaderInfo.codeSize = sizeof(kVividLut3dShader);
    shaderInfo.pCode = kVividLut3dShader;
    result = vkCreateShaderModule(device_, &shaderInfo, nullptr, &shaderModule_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateShaderModule", result, error);
    }

    VkPushConstantRange pushRange{};
    pushRange.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    pushRange.offset = 0;
    pushRange.size = sizeof(PushConstants);
    VkPipelineLayoutCreateInfo pipelineLayoutInfo{};
    pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pipelineLayoutInfo.setLayoutCount = 1;
    pipelineLayoutInfo.pSetLayouts = &descriptorSetLayout_;
    pipelineLayoutInfo.pushConstantRangeCount = 1;
    pipelineLayoutInfo.pPushConstantRanges = &pushRange;
    result = vkCreatePipelineLayout(device_, &pipelineLayoutInfo, nullptr, &pipelineLayout_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreatePipelineLayout", result, error);
    }

    VkPipelineShaderStageCreateInfo shaderStage{};
    shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    shaderStage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
    shaderStage.module = shaderModule_;
    shaderStage.pName = "main";
    VkComputePipelineCreateInfo pipelineInfo{};
    pipelineInfo.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
    pipelineInfo.stage = shaderStage;
    pipelineInfo.layout = pipelineLayout_;
    result = vkCreateComputePipelines(device_, VK_NULL_HANDLE, 1, &pipelineInfo, nullptr,
                                      &pipeline_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateComputePipelines", result, error);
    }

    VkCommandPoolCreateInfo commandPoolInfo{};
    commandPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    commandPoolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    commandPoolInfo.queueFamilyIndex = computeQueueFamily_;
    result = vkCreateCommandPool(device_, &commandPoolInfo, nullptr, &commandPool_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateCommandPool", result, error);
    }

    VkDescriptorPoolSize poolSize{};
    poolSize.type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    poolSize.descriptorCount = 48;
    VkDescriptorPoolCreateInfo poolInfo{};
    poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    poolInfo.flags = VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
    poolInfo.maxSets = 16;
    poolInfo.poolSizeCount = 1;
    poolInfo.pPoolSizes = &poolSize;
    result = vkCreateDescriptorPool(device_, &poolInfo, nullptr, &descriptorPool_);
    if (result != VK_SUCCESS) {
        Cleanup();
        return SetVulkanError("vkCreateDescriptorPool", result, error);
    }

    initialized_ = true;
    VkPhysicalDeviceProperties properties{};
    vkGetPhysicalDeviceProperties(physicalDevice_, &properties);
    const std::string message = std::string("Initialized Vulkan device=") +
                                properties.deviceName + " queueFamily=" +
                                std::to_string(computeQueueFamily_);
    LogInfo(message.c_str());
    return true;
}

bool VulkanLutRenderer::FindHostMemoryType(uint32_t typeBits,
                                           uint32_t* memoryType) const {
    if (memoryType == nullptr || physicalDevice_ == VK_NULL_HANDLE) {
        return false;
    }
    VkPhysicalDeviceMemoryProperties properties{};
    vkGetPhysicalDeviceMemoryProperties(physicalDevice_, &properties);
    constexpr VkMemoryPropertyFlags kRequired =
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
    for (uint32_t index = 0; index < properties.memoryTypeCount; ++index) {
        if ((typeBits & (1u << index)) != 0 &&
            (properties.memoryTypes[index].propertyFlags & kRequired) == kRequired) {
            *memoryType = index;
            return true;
        }
    }
    return false;
}

bool VulkanLutRenderer::CreateBuffer(VkDeviceSize size,
                                     VkBufferUsageFlags usage,
                                     Buffer* output,
                                     std::string* error) {
    if (output == nullptr || size == 0) {
        return SetError("Invalid Vulkan buffer request", error);
    }
    VkBufferCreateInfo bufferInfo{};
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = size;
    bufferInfo.usage = usage;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    VkResult result = vkCreateBuffer(device_, &bufferInfo, nullptr, &output->handle);
    if (result != VK_SUCCESS) {
        return SetVulkanError("vkCreateBuffer", result, error);
    }

    VkMemoryRequirements requirements{};
    vkGetBufferMemoryRequirements(device_, output->handle, &requirements);
    uint32_t memoryType = 0;
    if (!FindHostMemoryType(requirements.memoryTypeBits, &memoryType)) {
        DestroyBuffer(output);
        return SetError("No host-visible coherent Vulkan memory type", error);
    }
    VkMemoryAllocateInfo allocationInfo{};
    allocationInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocationInfo.allocationSize = requirements.size;
    allocationInfo.memoryTypeIndex = memoryType;
    result = vkAllocateMemory(device_, &allocationInfo, nullptr, &output->memory);
    if (result != VK_SUCCESS) {
        DestroyBuffer(output);
        return SetVulkanError("vkAllocateMemory", result, error);
    }
    result = vkBindBufferMemory(device_, output->handle, output->memory, 0);
    if (result != VK_SUCCESS) {
        DestroyBuffer(output);
        return SetVulkanError("vkBindBufferMemory", result, error);
    }
    output->size = size;
    return true;
}

bool VulkanLutRenderer::WriteBuffer(const Buffer& buffer,
                                    const void* data,
                                    VkDeviceSize size,
                                    std::string* error) {
    if (data == nullptr || size > buffer.size) {
        return SetError("Invalid Vulkan buffer write", error);
    }
    void* mapped = nullptr;
    const VkResult result = vkMapMemory(device_, buffer.memory, 0, size, 0, &mapped);
    if (result != VK_SUCCESS) {
        return SetVulkanError("vkMapMemory(write)", result, error);
    }
    std::memcpy(mapped, data, static_cast<std::size_t>(size));
    vkUnmapMemory(device_, buffer.memory);
    return true;
}

bool VulkanLutRenderer::ReadBuffer(const Buffer& buffer,
                                   void* data,
                                   VkDeviceSize size,
                                   std::string* error) {
    if (data == nullptr || size > buffer.size) {
        return SetError("Invalid Vulkan buffer read", error);
    }
    void* mapped = nullptr;
    const VkResult result = vkMapMemory(device_, buffer.memory, 0, size, 0, &mapped);
    if (result != VK_SUCCESS) {
        return SetVulkanError("vkMapMemory(read)", result, error);
    }
    std::memcpy(data, mapped, static_cast<std::size_t>(size));
    vkUnmapMemory(device_, buffer.memory);
    return true;
}

bool VulkanLutRenderer::EnsureLut(const std::string& filterId,
                                  const Lut3D& lut,
                                  Buffer** output,
                                  std::string* error) {
    if (output == nullptr || filterId.empty() || lut.data.size() != Lut3D::NODE_COUNT) {
        return SetError("Invalid LUT upload request", error);
    }
    const auto existing = lutBuffers_.find(filterId);
    if (existing != lutBuffers_.end()) {
        *output = &existing->second;
        return true;
    }

    std::vector<GpuLutNode> packed;
    packed.reserve(lut.data.size());
    for (const RgbFloat& node : lut.data) {
        packed.push_back({node.r, node.g, node.b, 1.0f});
    }
    const VkDeviceSize byteSize =
        static_cast<VkDeviceSize>(packed.size()) * sizeof(GpuLutNode);
    Buffer buffer{};
    if (!CreateBuffer(byteSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, &buffer, error) ||
        !WriteBuffer(buffer, packed.data(), byteSize, error)) {
        DestroyBuffer(&buffer);
        return false;
    }
    const auto inserted = lutBuffers_.emplace(filterId, buffer);
    *output = &inserted.first->second;
    const std::string message = "Uploaded LUT filter=" + filterId +
                                " nodes=" + std::to_string(lut.data.size());
    LogInfo(message.c_str());
    return true;
}

bool VulkanLutRenderer::Render(uint8_t* rgba,
                               int width,
                               int height,
                               int rowBytes,
                               const std::string& filterId,
                               const Lut3D& lut,
                               float strength,
                               std::string* error) {
    if (!VulkanLutContract::ValidateImageLayout(width, height, rowBytes)) {
        return SetError("Invalid RGBA image layout for Vulkan", error);
    }
    if (rgba == nullptr || filterId.empty() || lut.data.size() != Lut3D::NODE_COUNT) {
        return SetError("Invalid Vulkan LUT render request", error);
    }
    if (!Initialize(error)) {
        return false;
    }

    Buffer* lutBuffer = nullptr;
    if (!EnsureLut(filterId, lut, &lutBuffer, error)) {
        return false;
    }
    const VkDeviceSize imageSize =
        static_cast<VkDeviceSize>(rowBytes) * static_cast<VkDeviceSize>(height);
    const std::vector<uint8_t> originalPixels(
        rgba, rgba + static_cast<std::size_t>(imageSize));
    Buffer input{};
    Buffer output{};
    VkDescriptorSet descriptorSet = VK_NULL_HANDLE;
    VkCommandBuffer commandBuffer = VK_NULL_HANDLE;
    VkFence fence = VK_NULL_HANDLE;

    auto cleanupRender = [&]() {
        if (fence != VK_NULL_HANDLE) {
            vkDestroyFence(device_, fence, nullptr);
        }
        if (commandBuffer != VK_NULL_HANDLE) {
            vkFreeCommandBuffers(device_, commandPool_, 1, &commandBuffer);
        }
        if (descriptorSet != VK_NULL_HANDLE) {
            vkFreeDescriptorSets(device_, descriptorPool_, 1, &descriptorSet);
        }
        DestroyBuffer(&output);
        DestroyBuffer(&input);
    };

    if (!CreateBuffer(imageSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, &input, error) ||
        !CreateBuffer(imageSize, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, &output, error) ||
        !WriteBuffer(input, rgba, imageSize, error) ||
        !WriteBuffer(output, rgba, imageSize, error)) {
        cleanupRender();
        return false;
    }

    VkDescriptorSetAllocateInfo descriptorAllocateInfo{};
    descriptorAllocateInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    descriptorAllocateInfo.descriptorPool = descriptorPool_;
    descriptorAllocateInfo.descriptorSetCount = 1;
    descriptorAllocateInfo.pSetLayouts = &descriptorSetLayout_;
    VkResult result = vkAllocateDescriptorSets(device_, &descriptorAllocateInfo, &descriptorSet);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkAllocateDescriptorSets", result, error);
    }

    const std::array<VkDescriptorBufferInfo, 3> bufferInfos = {{
        {input.handle, 0, input.size},
        {output.handle, 0, output.size},
        {lutBuffer->handle, 0, lutBuffer->size}
    }};
    std::array<VkWriteDescriptorSet, 3> writes{};
    for (uint32_t index = 0; index < writes.size(); ++index) {
        writes[index].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
        writes[index].dstSet = descriptorSet;
        writes[index].dstBinding = index;
        writes[index].descriptorCount = 1;
        writes[index].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        writes[index].pBufferInfo = &bufferInfos[index];
    }
    vkUpdateDescriptorSets(device_, static_cast<uint32_t>(writes.size()), writes.data(), 0,
                           nullptr);

    VkCommandBufferAllocateInfo commandAllocateInfo{};
    commandAllocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    commandAllocateInfo.commandPool = commandPool_;
    commandAllocateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    commandAllocateInfo.commandBufferCount = 1;
    result = vkAllocateCommandBuffers(device_, &commandAllocateInfo, &commandBuffer);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkAllocateCommandBuffers", result, error);
    }

    VkCommandBufferBeginInfo beginInfo{};
    beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    result = vkBeginCommandBuffer(commandBuffer, &beginInfo);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkBeginCommandBuffer", result, error);
    }

    VkMemoryBarrier hostToCompute{};
    hostToCompute.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER;
    hostToCompute.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT;
    hostToCompute.dstAccessMask = VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT;
    vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_HOST_BIT,
                         VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &hostToCompute, 0,
                         nullptr, 0, nullptr);

    vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline_);
    vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipelineLayout_,
                            0, 1, &descriptorSet, 0, nullptr);
    const PushConstants pushConstants = {
        static_cast<uint32_t>(width),
        static_cast<uint32_t>(height),
        static_cast<uint32_t>(rowBytes / 4),
        static_cast<uint32_t>(Lut3D::SIZE),
        VulkanLutContract::ClampStrength(strength),
        0.0f, 0.0f, 0.0f,
        1.0f, 1.0f, 1.0f
    };
    vkCmdPushConstants(commandBuffer, pipelineLayout_, VK_SHADER_STAGE_COMPUTE_BIT, 0,
                       sizeof(PushConstants), &pushConstants);
    vkCmdDispatch(commandBuffer,
                  (static_cast<uint32_t>(width) + 15u) / 16u,
                  (static_cast<uint32_t>(height) + 15u) / 16u,
                  1);

    VkMemoryBarrier computeToHost{};
    computeToHost.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER;
    computeToHost.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT;
    computeToHost.dstAccessMask = VK_ACCESS_HOST_READ_BIT;
    vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                         VK_PIPELINE_STAGE_HOST_BIT, 0, 1, &computeToHost, 0, nullptr, 0,
                         nullptr);
    result = vkEndCommandBuffer(commandBuffer);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkEndCommandBuffer", result, error);
    }

    VkFenceCreateInfo fenceInfo{};
    fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    result = vkCreateFence(device_, &fenceInfo, nullptr, &fence);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkCreateFence", result, error);
    }
    VkSubmitInfo submitInfo{};
    submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &commandBuffer;
    result = vkQueueSubmit(computeQueue_, 1, &submitInfo, fence);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkQueueSubmit", result, error);
    }
    result = vkWaitForFences(device_, 1, &fence, VK_TRUE, kFenceTimeoutNanoseconds);
    if (result != VK_SUCCESS) {
        cleanupRender();
        return SetVulkanError("vkWaitForFences", result, error);
    }
    if (!ReadBuffer(output, rgba, imageSize, error)) {
        cleanupRender();
        return false;
    }

    const bool gpuPixelsChanged =
        std::memcmp(rgba, originalPixels.data(), static_cast<std::size_t>(imageSize)) != 0;
    bool usedCpuFallback = false;
    if (VulkanLutContract::ShouldUseCpuFallback(gpuPixelsChanged, strength)) {
        std::memcpy(rgba, originalPixels.data(), static_cast<std::size_t>(imageSize));
        if (!LutRenderer::Render(rgba, width, height, rowBytes, lut, strength)) {
            cleanupRender();
            return SetError("CPU LUT fallback failed after unchanged Vulkan output", error);
        }
        usedCpuFallback = true;
    }

    cleanupRender();
    const std::string message = "Dispatched filter=" + filterId + " size=" +
                                std::to_string(width) + "x" + std::to_string(height) +
                                " strength=" + std::to_string(strength) +
                                " backend=" + (usedCpuFallback ? "cpu-fallback" : "vulkan");
    LogInfo(message.c_str());
    return true;
}

void VulkanLutRenderer::RemoveLut(const std::string& filterId) {
    const auto found = lutBuffers_.find(filterId);
    if (found == lutBuffers_.end()) {
        return;
    }
    DestroyBuffer(&found->second);
    lutBuffers_.erase(found);
}

void VulkanLutRenderer::ClearLutCache() {
    for (auto& entry : lutBuffers_) {
        DestroyBuffer(&entry.second);
    }
    lutBuffers_.clear();
}

void VulkanLutRenderer::DestroyBuffer(Buffer* buffer) {
    if (buffer == nullptr || device_ == VK_NULL_HANDLE) {
        return;
    }
    if (buffer->handle != VK_NULL_HANDLE) {
        vkDestroyBuffer(device_, buffer->handle, nullptr);
    }
    if (buffer->memory != VK_NULL_HANDLE) {
        vkFreeMemory(device_, buffer->memory, nullptr);
    }
    *buffer = {};
}

void VulkanLutRenderer::Cleanup() {
    if (device_ != VK_NULL_HANDLE) {
        vkDeviceWaitIdle(device_);
        ClearLutCache();
        if (descriptorPool_ != VK_NULL_HANDLE) {
            vkDestroyDescriptorPool(device_, descriptorPool_, nullptr);
        }
        if (commandPool_ != VK_NULL_HANDLE) {
            vkDestroyCommandPool(device_, commandPool_, nullptr);
        }
        if (pipeline_ != VK_NULL_HANDLE) {
            vkDestroyPipeline(device_, pipeline_, nullptr);
        }
        if (pipelineLayout_ != VK_NULL_HANDLE) {
            vkDestroyPipelineLayout(device_, pipelineLayout_, nullptr);
        }
        if (shaderModule_ != VK_NULL_HANDLE) {
            vkDestroyShaderModule(device_, shaderModule_, nullptr);
        }
        if (descriptorSetLayout_ != VK_NULL_HANDLE) {
            vkDestroyDescriptorSetLayout(device_, descriptorSetLayout_, nullptr);
        }
        vkDestroyDevice(device_, nullptr);
    }
    if (instance_ != VK_NULL_HANDLE) {
        vkDestroyInstance(instance_, nullptr);
    }
    initialized_ = false;
    instance_ = VK_NULL_HANDLE;
    physicalDevice_ = VK_NULL_HANDLE;
    device_ = VK_NULL_HANDLE;
    computeQueue_ = VK_NULL_HANDLE;
    computeQueueFamily_ = 0;
    descriptorSetLayout_ = VK_NULL_HANDLE;
    shaderModule_ = VK_NULL_HANDLE;
    pipelineLayout_ = VK_NULL_HANDLE;
    pipeline_ = VK_NULL_HANDLE;
    commandPool_ = VK_NULL_HANDLE;
    descriptorPool_ = VK_NULL_HANDLE;
}
