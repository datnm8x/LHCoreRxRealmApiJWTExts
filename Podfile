# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
inhibit_all_warnings!

target 'LHCoreRxRealmApiJWTExts iOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for LHCoreExtensions iOS
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RealmSwift'
  pod 'RxRealm'
  pod 'JSONWebToken', :git => 'https://github.com/laohac8x/JSONWebToken.git', :inhibit_warnings => true
  
  target 'LHCoreRxRealmApiJWTExts iOS Tests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Nimble'
  end

  target 'Example' do
    use_frameworks!
    # Pods for host app example
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
    end
  end
  
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  end
end
