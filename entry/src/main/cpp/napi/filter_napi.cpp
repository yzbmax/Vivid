#include "filter_napi.h"

#include "../filter/filter_engine.h"
#include "pixel_buffer_layout.h"

#include <multimedia/image_framework/image/pixelmap_native.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace {

FilterEngine g_engine;
std::mutex g_engineMutex;

struct RenderWork {
    napi_env env = nullptr;
    napi_deferred deferred = nullptr;
    napi_async_work work = nullptr;
    std::string filterId;
    float strength = 0.0f;
    int width = 0;
    int height = 0;
    int rowBytes = 0;
    std::vector<uint8_t> rgba;
    bool success = false;
    std::string error;
};

bool ReadString(napi_env env, napi_value value, std::string* result) {
    if (result == nullptr) {
        return false;
    }
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
        return false;
    }
    std::vector<char> buffer(length + 1, '\0');
    if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &length) != napi_ok) {
        return false;
    }
    result->assign(buffer.data(), length);
    return true;
}

napi_value Throw(napi_env env, const char* message) {
    napi_throw_error(env, nullptr, message);
    return nullptr;
}

napi_value CreateError(napi_env env, const std::string& message) {
    napi_value result = nullptr;
    if (napi_create_string_utf8(env, message.c_str(), NAPI_AUTO_LENGTH, &result) != napi_ok) {
        return nullptr;
    }
    return result;
}

void ExecuteRender(napi_env /*env*/, void* data) {
    auto* context = static_cast<RenderWork*>(data);
    if (context == nullptr) {
        return;
    }
    std::lock_guard<std::mutex> lock(g_engineMutex);
    context->success = g_engine.Render(context->rgba.data(), context->width,
                                       context->height, context->rowBytes,
                                       context->filterId, context->strength,
                                       &context->error);
    if (!context->success && context->error.empty()) {
        context->error = "Native filter render failed";
    }
}

bool CreateOutputPixelMap(RenderWork* context, napi_value* result) {
    if (context == nullptr || result == nullptr) {
        return false;
    }
    if (context->width <= 0 || context->height <= 0 ||
        context->width > std::numeric_limits<int>::max() / 4) {
        context->error = "Invalid output PixelMap dimensions";
        return false;
    }

    // PixelMap input buffers may have an aligned stride. Create the output
    // with a tight stride because the native PixelMap initializer rejects a
    // stride that does not exactly match the image width on some devices.
    const int outputRowBytes = context->width * 4;
    const size_t outputSize = static_cast<size_t>(outputRowBytes) *
                              static_cast<size_t>(context->height);
    uint8_t* outputData = context->rgba.data();
    std::vector<uint8_t> tightBuffer;
    if (context->rowBytes != outputRowBytes) {
        const size_t sourceRowBytes = static_cast<size_t>(context->rowBytes);
        const size_t sourceSize = sourceRowBytes * static_cast<size_t>(context->height);
        if (context->rowBytes < outputRowBytes || context->rgba.size() < sourceSize) {
            context->error = "Invalid source PixelMap stride";
            return false;
        }
        tightBuffer.resize(outputSize);
        for (int y = 0; y < context->height; ++y) {
            std::copy_n(context->rgba.data() + static_cast<size_t>(y) * sourceRowBytes,
                        outputRowBytes,
                        tightBuffer.data() + static_cast<size_t>(y) * outputRowBytes);
        }
        outputData = tightBuffer.data();
    } else if (context->rgba.size() < outputSize) {
        context->error = "Invalid output PixelMap buffer";
        return false;
    }

    OH_Pixelmap_InitializationOptions* options = nullptr;
    if (OH_PixelmapInitializationOptions_Create(&options) != IMAGE_SUCCESS || options == nullptr) {
        context->error = "Unable to allocate PixelMap options";
        return false;
    }
    const bool configured =
        OH_PixelmapInitializationOptions_SetWidth(options, static_cast<uint32_t>(context->width)) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetHeight(options, static_cast<uint32_t>(context->height)) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetRowStride(options, outputRowBytes) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetPixelFormat(options, PIXEL_FORMAT_RGBA_8888) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetSrcPixelFormat(options, PIXEL_FORMAT_RGBA_8888) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetAlphaType(options, PIXELMAP_ALPHA_TYPE_UNPREMULTIPLIED) == IMAGE_SUCCESS &&
        OH_PixelmapInitializationOptions_SetEditable(options, true) == IMAGE_SUCCESS;
    if (!configured) {
        OH_PixelmapInitializationOptions_Release(options);
        context->error = "Unable to configure PixelMap options";
        return false;
    }

    OH_PixelmapNative* output = nullptr;
    const Image_ErrorCode createResult = OH_PixelmapNative_CreateEmptyPixelmap(options, &output);
    OH_PixelmapInitializationOptions_Release(options);
    if (createResult != IMAGE_SUCCESS || output == nullptr) {
        context->error = "Unable to create output PixelMap";
        return false;
    }

    const Image_ErrorCode writeResult = OH_PixelmapNative_WritePixels(output, outputData, outputSize);
    if (writeResult != IMAGE_SUCCESS) {
        OH_PixelmapNative_Release(output);
        context->error = "Unable to write output PixelMap";
        return false;
    }

    const Image_ErrorCode convertResult =
        OH_PixelmapNative_ConvertPixelmapNativeToNapi(context->env, output, result);
    OH_PixelmapNative_Release(output);
    if (convertResult != IMAGE_SUCCESS) {
        context->error = "Unable to convert output PixelMap";
        return false;
    }
    return true;
}

