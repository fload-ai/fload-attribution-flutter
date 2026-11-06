#
# The CocoaPods half of the iOS plugin. Swift Package Manager (Package.swift)
# is the default from Flutter 3.44; this podspec builds the same sources for
# apps that still use CocoaPods. It is never pushed to the CocoaPods trunk.
#
Pod::Spec.new do |s|
  s.name             = 'fload_attribution'
  s.version          = '1.0.0'
  s.summary          = 'Fload install attribution for Flutter: Apple AdServices on iOS.'
  s.description      = <<-DESC
Reports the app's install to Fload with Apple's AdServices attribution token.
No IDFA, no App Tracking Transparency prompt. Wraps the Fload iOS SDK.
                       DESC
  s.homepage         = 'https://github.com/fload-ai/fload-attribution-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Fload' => 'hello@fload.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'fload_attribution/Sources/fload_attribution/**/*.swift'
  s.resource_bundles = {
    'fload_attribution_privacy' => ['fload_attribution/Sources/fload_attribution/Vendor/FloadAttribution/Resources/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.weak_frameworks  = 'AdServices'
  s.platform         = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
