cmake_minimum_required(VERSION 3.18.1)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

set(PLUGIN_NAME "dart_wormhole_william")
set(PLUGIN_LIB ${PLUGIN_NAME}_plugin)

set(WORMHOLE_WILLIAM_GO_DIR "${CMAKE_SOURCE_DIR}/../wormhole-william")
set(DART_WORMHOLE_WILLIAM_C_DIR "${CMAKE_SOURCE_DIR}/../lib/src")

# The golden GOOS
set(GOOS android)

if(ANDROID_ABI STREQUAL "x86_64")
  set(GOARCH "amd64")
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
  set(GOARCH "arm64")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
  set(GOARCH "arm")
elseif(ANDROID_ABI STREQUAL "x86")
  set(GOARCH "386")
else()
  message(FATAL_ERROR "Unrecognized ANDROID_ABI ${ANDROID_ABI}")
endif()

set(CC_FOR_TARGET
    ${ANDROID_TOOLCHAIN_ROOT}/bin/${CMAKE_C_COMPILER_TARGET}-clang)

# Fix the clang triplet used as parameter for -target flag. compiler with -none-
# are not in the ndk
string(REPLACE "-none" "" CC_FOR_TARGET ${CC_FOR_TARGET})

# For some reason CMAKE_C_COMPILER_TARGET is named differently for this
# architecture than the one that comes with the ndk armv7 vs armv7a
string(REPLACE "armv7-" "armv7a-" CC_FOR_TARGET ${CC_FOR_TARGET})

add_library(${PLUGIN_LIB} SHARED "src/main/c/dummy.c")
include(${DART_WORMHOLE_WILLIAM_C_DIR}/../../CMakeLists.txt)
include(${DART_WORMHOLE_WILLIAM_C_DIR}/CMakeLists.txt)

target_link_libraries(${PLUGIN_LIB} PRIVATE bindings)
# TODO figure out how not to add this as a dependency of the plugin
# bindings has wormhole_william as a dependency so this should
# not be needed. However on startup dlopen fails when this is
# not added as a direct dependency of the plugin
target_link_libraries(${PLUGIN_LIB} PRIVATE wormhole_william)

set(dart_wormhole_william_bundled_libraries $<TARGET_FILE:wormhole_william>
                                            $<TARGET_FILE:bindings>)
