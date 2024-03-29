# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dart_wormhole_william.podspec` to validate before publishing.
#2>&1 | tee logs.txt
Pod::Spec.new do |s|
  s.name             = 'dart_wormhole_william'
  s.version          = '0.0.1'
  s.summary          = 'Flutter Wormhole-William plugin for iOS'

  s.script_phases = [
    { :name => 'Helpful for debugging', :script => 'env 2>&1 | tee $CODESIGNING_FOLDER_PATH/buildenv_$PLATFORM_PREFERRED_ARCH.txt', :execution_position => :before_compile },    
    { :name => 'Build project', :script => '${PODS_TARGET_SRCROOT}/script_phase.sh',
      :output_files => [
        "$PODS_CONFIGURATION_BUILD_DIR/libbindings.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libdart_wormhole_william_plugin.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libwormhole_william.a",
        "$PODS_CONFIGURATION_BUILD_DIR/libwormhole_william.h",
      ],
      :execution_position => :before_compile
    },
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
  s.swift_version = '5.0'

  s.ios.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # 'OTHER_LDFLAGS' => "",
    'OTHER_LDFLAGS' => "-L$(TARGET_BUILD_DIR)/$(CONFIGURATION)-$(PLATFORM_NAME) -force_load $(PODS_CONFIGURATION_BUILD_DIR)/libbindings.a $(PODS_CONFIGURATION_BUILD_DIR)/libdart_wormhole_william_plugin.a $(PODS_CONFIGURATION_BUILD_DIR)/libwormhole_william.a",
    # "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "i386,arm64",
  }
end
