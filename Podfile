project 'XXTExplorer'
install! 'cocoapods', :deterministic_uuids => false

def shared_pods
    pod 'OMGHTTPURLRQ', :inhibit_warnings => true
    pod 'SOZOChromoplast', :inhibit_warnings => true
    pod 'PromiseKit', '~> 1.7', :inhibit_warnings => true
    pod 'LGAlertView', :path => '../LGAlertView', :inhibit_warnings => true
    pod 'MWPhotoBrowser', :path => '../MWPhotoBrowser', :inhibit_warnings => true
    pod 'YYCache', :inhibit_warnings => true
    pod 'YYImage', '~> 1.0.4', :inhibit_warnings => true
    pod 'JSONModel', :inhibit_warnings => true
end

target 'XXTExplorer' do
    platform :ios, '13.0'
    shared_pods
end

target 'XXTExplorer-Archive' do
    platform :ios, '13.0'
    shared_pods
end

def fix_config(config)
    # https://github.com/CocoaPods/CocoaPods/issues/8891
    if config.build_settings['DEVELOPMENT_TEAM'].nil?
        config.build_settings['DEVELOPMENT_TEAM'] = 'GXZ23M5TP2'
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        end
    end
    installer.generated_projects.each do |project|
        project.build_configurations.each do |config|
            fix_config(config)
        end
        project.targets.each do |target|
            target.build_configurations.each do |config|
                fix_config(config)
            end
        end
    end
end
