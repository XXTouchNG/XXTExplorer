//
//  XXTECommonWebViewController.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECommonWebViewController.h"
#import "XXTEUserInterfaceDefines.h"

@interface XXTECommonWebViewController ()

@end

@implementation XXTECommonWebViewController

@synthesize entryPath = _entryPath;

- (instancetype)init {
    if (self = [super init]) {
        [self configure];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        [self configure];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super initWithURL:url]) {
        [self configure];
    }
    return self;
}

- (void)configure { // do not override [super setup]
    self.loadingBarTintColor = XXTE_COLOR_SUCCESS;
    self.showLoadingBar = YES;
    self.showUrlWhileLoading = NO;
    self.hideWebViewBoundaries = YES;
    
    if (isiPhoneX()) {
        self.hidesBottomBarWhenPushed = YES;
    } else {
        self.hidesBottomBarWhenPushed = NO;
    }
    
    @weakify(self);
    if (@available(iOS 8.0, *)) {
        self.wk_shouldStartLoadRequestHandler = ^BOOL(NSURLRequest *request, WKNavigationType navigationType) {
            @strongify(self);
            NSURL *url = request.URL;
            if ([url.scheme isEqualToString:@"xxt"]) {
                [self dismissViewControllerAnimated:YES completion:^{
                    if ([[UIApplication sharedApplication] canOpenURL:url])
                    {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
                return NO;
            }
            return YES;
        };
    } else {
        // Fallback on earlier versions
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.webView) {
        self.webView.opaque = NO;
    } else {
        self.wkWebView.opaque = NO;
    }

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self == self.navigationController.viewControllers[0]) {
        self.applicationLeftBarButtonItems = @[ self.splitViewController.displayModeButtonItem ];
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)showPlaceholderTitle {
    
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTECommonWebViewController dealloc]");
#endif
}

@end
