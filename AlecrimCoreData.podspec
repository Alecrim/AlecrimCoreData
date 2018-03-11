Pod::Spec.new do |s|

  s.name         = "AlecrimCoreData"
  s.version      = "6.0-beta.1"
  s.summary      = "A powerful and elegant Core Data framework for Swift."
  s.homepage     = "https://www.alecrim.com/AlecrimCoreData"

  s.license      = "MIT"

  s.author             = { "Vanderlei Martinelli" => "vanderlei.martinelli@gmail.com" }
  s.social_media_url   = "https://www.linkedin.com/in/vmartinelli/"

  s.osx.deployment_target     = "10.12"
  s.ios.deployment_target     = "10.0"
  s.tvos.deployment_target    = "10.0"
  s.watchos.deployment_target = "3.0"

  s.source       = { :git => "https://github.com/Alecrim/AlecrimCoreData.git", :tag => s.version }

  s.source_files = "Source/**/*.swift"

  s.requires_arc = true

end
