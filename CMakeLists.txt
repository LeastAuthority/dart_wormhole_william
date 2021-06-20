set(WORMHOLE_WILLIAM_LIB
    ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libwormhole_william.so)

add_custom_target(
  BUILD_GO_LIBRARY ALL
  COMMENT Building
  go static library
  # TODO I couldn't find a better way to pass the environment variables, but I
  # believe there should be
  COMMAND
    CGO_ENABLED=1 GOARCH=${GOARCH} GOOS=${GOOS} CC_FOR_TARGET=${CC_FOR_TARGET}
    CC=${CC_FOR_TARGET} go build -buildmode=c-shared -o ${WORMHOLE_WILLIAM_LIB}
    ./c/client.c.go
  USES_TERMINAL
  BYPRODUCTS ${WORMHOLE_WILLIAM_LIB}
  WORKING_DIRECTORY ${WORMHOLE_WILLIAM_GO_DIR})

add_library(
  WORMHOLE_GO
  SHARED
  IMPORTED
  DEPENDS ${WORMHOLE_WILLIAM_LIB}
  IMPORTED_LOCATION ${WORMHOLE_WILLIAM_LIB}
  GLOBAL)

target_link_libraries(${PLUGIN_NAME} PUBLIC ${WORMHOLE_WILLIAM_LIB})
