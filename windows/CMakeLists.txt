cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "dart_wormhole_william")
project(${PROJECT_NAME} LANGUAGES C CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "dart_wormhole_william_plugin")

add_library(${PLUGIN_NAME} SHARED
  "dart_wormhole_william_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

if(dart_wormhole_william_IS_TOP_LEVEL)
  set(WORMHOLE_WILLIAM_GO_DIR ${CMAKE_SOURCE_DIR}/wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/lib/src)
else()
  set(WORMHOLE_WILLIAM_GO_DIR
      ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/wormhole-william)
  set(DART_WORMHOLE_WILLIAM_C_DIR ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/lib/src)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/../CMakeLists.txt)

if(NOT DEFINED ENV{FLUTTER_ROOT})
  message(FATAL_ERROR "FLUTTER_ROOT environment variable must be defined")
else()
  file(TO_CMAKE_PATH $ENV{FLUTTER_ROOT} FLUTTER_ROOT)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(EXTRA_GCC_FLAGS "-DDESTINY_DEBUG_LOGS -g")
else()
  set(EXTRA_GCC_FLAGS "")
endif()

set(DART_INCLUDE ${FLUTTER_ROOT}/bin/cache/dart-sdk/include)

set(BINDINGS_LIB ${CMAKE_CURRENT_BINARY_DIR}/bindings.dll)
set(BINDINGS_DEF ${CMAKE_CURRENT_BINARY_DIR}/bindings.def)
set(BINDINGS_IMLIB ${CMAKE_CURRENT_BINARY_DIR}/bindings.lib)

add_custom_command(
  OUTPUT ${BINDINGS_LIB} ${BINDINGS_IMLIB}
  COMMENT Building client C bindings
  COMMAND
    gcc -shared -o ${BINDINGS_LIB}
      ${CMAKE_CURRENT_SOURCE_DIR}/../lib/src/async_callback.c
      ${DART_INCLUDE}/dart_api_dl.c
      -lwormhole_william
      -L${CMAKE_CURRENT_BINARY_DIR}
      -I${CMAKE_CURRENT_BINARY_DIR}
      -I${WORMHOLE_WILLIAM_C_DIR}
      -I${DART_INCLUDE}
      -Wl,--output-def,${BINDINGS_DEF}
      ${EXTRA_GCC_FLAGS}
  COMMAND lib /def:${BINDINGS_DEF} /out:${BINDINGS_IMLIB} /machine:x64
  USES_TERMINAL
  DEPENDS ${WORMHOLE_WILLIAM_HEADER} ${WORMHOLE_WILLIAM_LIB})

add_custom_target(
  bindings_target DEPENDS ${BINDINGS_LIB} ${BINDINGS_IMLIB})

add_library(
  bindings
  SHARED
  IMPORTED
  GLOBAL)

add_dependencies(bindings bindings_target)

set_target_properties(
  bindings
  PROPERTIES LINKER_LANGUAGE C
             IMPORTED_LOCATION ${BINDINGS_LIB}
             IMPORTED_IMPLIB ${BINDINGS_IMLIB})

add_dependencies(${PLUGIN_NAME} bindings)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin bindings)

# List of absolute paths to libraries that should be bundled with the plugin
set(dart_wormhole_william_bundled_libraries
  ""
  $<TARGET_FILE:bindings>
  $<TARGET_FILE:wormhole_william>
  PARENT_SCOPE
)
