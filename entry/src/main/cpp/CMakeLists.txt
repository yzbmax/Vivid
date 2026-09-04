cmake_minimum_required(VERSION 3.5.0)
project(vivid_image)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(vivid_image SHARED
    filter/cube_parser.cpp
    filter/lut_renderer.cpp
    filter/filter_engine.cpp
    filter/image_effect_lut_filter.cpp
    filter/vulkan_lut_renderer.cpp
    filter/tests/filter_engine_contract_test.cpp
    filter/tests/vulkan_lut_contract_test.cpp
    napi/pixel_buffer_layout.cpp
    napi/filter_napi.cpp
)

target_include_directories(vivid_image PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/filter
    ${CMAKE_CURRENT_SOURCE_DIR}/filter/generated
    ${CMAKE_CURRENT_SOURCE_DIR}/napi
)

target_compile_definitions(vivid_image PRIVATE
    NODE_GYP_MODULE_NAME=vivid_image
)

target_compile_options(vivid_image PRIVATE
    -fexceptions
    -frtti
)

target_link_libraries(vivid_image PUBLIC
    image_effect
    pixelmap
    pixelmap_ndk.z
    ace_napi.z
    hilog_ndk.z
    vulkan
)
