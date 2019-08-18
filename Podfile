xcodeproj 'XXTExplorer'
install! 'cocoapods', :deterministic_uuids => false

def shared_pods
    # pod 'XUI', :path => '../XUI', :inhibit_warnings => true
    pod 'XUI', :git => 'https://github.com/Lessica/XUI.git', :inhibit_warnings => true

    # pod 'TOWebViewController', :path => '../TOWebViewController', :inhibit_warnings => true
    pod 'TOWebViewController', :git => 'https://github.com/Lessica/TOWebViewController.git', :branch => 'WKWebView', :inhibit_warnings => true

    pod 'OMGHTTPURLRQ', :inhibit_warnings => true
    pod 'SOZOChromoplast', :inhibit_warnings => true
    
    # pod 'PromiseKit', :path => '../PromiseKit', :inhibit_warnings => true
    pod 'PromiseKit', '~> 1.7', :inhibit_warnings => true

    # pod 'LGAlertView', :path => '../LGAlertView', :inhibit_warnings => true
    pod 'LGAlertView', :git => 'https://github.com/Lessica/LGAlertView.git', :branch => 'old-device', :inhibit_warnings => true

    # pod 'MWPhotoBrowser', :path => '../MWPhotoBrowser', :inhibit_warnings => true
    pod 'MWPhotoBrowser', :git => 'https://github.com/Lessica/MWPhotoBrowser.git', :inhibit_warnings => true
    
    pod 'YYCache', :inhibit_warnings => true
    pod 'YYImage', '~> 1.0.4', :inhibit_warnings => true
    pod 'Bugly', :inhibit_warnings => true
end

target 'XXTouch' do
    platform :ios, '8.0'
    shared_pods
    
    pod 'SSZipArchive', :git => 'https://github.com/Lessica/ZipArchive.git', :inhibit_warnings => true
    pod 'UnrarKit', :git => 'https://github.com/Lessica/UnrarKit.git', :branch => 'v2.9', :inhibit_warnings => true
    
    pod 'GCDWebServer/WebDAV', :inhibit_warnings => true
end

def shared_cloud
    pod 'JSONModel', '~> 1.7.0', :inhibit_warnings => true
    pod 'YYWebImage', '~> 1.0.5', :inhibit_warnings => true
end

target 'XXTExplorer' do
    platform :ios, '8.0'
    shared_pods
    shared_cloud
    
    pod 'FLEX', :configurations => ['Debug'], :inhibit_warnings => true
end

target 'XXTExplorer-Archive' do
    platform :ios, '8.0'
    shared_pods
    shared_cloud
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '8.0'
        end
    end
end
