cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

# This value is used when generating builds using this plugin, so it must not be
# changed
set(PLUGIN_NAME "dart_wormhole_william_plugin")

execute_process(
  COMMAND go tool cgo c/client.c.go
  COMMAND_ERROR_IS_FATAL LAST
  WORKING_DIRECTORY
    ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william)

set(WORMHOLE_C_WRAPPER_BASE
    "${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william/_obj")
file(GLOB_RECURSE WORMHOLE_C_WRAPPER_SRC ${WORMHOLE_C_WRAPPER_BASE}/*.c
     ${WORMHOLE_C_WRAPPER_BASE}/*.h)
add_library(${PLUGIN_NAME} SHARED
            "dart_wormhole_william_plugin.cc;${WORMHOLE_C_WRAPPER_SRC}")

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(
  ${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include;${WORMHOLE_C_WRAPPER_BASE}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin
set(dart_wormhole_william_bundled_libraries
    ""
    PARENT_SCOPE)
