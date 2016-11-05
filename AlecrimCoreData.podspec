Pod::Spec.new do |s|

  s.name         = "AlecrimCoreData"
  s.version      = "5.0-beta.5"
  s.summary      = "A powerful and simple Core Data wrapper framework written in Swift."
  s.homepage     = "https://github.com/Alecrim/AlecrimCoreData"

  s.license      = "MIT"

  s.author             = { "Vanderlei Martinelli" => "vanderlei.martinelli@gmail.com" }
  s.social_media_url   = "https://twitter.com/vmartinelli"

  s.osx.deployment_target     = "10.12"
  s.ios.deployment_target     = "9.0"
  s.tvos.deployment_target    = "9.0"
  s.watchos.deployment_target = "2.0"
  
  s.source       = { :git => "https://github.com/Alecrim/AlecrimCoreData.git", :tag => s.version }

  s.source_files = "Source/**/*.swift"

  s.requires_arc = true
  
end
