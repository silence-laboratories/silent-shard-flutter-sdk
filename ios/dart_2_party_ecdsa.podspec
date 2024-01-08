#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dart_2_party_ecdsa.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dart_2_party_ecdsa'
  s.version          = '0.0.1'
  s.summary          = 'A Dart Flutter plugin for 2-party TSS.'
  s.description      = <<-DESC
A convenience wrapper around corresponding rust sdk (via C bindings).
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.vendored_frameworks     = 'Frameworks/ctss.xcframework', 'Frameworks/gmp.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
