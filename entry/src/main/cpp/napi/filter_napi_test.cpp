#include "filter_napi.h"

#include <iostream>

int main() {
    if (FilterNapi::ClampStrength(-1.0f) != 0.0f ||
        FilterNapi::ClampStrength(2.0f) != 1.0f ||
        FilterNapi::ClampStrength(0.42f) != 0.42f) {
        std::cerr << "FilterNapi strength clamp failed" << std::endl;
        return 1;
    }
    return 0;
}
