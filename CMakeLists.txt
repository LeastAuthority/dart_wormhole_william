set(WORMHOLE_WILLIAM_LIB
    ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libwormhole_william.so)

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
  set(EXPORT set)
else()
  set(EXPORT export)
endif()

file(GLOB_RECURSE WORMHOLE_WILLIAM_SRC_FILES ${WORMHOLE_WILLIAM_GO_DIR}/*.go ${WORMHOLE_WILLIAM_GO_DIR}/*.c)

#target_sources(wormhole_william
  #PUBLIC ${WORMHOLE_WILLIAM_SRC_FILES})

#add_custom_target(
  #wormhole_william
  #COMMENT Building go static library
  #SOURCES ${WORMHOLE_WILLIAM_SRC_FILES})

  


add_custom_command(OUTPUT ${WORMHOLE_WILLIAM_LIB}
  COMMAND ${EXPORT} CGO_ENABLED=1&&
          ${EXPORT} GOARCH=${GOARCH}&&
          ${EXPORT} GOOS=${GOOS}&&
          ${EXPORT} CC_FOR_TARGET=${CC_FOR_TARGET}&&
          ${EXPORT} CC=${CC_FOR_TARGET}&&
          go build -buildmode=c-shared -o ${WORMHOLE_WILLIAM_LIB} c/client.c.go c/callback.c.go
    DEPENDS ${WORMHOLE_WILLIAM_SRC_FILES}
    WORKING_DIRECTORY ${WORMHOLE_WILLIAM_GO_DIR})

add_library(
  wormhole_william
  SHARED)
  

set_target_properties(wormhole_william PROPERTIES
  LINKER_LANGUAGE C
  SOURCES ${WORMHOLE_WILLIAM_SRC_FILES}
  GLOBAL TRUE)
  


#add_custom_target(
  #BUILD_GO_LIBRARY ALL
  #COMMENT Building go static library
  #COMMAND ${EXPORT} CGO_ENABLED=1&&
          #${EXPORT} GOARCH=${GOARCH}&&
          #${EXPORT} GOOS=${GOOS}&&
          #${EXPORT} CC_FOR_TARGET=${CC_FOR_TARGET}&&
          #${EXPORT} CC=${CC_FOR_TARGET}&&
    #go build -buildmode=c-shared -o ${WORMHOLE_WILLIAM_LIB} c/client.c.go c/callback.c.go
  #USES_TERMINAL
  #BYPRODUCTS ${WORMHOLE_WILLIAM_LIB}
  #WORKING_DIRECTORY ${WORMHOLE_WILLIAM_GO_DIR})

#add_library(
  #WORMHOLE_GO
  #SHARED
  #IMPORTED
  #DEPENDS ${WORMHOLE_WILLIAM_LIB}
  #IMPORTED_LOCATION ${WORMHOLE_WILLIAM_LIB}
  #GLOBAL)


#include(CMakePrintHelpers)
#include(CMakePrintSystemInformation)

#add_custom_target(PWD ALL pwd USES_TERMINAL)

#add_library(
  #DART_WORMHOLE_API
  #SHARED
  #../dart_wormhole_william/lib/src/async_callback.c include/dart_api_dl.c
#)

#set_target_properties(DART_WORMHOLE_API PROPERTIES
  #PUBLIC_HEADER include/dart_version.h
  #PUBLIC_HEADER include/dart_api.h
  #PUBLIC_HEADER include/dart_api_dl.h
  #PUBLIC_HEADER include/dart_naitive_dl.h
  ## VERSION ${PROJECT_VERSION}
  #SOVERSION 1
  #OUTPUT_NAME "dart_wormhole_api"
#)

# target_link_libraries(${PLUGIN_NAME} PUBLIC ${WORMHOLE_GO DART_WORMHOLE_API)
# include(${CMAKE_SOURCE_DIR}/../dart_wormhole_william/lib/src/CMakeLists.txt)


target_link_libraries(${PLUGIN_NAME} PUBLIC $<TARGET_FILE:wormhole_william>)

get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()
