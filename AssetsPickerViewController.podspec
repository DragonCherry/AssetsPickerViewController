#
# Be sure to run `pod lib lint AssetsPickerViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AssetsPickerViewController'
  s.version          = '2.4.2'
  s.summary          = 'Picker controller that supports multiple photos and videos written in Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Select multiple photos and videos.
Fully customizable UI.
                       DESC

  s.homepage         = 'https://github.com/DragonCherry/AssetsPickerViewController'
  s.screenshots      = 'https://cloud.githubusercontent.com/assets/20486591/26525538/42b1d6dc-4395-11e7-9c16-b9abdb2e9247.PNG', 'https://cloud.githubusercontent.com/assets/20486591/26616648/1d385746-460b-11e7-9324-62ea634e2fcb.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DragonCherry' => 'dragoncherry@naver.com' }
  s.source           = { :git => 'https://github.com/DragonCherry/AssetsPickerViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.linkedin.com/in/jeongyong/'

  s.ios.deployment_target = '9.0'

  s.source_files = 'AssetsPickerViewController/Classes/**/*'
  
  s.resource_bundles = {
    'AssetsPickerViewController' => ['AssetsPickerViewController/Assets/*.*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'PureLayout'
  s.dependency 'Dimmer', '~> 2.0'
  s.dependency 'FadeView', '~> 2.0'
  s.dependency 'TinyLog', '~> 2.0'
  s.dependency 'SwiftARGB', '~> 2.0'
  s.dependency 'Device', '~> 3.0.3'
end
