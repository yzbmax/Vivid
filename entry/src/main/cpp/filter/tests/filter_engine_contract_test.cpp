#include "../filter_engine.h"

#include <cstdint>
#include <string>
#include <type_traits>

using ExpectedRenderSignature = bool (FilterEngine::*)(
    uint8_t*, int, int, int, const std::string&, float, std::string*);

static_assert(std::is_same_v<decltype(&FilterEngine::Render), ExpectedRenderSignature>,
              "FilterEngine::Render must preserve actionable backend errors");
