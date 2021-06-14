cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES CXX C)

# This value is used when generating builds using this plugin, so it must not be
# changed
set(PLUGIN_NAME "dart_wormhole_william_plugin")

execute_process(
  COMMAND go tool cgo c/client.c.go COMMAND_ERROR_IS_FATAL LAST
  WORKING_DIRECTORY
    ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william)

set(WORMHOLE_C_WRAPPER_BASE "${CMAKE_SOURCE_DIR}/../wormhole-william/_obj")
file(GLOB_RECURSE WORMHOLE_C_WRAPPER_SRC ${WORMHOLE_C_WRAPPER_BASE}/*.c
     ${WORMHOLE_C_WRAPPER_BASE}/*.h)
add_library(${PLUGIN_NAME} SHARED "src/main/c/test.c;${WORMHOLE_C_WRAPPER_SRC}")
