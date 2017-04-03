#
# Be sure to run `pod lib lint MoppLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MoppLib'
  s.version          = '1.0.0'
  s.summary          = 'Library for signing documents with ID card'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
MoppLib enables you to add document signing capability to you app. Library supports signing with Mobile-ID or with physical card, using bluetooth card reader.
                       DESC

  s.homepage         = 'https://github.com/open-eid/MOPP-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'LGPL', :file => 'LICENSE' }
  s.author           = { 'KatrinLomp' => 'katrin.annuk@lab.mobi' }
  s.source           = { :git => 'https://github.com/open-eid/MOPP-iOS.git'}
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'MoppLib/**/*'
  
  # s.resource_bundles = {
  #   'MoppLib' => ['MoppLib/Assets/*.png']
  # }

  s.public_header_files = ‘MoppLib/PublicInterface/*.h’
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
