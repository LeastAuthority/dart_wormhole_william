cmake_minimum_required(VERSION 3.21.2)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

#include(FindPkgConfig)

#pkg_check_modules(GTK IMPORTED_TARGET gtk)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtkmm-3.0)

if(dart_wormhole_william_IS_TOP_LEVEL)
  set(WORMHOLE_WILLIAM_GO_DIR ${CMAKE_SOURCE_DIR}/../wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../lib/src)
else()
  set(WORMHOLE_WILLIAM_GO_DIR ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/lib/src)
endif()

# This value is used when generating builds using this plugin, so it must not be
# changed
set(PLUGIN_NAME "dart_wormhole_william_plugin")

add_library(${PLUGIN_NAME} SHARED "dart_wormhole_william_plugin.cc")

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME}
                           INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PUBLIC ${WORMHOLE_WILLIAM_LIB})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)

# List of absolute paths to libraries that should be bundled with the plugin

include(../CMakeLists.txt)
include(${DART_WORMHOLE_WILLIAM_C_DIR}/CMakeLists.txt)

if(dart_wormhole_william_IS_TOP_LEVEL)
  set(dart_wormhole_william_bundled_libraries
    "" ${WORMHOLE_WILLIAM_LIB} $<TARGET_FILE:bindings>)
else()
  set(dart_wormhole_william_bundled_libraries
    "" ${WORMHOLE_WILLIAM_LIB} $<TARGET_FILE:bindings>
    PARENT_SCOPE)
endif()
