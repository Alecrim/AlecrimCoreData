Pod::Spec.new do |s|
    s.name                      = 'AlecrimCoreData'
    s.version                   = '7.0'
    s.summary                   = 'Core Data made simple'

    s.homepage                  = 'https://github.com/Alecrim/AlecrimCoreData'
    s.license                   = 'MIT'
    s.author                    = { 'Vanderlei Martinelli' => 'vanderlei.martinelli@gmail.com' }
    s.social_media_url          = 'https://www.linkedin.com/in/vmartinelli'

    s.source                    = { :git => 'https://github.com/Alecrim/AlecrimCoreData.git', :tag => s.version.to_s }
    s.source_files              = 'Sources/**/*'

    s.osx.deployment_target     = '10.12'
    s.ios.deployment_target     = '10.0'
    s.watchos.deployment_target = '3.0'
    s.tvos.deployment_target    = '10.0'
end
