#include "../image_effect_lut_filter.h"

#include <iostream>
#include <string>

namespace {

int failures = 0;

void Expect(bool condition, const std::string& message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << std::endl;
        ++failures;
    }
}

}  // namespace

int main() {
    VividLutFilter::SetActiveFilterId("identity");
    VividLutFilter::SetStrength(-0.5f);
    Expect(VividLutFilter::Strength() == 0.0f,
           "filter strength is clamped at zero");
    VividLutFilter::SetStrength(1.5f);
    Expect(VividLutFilter::Strength() == 1.0f,
           "filter strength is clamped at one");
    Expect(VividLutFilter::ActiveFilterId() == "identity",
           "active filter id is retained outside render");
    return failures == 0 ? 0 : 1;
}
