#
# Be sure to run `pod lib lint YikesStaffEngine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YikesStaffEngine'
  s.version          = '0.0.1'
  s.summary          = 'Engine used internally by the Staff App.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://bitbucket.org/yikesdev/yikesstaffengine'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Manny Singh' => 'manny.singh@yikes.co' }
  s.source           = { :git => 'https://bitbucket.org/yikesdev/yikesstaffengine.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'YikesStaffEngine/**/*.{swift}'
  # s.resources = 'YikesStaffEngine/**/*.{png,jpeg,jpg,storyboard,xib}'
  
  # s.resource_bundles = {
  #  'YikesStaffEngine' => ['YikesStaffEngine/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'KeychainAccess'
  s.dependency 'AlamofireObjectMapper'
  s.dependency 'TaskQueue'
  s.dependency 'Device'

end
