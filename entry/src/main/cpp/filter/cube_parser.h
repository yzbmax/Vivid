#ifndef VIVID_CUBE_PARSER_H
#define VIVID_CUBE_PARSER_H

#include "lut3d.h"

#include <string>

class CubeParser {
public:
    static Lut3D Parse(const std::string& text);
};

#endif  // VIVID_CUBE_PARSER_H
