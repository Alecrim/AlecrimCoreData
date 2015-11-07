Pod::Spec.new do |s|

  s.name         = "AlecrimCoreData"
  s.version      = "4.0"
  s.summary      = "A powerful and simple Core Data wrapper framework written in Swift."
  s.homepage     = "https://github.com/Alecrim/AlecrimCoreData"

  s.license      = "MIT"

  s.author             = { "Vanderlei Martinelli" => "vanderlei.martinelli@gmail.com" }
  s.social_media_url   = "https://twitter.com/vmartinelli"

  s.ios.deployment_target     = "8.0"
  s.osx.deployment_target     = "10.9"
  s.watchos.deployment_target = "2.0"
  
  s.source       = { :git => "https://github.com/Alecrim/AlecrimCoreData.git", :tag => s.version }

  s.source_files = "Source/**/*.swift"

end
