inhibit_all_warnings!

xcodeproj 'XXTExplorer'

def shared_pods

    # pod 'XUI', :path => '../XUI'
    pod 'XUI', :git => 'https://github.com/Lessica/XUI.git'

    # pod 'TOWebViewController', '~> 2.2.6'
    # pod 'TOWebViewController', :path => '../TOWebViewController'
    pod 'TOWebViewController', :git => 'https://github.com/Lessica/TOWebViewController.git', :branch => 'WKWebView'

    pod 'PromiseKit', '~> 1.7'
    # pod 'PromiseKit', :path => '../PromiseKit'

    # pod 'LGAlertView', '~> 2.4.0'
    # pod 'LGAlertView', :path => '../LGAlertView'
    pod 'LGAlertView', :git => 'https://github.com/Lessica/LGAlertView.git', :branch => 'old-device'

    # pod 'MWPhotoBrowser', '~> 2.1.2'
    # pod 'MWPhotoBrowser', :path => '../MWPhotoBrowser'
    pod 'MWPhotoBrowser', :git => 'https://github.com/Lessica/MWPhotoBrowser.git'

    # pod 'Masonry', '~> 1.0.2'
    pod 'YYImage', '~> 1.0.4'

    pod 'XXShield'
    pod 'Bugly'

end

target 'XXTouch' do
    platform :ios, '8.0'
    shared_pods
end

target 'XXTExplorer' do
    platform :ios, '8.0'
    shared_pods
end

target 'XXTExplorer-Archive' do
    platform :ios, '7.0'
    shared_pods
end

