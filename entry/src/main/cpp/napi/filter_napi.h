#ifndef VIVID_FILTER_NAPI_H
#define VIVID_FILTER_NAPI_H

#include <napi/native_api.h>

class FilterNapi {
public:
    static float ClampStrength(float value);
    static napi_value Init(napi_env env, napi_value exports);
};

#endif  // VIVID_FILTER_NAPI_H
