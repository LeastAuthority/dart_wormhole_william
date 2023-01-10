# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dart_wormhole_william.podspec` to validate before publishing.
#2>&1 | tee logs.txt
Pod::Spec.new do |s|
  s.name             = 'dart_wormhole_william'
  s.version          = '0.0.1'
  s.summary          = 'Flutter Wormhole-William plugin for iOS'

  s.script_phases = [
    { :name => 'Helpful for debugging', :script => 'env 2>&1 | tee $CODESIGNING_FOLDER_PATH/buildenv_$arch.txt', :execution_position => :before_compile },
    { :name => 'Build project', :script => 'cd $TARGET_BUILD_DIR && mkdir -p $TARGET_BUILD_DIR/Headers && cmake --trace -GXcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=$(tr " " ";" <<< $ARCHS) -DGOCMD=$(which go) -S $PODS_TARGET_SRCROOT && xcodebuild -alltargets && cp -v $TARGET_BUILD_DIR/$CONFIGURATION-$PLATFORM_NAME/{libbindings.a,libdart_wormhole_william_plugin.a} $TARGET_BUILD_DIR/$PLATFORM_PREFERRED_ARCH/libwormhole_william.{h,a} $PODS_CONFIGURATION_BUILD_DIR/',
      :output_files => [
        "$PODS_CONFIGURATION_BUILD_DIR/libbindings.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libdart_wormhole_william_plugin.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libwormhole_william.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libwormhole_william.h",
      ],
      :execution_position => :before_compile
    },
    # { :name => 'Make another copy', :script => 'cp -v $TARGET_BUILD_DIR/$CONFIGURATION-$PLATFORM_NAME/{libbindings.a,libdart_wormhole_william_plugin.a} $TARGET_BUILD_DIR/libwormhole_william.{h,a} $CODESIGNING_FOLDER_PATH',
      # :output_files => [
        # "$CODESIGNING_FOLDER_PATH/libbindings.a",
        # "$CODESIGNING_FOLDER_PATH/libdart_wormhole_william_plugin.a",
        # "$CODESIGNING_FOLDER_PATH/libwormhole_william.a",
        # "$CODESIGNING_FOLDER_PATH/libwormhole_william.h",
      # ],
      # :execution_position => :after_compile
    # },
  ]

  s.description      = "Flutter Wormhole-William plugin for iOS"

  s.homepage         = 'https://github.com/LeastAuthority/destiny/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Least Authority' => 'destiny@leastauthority.com' }
  s.source           = { :path => '.' }
  s.ios.source_files     = 'Classes/**/*'
  # s.libraries = 'wormhole_william', 'bindings', 'dart_wormhole_william_plugin'
  s.dependency  'Flutter'

  s.ios.deployment_target  = '12.0'

  s.platform = :ios
  s.ios.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # 'OTHER_LDFLAGS' => "",
    'OTHER_LDFLAGS' => "-L$(TARGET_BUILD_DIR)/$(CONFIGURATION)-$(PLATFORM_NAME) -force_load $(PODS_CONFIGURATION_BUILD_DIR)/libbindings.a $(PODS_CONFIGURATION_BUILD_DIR)/libdart_wormhole_william_plugin.a $(PODS_CONFIGURATION_BUILD_DIR)/libwormhole_william.a"
  }
  s.swift_version = '5.0'

end
