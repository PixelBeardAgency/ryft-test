#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_ryft_payment'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin implementing Ryft payment SDKs for both Android and iOS platforms.'
  s.description      = <<-DESC
A Flutter plugin implementing Ryft payment SDKs for both Android and iOS platforms.
                       DESC
  s.homepage         = 'https://github.com/yourusername/flutter_ryft_payment'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Swift Package dependencies 
  # Note: In a real implementation, you would need to add the Ryft Swift package
  # https://github.com/RyftPay/ryft-ios
  
  # Swift libs
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
end 