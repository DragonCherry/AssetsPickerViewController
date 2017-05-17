#
# Be sure to run `pod lib lint AssetsPickerViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AssetsPickerViewController'
  s.version          = '0.5.0'
  s.summary          = 'Picker controller that supports multiple photos and videos written in Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Select multiple photos and videos.
Can take photo or video during selection.
Fully customizable UI.
                       DESC

  s.homepage         = 'https://github.com/DragonCherry/AssetsPickerViewController'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DragonCherry' => 'dragoncherry@naver.com' }
  s.source           = { :git => 'https://github.com/DragonCherry/AssetsPickerViewController.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'AssetsPickerViewController/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AssetsPickerViewController' => ['AssetsPickerViewController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AlamofireImage'
  s.dependency 'TinyLog'
  s.dependency 'OptionalTypes'
  
end
