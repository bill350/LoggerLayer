platform :ios, '12.1'

workspace 'MyModularApp'
project './MyModularApp/MyModularApp.xcodeproj'

inhibit_all_warnings!
use_frameworks!

def loggerPods
  pod 'NSLogger/Swift', '= 1.9.0'
end

target 'MyModularApp' do
  
  loggerPods
  
  pod 'SwiftLint', '= 0.27.0'

  target 'MyModularAppTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'PaymentKit' do
  project './AppFeatures/PaymentKit/PaymentKit.xcodeproj'
  pod 'Stripe', '= 13.2.0'
  
  target 'PaymentKitTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
end


# MARK: Logger
target 'Logger' do
  project './AppFrameworks/Logger/Logger.xcodeproj'
  
  loggerPods
  
  target 'LoggerTests' do
    inherit! :search_paths
  end
end

# MARK: Post install
post_install do |installer|
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      
      if target.name == 'NSLogger'
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
      
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
