if(NOT DEFINED ENV{FLUTTER_HOME})
  message(FATAL_ERROR "Flutter home must be defined")
endif()

add_library(
  bindings SHARED ${DART_WORMHOLE_WILLIAM_C_DIR}/async_callback.c
                  $ENV{FLUTTER_HOME}/bin/cache/dart-sdk/include/dart_api_dl.c)
target_include_directories(
  bindings PRIVATE $ENV{FLUTTER_HOME}/bin/cache/dart-sdk/include)
target_include_directories(bindings PRIVATE ${flutter_INCLUDE_DIRECTORIES})
target_include_directories(bindings PRIVATE ${WORMHOLE_WILLIAM_INCLUDE_DIR})
target_include_directories(bindings PRIVATE ${WORMHOLE_WILLIAM_C_DIR})
target_link_libraries(bindings PRIVATE $<TARGET_FILE:wormhole_william>)

set_target_properties(
  bindings
  PROPERTIES PUBLIC_HEADER bindings.h
             PUBLIC_HEADER include/dart_version.h
             PUBLIC_HEADER include/dart_api.h
             PUBLIC_HEADER include/dart_api_dl.h
             PUBLIC_HEADER include/dart_naitive_dl.h
             OUTPUT_NAME "bindings")
