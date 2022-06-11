#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'location_macos'
  s.version          = '0.0.1'
  s.summary          = 'A macOS implementation of the location plugin.'
  s.description      = <<-DESC
  A macOS implementation of the location plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'SwiftLocation/Core', '5.1.0'

  s.platform = :osx
  s.osx.deployment_target = '11.0'
  s.swift_version = '5.0'
end

