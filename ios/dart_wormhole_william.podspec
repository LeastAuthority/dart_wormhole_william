#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dart_wormhole_william.podspec` to validate before publishing.
#2>&1 | tee logs.txt
Pod::Spec.new do |s|
  s.name             = 'dart_wormhole_william'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.prepare_command = <<-CMD
			  cd build
			  CMAKE_SYSTEM_NAME=iOS cmake -D CMAKE_SYSTEM_NAME=iOS --trace ../ 
			  make
		  CMD
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.ios.deployment_target  = '16.0'

  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.swift_version = '5.0'

  #  'OTHER_LDFLAGS' => '-ldart_wormhole_william'
end
