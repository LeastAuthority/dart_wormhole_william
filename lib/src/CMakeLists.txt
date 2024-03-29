if(NOT DEFINED ENV{FLUTTER_ROOT})
  message(FATAL_ERROR "FLUTTER_ROOT environment variable must be defined")
else()
  file(TO_CMAKE_PATH $ENV{FLUTTER_ROOT} FLUTTER_ROOT)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	add_compile_options("-DDESTINY_DEBUG_LOGS")
endif()

set(DART_INCLUDE $ENV{FLUTTER_ROOT}/bin/cache/dart-sdk/include)

# For iOS only load static libraries
if (${CMAKE_SYSTEM_NAME} STREQUAL "iOS")
  add_library(
    bindings 
    STATIC 
    ${DART_WORMHOLE_WILLIAM_C_DIR}/async_callback.c
    ${DART_INCLUDE}/dart_api_dl.c
    ${DART_INCLUDE}/dart_api_dl.h
    )
else ()
  add_library(
    bindings SHARED ${DART_WORMHOLE_WILLIAM_C_DIR}/async_callback.c
    ${DART_INCLUDE}/dart_api_dl.c)
endif ()

target_include_directories(
  bindings
  PRIVATE ${WORMHOLE_WILLIAM_INCLUDE_DIR}
  PRIVATE ${WORMHOLE_WILLIAM_C_DIR}
  PRIVATE ${DART_INCLUDE})

add_dependencies(bindings wormhole_william)

target_link_libraries(bindings PRIVATE ${WORMHOLE_WILLIAM_LIB})

set_target_properties(
  bindings
  PROPERTIES PUBLIC_HEADER bindings.h
             OUTPUT_NAME "bindings"
             BUILD_WITH_INSTALL_RPATH TRUE)
