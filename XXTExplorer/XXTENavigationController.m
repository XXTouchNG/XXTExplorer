//
//  XXTENavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTENavigationController.h"

@interface XXTENavigationController ()

@end

@implementation XXTENavigationController

- (instancetype)init {
    if (self = [super init]) {
        [self setupAppearance];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    UINavigationBar *barAppearance = [UINavigationBar appearance];
    [barAppearance setTintColor:XXTColorTint()];
    [barAppearance setBarTintColor:XXTColorBarTint()];
    [barAppearance setTitleTextAttributes:@{ NSForegroundColorAttributeName: XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f] }];
    [barAppearance setLargeTitleTextAttributes:@{ NSForegroundColorAttributeName: XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:24.f] }];
    [barAppearance setPrefersLargeTitles:YES];

    XXTE_START_IGNORE_PARTIAL
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[self class], nil];
    XXTE_END_IGNORE_PARTIAL
    [navigationBarAppearance setTintColor:XXTColorTint()];
    [navigationBarAppearance setBarTintColor:XXTColorBarTint()];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    [navigationBarAppearance setTranslucent:YES];

    UINavigationBarAppearance *latestNavigationBarAppearance = [[UINavigationBarAppearance alloc] init];
    [latestNavigationBarAppearance configureWithOpaqueBackground];
    [latestNavigationBarAppearance setBackgroundColor:XXTColorBarTint()];
    [latestNavigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName : XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    [self.navigationBar setStandardAppearance:latestNavigationBarAppearance];
    [self.navigationBar setScrollEdgeAppearance:latestNavigationBarAppearance];

    XXTE_START_IGNORE_PARTIAL
    UIBarButtonItem *barButtonItemAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    XXTE_END_IGNORE_PARTIAL
    [barButtonItemAppearance setTintColor:XXTColorTint()];
    [barButtonItemAppearance setTitleTextAttributes:@{ NSForegroundColorAttributeName: XXTColorTint(), NSFontAttributeName: [UIFont systemFontOfSize:17.0] } forState:UIControlStateNormal];
    [barButtonItemAppearance setTitleTextAttributes:@{ NSForegroundColorAttributeName: [XXTColorTint() colorWithAlphaComponent:0.3], NSFontAttributeName: [UIFont systemFontOfSize:17.0] } forState:UIControlStateDisabled];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000
    if (@available(iOS 15.0, *)) {
        [[UITableView appearance] setSectionHeaderTopPadding:0];
    } else {
        // Fallback on earlier versions
    }
#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController.prefersStatusBarHidden;
}

- (UIUserInterfaceStyle)overrideUserInterfaceStyle {
    return self.topViewController.overrideUserInterfaceStyle;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.translucent = YES;
}

@end
