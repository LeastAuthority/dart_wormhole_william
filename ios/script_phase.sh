#!/bin/bash -x

# Note: For xcode to build, might need to set env
#export PATH=$PATH:/opt/homebrew/bin &&
#export FLUTTER_ROOT=/Users/donataspuidokas/Apps/flutter &&

cd $TARGET_BUILD_DIR

mkdir -p $TARGET_BUILD_DIR/Headers

# Note: For xcode build might need to set full path to cmake
cmake \
  -GXcode \
  -DCMAKE_OSX_SYSROOT=$SDK_DIR \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=$PLATFORM_PREFERRED_ARCH \
  -DPLATFORM_PREFERRED_ARCH=$PLATFORM_PREFERRED_ARCH \
  -DGOCMD=`which go` \
  -DGOROOT=`go env GOROOT` \
  -S $PODS_TARGET_SRCROOT

xcodebuild -alltargets -configuration $CONFIGURATION

cp -v \
  $TARGET_BUILD_DIR/$CONFIGURATION-$PLATFORM_NAME/{libbindings.a,libdart_wormhole_william_plugin.a} \
  $TARGET_BUILD_DIR/libwormhole_william.{h,a} \
  $PODS_CONFIGURATION_BUILD_DIR/
