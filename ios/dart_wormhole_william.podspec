#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dart_wormhole_william.podspec` to validate before publishing.
#2>&1 | tee logs.txt
Pod::Spec.new do |s|
  s.name             = 'dart_wormhole_william'
  s.version          = '0.0.1'
  s.summary          = 'Flutter Wormhole-William plugin for iOS'
  s.prepare_command = <<-CMD
			  cd build
			  CMAKE_SYSTEM_NAME=iOS cmake -D CMAKE_SYSTEM_NAME=iOS --trace ../ 
			  make
		  CMD
  s.description      = <<-DESC
Flutter Wormhole-William plugin for iOS
                       DESC
  s.homepage         = 'https://github.com/LeastAuthority/destiny/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Least Authority' => 'destiny@leastauthority.com' }
  s.source           = { :path => '.' }
  s.ios.source_files     = 'Classes/**/*'
  s.libraries        = 'c'
  s.dependency 'Flutter'
  s.ios.deployment_target  = '12.0'

  s.platform = :ios, '12.0'
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => "-force_load $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libbindings.a $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libdart_wormhole_william_plugin.a $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libwormhole_william.a",
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => "-force_load $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libbindings.a $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libdart_wormhole_william_plugin.a $(PODS_ROOT)/../../dart_wormhole_william/ios/build/libwormhole_william.a",
  
  }
  s.swift_version = '5.0'
end
