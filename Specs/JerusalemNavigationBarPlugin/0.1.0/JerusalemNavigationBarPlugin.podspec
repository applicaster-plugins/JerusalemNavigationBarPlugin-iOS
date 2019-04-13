Pod::Spec.new do |s|
  s.name             = "JerusalemNavigationBarPlugin"
  s.version          = '0.1.0'
  s.summary          = "JerusalemNavigationBarPlugin"
  s.description      = <<-DESC
                        Jerusalem navigation bar plugin.
                       DESC
  s.homepage         = "https://github.com/applicaster-plugins/JerusalemNavigationBarPlugin-iOS"
  s.license          = 'CMPS'
  s.author           = { "cmps" => "m.vecselboim@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster-plugins/JerusalemNavigationBarPlugin-iOS.git", :tag => s.version.to_s }
  s.platform     = :ios, '10.0'
  s.requires_arc = true

  s.public_header_files = 'JerusalemNavigationBarPlugin/**/*.h'
  s.source_files = 'JerusalemNavigationBarPlugin/**/**/*.{h,m,swift}'


  s.resources = [
    "**/*.{png,xib}"
  ]

  s.xcconfig =  {
                  'ENABLE_BITCODE' => 'YES',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'SWIFT_VERSION' => '4.2'
                }

  s.dependency 'ZappPlugins'
  s.dependency 'ZappNavigationBarPluginsSDK'
  s.dependency 'ApplicasterSDK'
  s.dependency 'ZappRootPluginsSDK'
  s.dependency 'ComponentsSDK'
  s.dependency 'ZappSDK'
  s.dependency 'Alamofire'
end
