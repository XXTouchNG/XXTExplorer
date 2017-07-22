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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

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
    
    self.webView.opaque = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (XXTE_COLLAPSED) {
        self.applicationLeftBarButtonItems = @[ self.splitViewController.displayModeButtonItem ];
    }
}

- (void)showPlaceholderTitle {
    
}

- (BOOL)compactPresentation {
    if (XXTE_SYSTEM_8) {
        return ((self.splitViewController && self.splitViewController.isCollapsed == NO) || self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    }
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTECommonWebViewController dealloc]");
#endif
}

@end
