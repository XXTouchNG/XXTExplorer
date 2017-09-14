//
//  XXTECommonWebViewController.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECommonWebViewController.h"

@interface XXTECommonWebViewController ()

@end

@implementation XXTECommonWebViewController

- (instancetype)init {
    if (self = [super init]) {
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
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
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
    NSLog(@"[XXTECommonWebViewController dealloc]");
#endif
}

@end
