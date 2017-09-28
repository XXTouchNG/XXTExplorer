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
    [barAppearance setTintColor:[UIColor whiteColor]];
    [barAppearance setBarTintColor:XXTE_COLOR];
    [barAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];

    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[self class], nil];
    [navigationBarAppearance setTintColor:[UIColor whiteColor]];
    [navigationBarAppearance setBarTintColor:XXTE_COLOR];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        [navigationBarAppearance setTranslucent:NO];
    }
    XXTE_END_IGNORE_PARTIAL

    UIBarButtonItem *barButtonItemAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    [barButtonItemAppearance setTintColor:[UIColor whiteColor]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController.prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.translucent = NO;
}

@end