void CompleteRender(napi_env env, napi_status status, void* data) {
    auto* context = static_cast<RenderWork*>(data);
    if (context == nullptr) {
        return;
    }
    if (status == napi_ok && context->success) {
        napi_value output = nullptr;
        if (CreateOutputPixelMap(context, &output)) {
            napi_resolve_deferred(env, context->deferred, output);
        } else {
            napi_reject_deferred(env, context->deferred, CreateError(env, context->error));
        }
    } else {
        const std::string message = context->error.empty() ? "Native filter render cancelled" : context->error;
        napi_reject_deferred(env, context->deferred, CreateError(env, message));
    }
    napi_delete_async_work(env, context->work);
    delete context;
}

napi_value LoadLut(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2] = {nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 2) {
        return Throw(env, "loadLut expects filterId and cubeText");
    }
    std::string filterId;
    std::string cubeText;
    if (!ReadString(env, argv[0], &filterId) || !ReadString(env, argv[1], &cubeText)) {
        return Throw(env, "loadLut arguments must be strings");
    }
    bool loaded = false;
    {
        std::lock_guard<std::mutex> lock(g_engineMutex);
        loaded = g_engine.LoadLut(filterId, cubeText);
    }
    napi_value result = nullptr;
    napi_get_boolean(env, loaded, &result);
    return result;
}

