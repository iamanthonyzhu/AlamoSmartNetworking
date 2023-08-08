#
# Be sure to run `pod lib lint EMSmartNetworking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NFZMSmartNetworking-iOS'
  s.version          = '0.1.0'
  s.summary          = 'A short description of EMSmartNetworking.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Aron1987@126.com/NFZMSmartNetworking-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Aron1987@126.com' => 'lixiefeng@evergrande.com' }
  s.source           = { :git => 'ssh://gogs@gogs.infzm.com:22403/zhuWei/NFZMSmartNetworking-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

#  s.source_files = 'EMSmartNetworking/Classes/**/*'
  
  # s.resource_bundles = {
  #   'EMSmartNetworking' => ['EMSmartNetworking/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.dependency 'Alamofire', '~> 5.6.4'
  #s.dependency 'AFNetworking'
  #s.dependency 'YYModel'
  #s.dependency 'CocoaLumberjack'
  
  s.subspec 'Core' do |core|
      core.source_files = 'EMSmartNetworking/Classes/Core/*.{h,m,swift}'
  end
  
  s.prefix_header_contents = <<-EOS
   #ifdef __OBJC__
   #import <CocoaLumberjack/DDLogMacros.h>
   static DDLogLevel ddLogLevel = DDLogLevelInfo;
   #endif
   EOS
  
end
