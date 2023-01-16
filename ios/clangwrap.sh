#!/usr/bin/env bash -x
# This uses the latest available iOS SDK, which is recommended.
# To select a specific SDK, run 'xcodebuild -showsdks'
# to see the available SDKs and replace iphoneos with one of them.
#
# Copied with modification from $(go env GOROOT)/misc/ios/clangwrap.sh
# Modifications:
#   - Use SHALLOW_BUNDLE_TRIPLE, SDK_NAME and NATIVE_ARCH_ACTUAL
#   instead of using GOARCH to infer them

SDK_PATH=`xcrun --sdk $SDK_NAME --show-sdk-path`
export IPHONEOS_DEPLOYMENT_TARGET=5.1
# cmd/cgo doesn't support llvm-gcc-4.2, so we have to use clang.
CLANG=`xcrun --sdk $SDK_NAME --find clang`

exec "$CLANG" -arch $NATIVE_ARCH_ACTUAL -isysroot "$SDK_PATH" -m${SHALLOW_BUNDLE_TRIPLE}-version-min=12.0 "$@"
