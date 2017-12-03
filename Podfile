platform :ios, '7.0'
inhibit_all_warnings!

xcodeproj 'XXTExplorer'

def shared_pods

    pod 'XUI', :path => '../XUI'

    # pod 'TOWebViewController', '~> 2.2.6'
    pod 'TOWebViewController', :path => '../TOWebViewController'
    # pod 'TOWebViewController', :git => 'https://github.com/Lessica/TOWebViewController.git', :branch => 'WKWebView'

    pod 'PromiseKit', '~> 1.7'
    # pod 'PromiseKit', :path => '../PromiseKit'

    # pod 'LGAlertView', '~> 2.4.0'
    # pod 'LGAlertView', :path => '../LGAlertView'
    pod 'LGAlertView', :git => 'https://github.com/Lessica/LGAlertView.git', :branch => 'old-device'

    # pod 'Masonry', '~> 1.0.2'
    pod 'YYImage', '~> 1.0.4'

    pod 'Bugly'

end

target 'XXTouch' do
    shared_pods
end

target 'XXTExplorer' do
    shared_pods
end