napi_value Render(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value argv[3] = {nullptr, nullptr, nullptr};
    if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 3) {
        return Throw(env, "render expects pixelMap, filterId and strength");
    }

    std::string filterId;
    double strength = 0.0;
    if (!ReadString(env, argv[1], &filterId) || napi_get_value_double(env, argv[2], &strength) != napi_ok ||
        !std::isfinite(strength)) {
        return Throw(env, "render arguments are invalid");
    }

    OH_PixelmapNative* source = nullptr;
    if (OH_PixelmapNative_ConvertPixelmapNativeFromNapi(env, argv[0], &source) != IMAGE_SUCCESS || source == nullptr) {
        return Throw(env, "pixelMap must be a valid PixelMap");
    }

    OH_Pixelmap_ImageInfo* imageInfo = nullptr;
    uint32_t width = 0;
    uint32_t height = 0;
    uint32_t rowStride = 0;
    int32_t pixelFormat = PIXEL_FORMAT_UNKNOWN;
    uint32_t byteCount = 0;
    const bool infoOk =
        OH_PixelmapImageInfo_Create(&imageInfo) == IMAGE_SUCCESS && imageInfo != nullptr &&
        OH_PixelmapNative_GetImageInfo(source, imageInfo) == IMAGE_SUCCESS &&
        OH_PixelmapImageInfo_GetWidth(imageInfo, &width) == IMAGE_SUCCESS &&
        OH_PixelmapImageInfo_GetHeight(imageInfo, &height) == IMAGE_SUCCESS &&
        OH_PixelmapImageInfo_GetRowStride(imageInfo, &rowStride) == IMAGE_SUCCESS &&
        OH_PixelmapImageInfo_GetPixelFormat(imageInfo, &pixelFormat) == IMAGE_SUCCESS &&
        OH_PixelmapNative_GetByteCount(source, &byteCount) == IMAGE_SUCCESS;
    if (imageInfo != nullptr) {
        OH_PixelmapImageInfo_Release(imageInfo);
    }
    const bool supportedFormat = pixelFormat == PIXEL_FORMAT_RGBA_8888 ||
                                 pixelFormat == PIXEL_FORMAT_BGRA_8888;
    uint32_t inputRowBytes = 0;
    const bool validBuffer = infoOk &&
                             PixelBufferLayout::ResolveReadRowBytes(
                                 width, height, rowStride, byteCount, &inputRowBytes);
    if (!validBuffer || !supportedFormat ||
        inputRowBytes > static_cast<uint32_t>(std::numeric_limits<int>::max())) {
        OH_PixelmapNative_Release(source);
        return Throw(env, "PixelMap must be non-empty 32-bit RGBA with a valid stride");
    }

    auto* context = new RenderWork();
    context->env = env;
    context->filterId = filterId;
    context->strength = FilterNapi::ClampStrength(static_cast<float>(strength));
    context->width = static_cast<int>(width);
    context->height = static_cast<int>(height);
    context->rowBytes = static_cast<int>(inputRowBytes);
    const size_t requiredBytes = static_cast<size_t>(inputRowBytes) * static_cast<size_t>(height);
    if (requiredBytes == 0 || byteCount < requiredBytes) {
        OH_PixelmapNative_Release(source);
        return Throw(env, "PixelMap buffer size is invalid");
    }
    context->rgba.resize(static_cast<size_t>(byteCount));
    size_t readSize = context->rgba.size();
    const Image_ErrorCode readResult =
        OH_PixelmapNative_ReadPixels(source, context->rgba.data(), &readSize);
    OH_PixelmapNative_Release(source);
    if (readResult != IMAGE_SUCCESS || readSize < requiredBytes) {
        delete context;
        return Throw(env, "Unable to copy PixelMap pixels");
    }

    // The image decoder normally supplies RGBA_8888, but some providers keep
    // BGRA_8888 despite the requested decode format. Normalize that layout
    // before the LUT renderer reads the channels.
    if (pixelFormat == PIXEL_FORMAT_BGRA_8888) {
        for (int y = 0; y < context->height; ++y) {
            uint8_t* row = context->rgba.data() + static_cast<size_t>(y) * context->rowBytes;
            for (int x = 0; x < context->width; ++x) {
                std::swap(row[x * 4], row[x * 4 + 2]);
            }
        }
    }

    napi_value promise = nullptr;
    if (napi_create_promise(env, &context->deferred, &promise) != napi_ok) {
        delete context;
        return Throw(env, "Unable to create render Promise");
    }
    napi_value resourceName = nullptr;
    if (napi_create_string_utf8(env, "VividLutRender", NAPI_AUTO_LENGTH, &resourceName) != napi_ok ||
        napi_create_async_work(env, nullptr, resourceName, ExecuteRender, CompleteRender, context,
                               &context->work) != napi_ok ||
        napi_queue_async_work(env, context->work) != napi_ok) {
        if (context->work != nullptr) {
            napi_delete_async_work(env, context->work);
        }
        napi_reject_deferred(env, context->deferred, CreateError(env, "Unable to queue render work"));
        delete context;
        return promise;
    }
    return promise;
}

napi_value Clear(napi_env env, napi_callback_info info) {
    (void)info;
    std::lock_guard<std::mutex> lock(g_engineMutex);
    g_engine.Clear();
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

}  // namespace

float FilterNapi::ClampStrength(float value) {
    return std::max(0.0f, std::min(1.0f, value));
}

napi_value FilterNapi::Init(napi_env env, napi_value exports) {
    const napi_property_descriptor properties[] = {
        {"loadLut", nullptr, LoadLut, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"render", nullptr, Render, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clear", nullptr, Clear, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    if (napi_define_properties(env, exports, 3, properties) != napi_ok) {
        return nullptr;
    }
    return exports;
}

NAPI_MODULE_INIT() {
    return FilterNapi::Init(env, exports);
}
