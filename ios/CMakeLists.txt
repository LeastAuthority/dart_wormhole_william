cmake_minimum_required(VERSION 3.21.2)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

set(PLUGIN_NAME "dart_wormhole_william")
set(PLUGIN_LIB ${PLUGIN_NAME}_plugin)

find_package(PkgConfig REQUIRED)

set(GOOS ios)

if(dart_wormhole_william_IS_TOP_LEVEL)
  set(WORMHOLE_WILLIAM_GO_DIR ${CMAKE_SOURCE_DIR}/../wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../lib/src)
else()
  set(WORMHOLE_WILLIAM_GO_DIR
      ${CMAKE_SOURCE_DIR}/../../${PLUGIN_NAME}/wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../../${PLUGIN_NAME}/lib/src)
endif()

set(GOARCH "arm64")

add_library(${PLUGIN_LIB} SHARED "dart_wormhole_william_plugin.cc")
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
