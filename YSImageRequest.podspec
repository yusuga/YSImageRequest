Pod::Spec.new do |s|
  s.name = 'YSImageRequest'
  s.version = '0.3.9'
  s.summary = 'YSImageRequest'
  s.homepage = 'https://github.com/yusuga/YSImageRequest'
  s.license = 'MIT'
  s.author = 'Yu Sugawara'
  s.source = { :git => 'https://github.com/yusuga/YSImageRequest.git', :tag => s.version.to_s }
  s.platform = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.source_files = 'Classes/YSImageRequest/*.{h,m}'
  s.requires_arc = true
  
  s.dependency 'SDWebImage'
  s.dependency 'NSString-Hash'
  s.dependency 'YSImageFilter'
  
  s.compiler_flags = '-fmodules'
end