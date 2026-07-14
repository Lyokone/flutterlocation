#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'location'
  s.version          = '8.0.1'
  s.summary          = 'Cross-platform plugin for easy access to the device location in real time.'
  s.description      = <<-DESC
Cross-platform plugin for easy access to the device location in real time.
                       DESC
  s.homepage         = 'https://github.com/Lyokone/flutterlocation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lyokone' => 'https://github.com/Lyokone/flutterlocation' }
  s.source           = { :path => '.' }
  s.source_files     = 'location/Sources/location/**/*.swift'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'

  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
