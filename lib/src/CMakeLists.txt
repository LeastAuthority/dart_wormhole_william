# cmake_minimum_required(VERSION 3.7 FATAL_ERROR) project(bindings VERSION 1.0.0
# LANGUAGES C)

# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)

if(NOT DEFINED ENV{FLUTTER_HOME})
  message(FATAL_ERROR "Flutter home must be defined")
endif()

add_library(
  bindings SHARED ${CMAKE_SOURCE_DIR}/../dart_wormhole_william/lib/src/async_callback.c
  $ENV{FLUTTER_HOME}/bin/cache/dart-sdk/include/dart_api_dl.c)
target_include_directories(bindings
  PUBLIC $ENV{FLUTTER_HOME}/bin/cache/dart-sdk/include)
target_include_directories(bindings PRIVATE flutter_INCLUDE_DIRECTORIES)
target_include_directories(bindings PRIVATE dart_INCLUDE_DIRECTORIES)
target_link_libraries(bindings PUBLIC flutter)
# target_link_libraries(bindings INTERFACE dart) add_executable(bindings_test
# bindings.c include/dart_api_dl.c)

#get_cmake_property(_variableNames VARIABLES)
#list(SORT _variableNames)
#foreach(_variableName ${_variableNames})
  #message(STATUS "${_variableName}=${${_variableName}}")
#endforeach()

set_target_properties(
  bindings
  PROPERTIES PUBLIC_HEADER bindings.h
             PUBLIC_HEADER include/dart_version.h
             PUBLIC_HEADER include/dart_api.h
             PUBLIC_HEADER include/dart_api_dl.h
             PUBLIC_HEADER include/dart_naitive_dl.h
             VERSION 1.0.0
             SOVERSION 1
             OUTPUT_NAME "bindings")
