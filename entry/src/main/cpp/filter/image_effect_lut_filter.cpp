#include "image_effect_lut_filter.h"

#include <multimedia/image_effect/image_effect_filter.h>

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <string>

namespace {

constexpr char kFilterName[] = "VividLutFilter";
constexpr char kIntensityKey[] = "FilterIntensity";

float ClampStrength(float value) {
    return std::max(0.0f, std::min(1.0f, value));
}

FilterEngine& DefaultEngine() {
    static FilterEngine engine;
    return engine;
}

}  // namespace

FilterEngine* VividLutFilter::engine_ = &DefaultEngine();
std::string VividLutFilter::activeFilterId_ = "identity";
float VividLutFilter::strength_ = 1.0f;

bool VividLutFilter::Register() {
    OH_EffectFilterInfo* info = OH_EffectFilterInfo_Create();
    if (info == nullptr) {
        return false;
    }

    ImageEffect_BufferType bufferTypes[] = {EFFECT_BUFFER_TYPE_PIXEL};
    ImageEffect_Format formats[] = {EFFECT_PIXEL_FORMAT_RGBA8888};
    const ImageEffect_FilterDelegate delegate = {
        &VividLutFilter::SetValue,
        &VividLutFilter::Render,
        &VividLutFilter::Save,
        &VividLutFilter::Restore
    };

    const bool configured =
        OH_EffectFilterInfo_SetFilterName(info, kFilterName) == EFFECT_SUCCESS &&
        OH_EffectFilterInfo_SetSupportedBufferTypes(info, 1, bufferTypes) == EFFECT_SUCCESS &&
        OH_EffectFilterInfo_SetSupportedFormats(info, 1, formats) == EFFECT_SUCCESS;
    const bool registered = configured &&
        OH_EffectFilter_Register(info, &delegate) == EFFECT_SUCCESS;
    OH_EffectFilterInfo_Release(info);
    return registered;
}

void VividLutFilter::SetEngine(FilterEngine* engine) {
    engine_ = engine == nullptr ? &DefaultEngine() : engine;
}

void VividLutFilter::SetActiveFilterId(const std::string& filterId) {
    if (!filterId.empty()) {
        activeFilterId_ = filterId;
    }
}

std::string VividLutFilter::ActiveFilterId() {
    return activeFilterId_;
}

void VividLutFilter::SetStrength(float strength) {
    strength_ = ClampStrength(strength);
}

float VividLutFilter::Strength() {
    return strength_;
}

bool VividLutFilter::SetValue(OH_EffectFilter* /*filter*/,
                              const char* key,
                              const ImageEffect_Any* value) {
    if (key == nullptr || value == nullptr || std::strcmp(key, kIntensityKey) != 0 ||
        value->dataType != EFFECT_DATA_TYPE_FLOAT) {
        return false;
    }
    SetStrength(value->dataValue.floatValue);
    return true;
}

bool VividLutFilter::Render(OH_EffectFilter* filter,
                            OH_EffectBufferInfo* info,
                            OH_EffectFilterDelegate_PushData pushData) {
    if (filter == nullptr || info == nullptr || engine_ == nullptr) {
        return false;
    }

    void* address = nullptr;
    int32_t width = 0;
    int32_t height = 0;
    int32_t rowSize = 0;
    ImageEffect_Format format = EFFECT_PIXEL_FORMAT_UNKNOWN;
    if (OH_EffectBufferInfo_GetAddr(info, &address) != EFFECT_SUCCESS ||
        OH_EffectBufferInfo_GetWidth(info, &width) != EFFECT_SUCCESS ||
        OH_EffectBufferInfo_GetHeight(info, &height) != EFFECT_SUCCESS ||
        OH_EffectBufferInfo_GetRowSize(info, &rowSize) != EFFECT_SUCCESS ||
        OH_EffectBufferInfo_GetEffectFormat(info, &format) != EFFECT_SUCCESS ||
        format != EFFECT_PIXEL_FORMAT_RGBA8888) {
        return false;
    }

    std::string renderError;
    if (!engine_->Render(static_cast<uint8_t*>(address), width, height, rowSize,
                         activeFilterId_, strength_, &renderError)) {
        return false;
    }
    if (pushData != nullptr) {
        pushData(filter, info);
    }
    return true;
}

bool VividLutFilter::Save(OH_EffectFilter* /*filter*/, char** info) {
    if (info == nullptr) {
        return false;
    }
    const std::string json = "{\"filterId\":\"" + activeFilterId_ +
                             "\",\"strength\":" + std::to_string(strength_) + "}";
    char* serialized = static_cast<char*>(std::malloc(json.size() + 1));
    if (serialized == nullptr) {
        return false;
    }
    std::memcpy(serialized, json.c_str(), json.size() + 1);
    *info = serialized;
    return true;
}

OH_EffectFilter* VividLutFilter::Restore(const char* info) {
    if (info == nullptr) {
        return nullptr;
    }
    const char* strengthStart = std::strstr(info, "\"strength\":");
    if (strengthStart == nullptr) {
        return nullptr;
    }
    const float strength = std::strtof(strengthStart + std::strlen("\"strength\":"), nullptr);
    OH_EffectFilter* filter = OH_EffectFilter_Create(kFilterName);
    if (filter == nullptr) {
        return nullptr;
    }
    ImageEffect_Any value;
    value.dataType = EFFECT_DATA_TYPE_FLOAT;
    value.dataValue.floatValue = ClampStrength(strength);
    if (OH_EffectFilter_SetValue(filter, kIntensityKey, &value) != EFFECT_SUCCESS) {
        OH_EffectFilter_Release(filter);
        return nullptr;
    }
    return filter;
}
