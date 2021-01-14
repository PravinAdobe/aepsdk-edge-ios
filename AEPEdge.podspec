Pod::Spec.new do |s|
  s.name             = "AEPEdge"
  s.version          = "1.0.0"
  s.summary          = "Experience Platform Edge extension for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       The Experience Platform Edge extension enables sending data to the Adobe Experience Edge from a mobile device using the v5 Adobe Experience Platform SDK.
                       DESC

  s.homepage         = "https://github.com/adobe/aepsdk-edge-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-edge-ios.git", :tag => "v#{s.version}-#{s.name}" }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore'
  s.dependency 'AEPServices'

  s.source_files = 'Sources/**/*.swift'
end
