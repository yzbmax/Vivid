#ifndef VIVID_IMAGE_EFFECT_LUT_FILTER_H
#define VIVID_IMAGE_EFFECT_LUT_FILTER_H

#include "filter_engine.h"

#include <string>

class VividLutFilter {
public:
    static bool Register();

    static void SetEngine(FilterEngine* engine);
    static void SetActiveFilterId(const std::string& filterId);
    static std::string ActiveFilterId();
    static void SetStrength(float strength);
    static float Strength();

private:
    static bool SetValue(struct OH_EffectFilter* filter,
                         const char* key,
                         const struct ImageEffect_Any* value);
    static bool Render(struct OH_EffectFilter* filter,
                       struct OH_EffectBufferInfo* info,
                       void (*pushData)(struct OH_EffectFilter*, struct OH_EffectBufferInfo*));
    static bool Save(struct OH_EffectFilter* filter, char** info);
    static struct OH_EffectFilter* Restore(const char* info);

    static FilterEngine* engine_;
    static std::string activeFilterId_;
    static float strength_;
};

#endif  // VIVID_IMAGE_EFFECT_LUT_FILTER_H
