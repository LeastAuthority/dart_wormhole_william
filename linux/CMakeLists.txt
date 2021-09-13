cmake_minimum_required(VERSION 3.21.2)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

set(WORMHOLE_WILLIAM_GO_DIR
    ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william)

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
include(${CMAKE_SOURCE_DIR}/../dart_wormhole_william/lib/src/CMakeLists.txt)

set(dart_wormhole_william_bundled_libraries
  "" ${WORMHOLE_WILLIAM_LIB} $<TARGET_FILE:bindings>
  PARENT_SCOPE)
