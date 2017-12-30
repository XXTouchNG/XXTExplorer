xcodeproj 'XXTExplorer'

def shared_pods

    # pod 'XUI', :path => '../XUI'
    pod 'XUI', :git => 'https://github.com/Lessica/XUI.git'

    # pod 'TOWebViewController', '~> 2.2.6'
    # pod 'TOWebViewController', :path => '../TOWebViewController'
    pod 'TOWebViewController', :git => 'https://github.com/Lessica/TOWebViewController.git', :branch => 'WKWebView'

    pod 'PromiseKit', '~> 1.7', :inhibit_warnings => true
    # pod 'PromiseKit', :path => '../PromiseKit', :inhibit_warnings => true

    # pod 'LGAlertView', '~> 2.4.0', :inhibit_warnings => true
    # pod 'LGAlertView', :path => '../LGAlertView', :inhibit_warnings => true
    pod 'LGAlertView', :git => 'https://github.com/Lessica/LGAlertView.git', :branch => 'old-device', :inhibit_warnings => true

    # pod 'MWPhotoBrowser', '~> 2.1.2', :inhibit_warnings => true
    # pod 'MWPhotoBrowser', :path => '../MWPhotoBrowser', :inhibit_warnings => true
    pod 'MWPhotoBrowser', :git => 'https://github.com/Lessica/MWPhotoBrowser.git', :inhibit_warnings => true

    # pod 'Masonry', '~> 1.0.2', :inhibit_warnings => true
    pod 'YYImage', '~> 1.0.4', :inhibit_warnings => true

    pod 'XXShield', :inhibit_warnings => true
    pod 'Bugly', :inhibit_warnings => true
end

target 'XXTouch' do
    platform :ios, '8.0'
    shared_pods
    
    # pod 'UnrarKit', :path => '../UnrarKit'
    pod 'UnrarKit', :git => 'https://github.com/Lessica/UnrarKit.git', :branch => 'v2.9'
end

target 'XXTExplorer' do
    platform :ios, '8.0'
    shared_pods
end

target 'XXTExplorer-Archive' do
    platform :ios, '7.0'
    shared_pods
end

