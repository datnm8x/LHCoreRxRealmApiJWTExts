#
# Be sure to run `pod lib lint LHCoreRxRealmApiJWTExts.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'LHCoreRxRealmApiJWTExts'
s.version          = '1.0'
s.summary          = 'A short description of LHCoreRxRealmApiJWTExts.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = <<-DESC
TODO: Add long description of the pod here.
DESC

s.homepage         = 'https://github.com/laohac8x/LHCoreRxRealmApiJWTExts'
# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Dat Ng' => 'laohac83x@gmail.com' }
s.source           = { :git => 'https://github.com/laohac8x/LHCoreRxRealmApiJWTExts.git', :tag => s.version.to_s }

s.ios.deployment_target = '9.0'
s.swift_version = '5.0'
s.source_files = 'Source/*.swift', 'LHCoreRxApiJWTExts/Source/*.swift', 'LHCoreRxApiJWTExts/LHSwiftJWT/Source/*.swift'

# s.resource_bundles = {
#   'LHCoreRxRealmApiJWTExts' => ['LHCoreRxRealmApiJWTExts/Assets/*.png']
# }

s.dependency 'SwiftyJSON', '~> 5'
s.dependency 'Alamofire', '~> 4'
s.dependency 'AlamofireImage', '~> 3'
s.dependency 'RxSwift', '~> 5'
s.dependency 'RxCocoa', '~> 5'
s.dependency 'RealmSwift', '~> 3'
s.dependency 'RxRealm', '~> 1'

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit', 'MapKit'
end
