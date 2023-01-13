cmake_minimum_required(VERSION 3.21.2)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

set(PLUGIN_NAME "dart_wormhole_william")
set(PLUGIN_LIB ${PLUGIN_NAME}_plugin)

find_package(PkgConfig REQUIRED)

if(dart_wormhole_william_IS_TOP_LEVEL)
  set(WORMHOLE_WILLIAM_GO_DIR ${CMAKE_SOURCE_DIR}/../wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../lib/src)
else()
  set(WORMHOLE_WILLIAM_GO_DIR
      ${CMAKE_SOURCE_DIR}/../../${PLUGIN_NAME}/wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../../${PLUGIN_NAME}/lib/src)
endif()

set(GOOS ios)

# TODO remove these debug logs when done
# get_cmake_property(_variableNames VARIABLES)
# list (SORT _variableNames)
# foreach (_variableName ${_variableNames})
#     message(STATUS "fooy ${_variableName}=${${_variableName}}")
# endforeach()


string(REPLACE " " ";" $ENV{ARCHS_STANDARD} CMAKE_OSX_ARCHITECTURES)
set(CMAKE_SYSTEM_NAME "iOS")
set(GOARCH $ENV{PLATFORM_PREFERRED_ARCH})
set(SUPPORTED_ARCHS "arm64;amd64")

if(${GOARCH} STREQUAL "x86_64")
  set(GOARCH "amd64")
endif()

if (GOARCH IN_LIST SUPPORTED_ARCHS)
else()
  set(GOARCH "arm64")
endif()

add_library(${PLUGIN_LIB} STATIC "dart_wormhole_william_plugin.cc")
include(${DART_WORMHOLE_WILLIAM_C_DIR}/../../CMakeLists.txt)
include(${DART_WORMHOLE_WILLIAM_C_DIR}/CMakeLists.txt)

target_compile_definitions(${PLUGIN_LIB} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_LIB}
INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_LIB} PRIVATE bindings)

# List of absolute paths to libraries that should be bundled with the plugin
if(dart_wormhole_william_IS_TOP_LEVEL)
set(dart_wormhole_william_bundled_libraries $<TARGET_FILE:wormhole_william>
$<TARGET_FILE:bindings>)
else()
set(dart_wormhole_william_bundled_libraries $<TARGET_FILE:wormhole_william>
$<TARGET_FILE:bindings>
PARENT_SCOPE)

endif()
