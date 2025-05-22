#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_aliyun_nui.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_aliyun_nui'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
 
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks =  'AudioToolbox'
  s.libraries = 'c++'
  s.vendored_frameworks = 'Frameworks/nuisdk.framework'
  s.resource_bundles = {
  'flutter_aliyun_nui_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
  # s.info_plist = {
  #     'NSMicrophoneUsageDescription' => 'App 需要访问麦克风进行语音识别',
  #     'NSSpeechRecognitionUsageDescription' => '当您点击麦克风按钮时，我们将通过语音识别帮助您快速输入文字',
  # }
  

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_aliyun_nui_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
