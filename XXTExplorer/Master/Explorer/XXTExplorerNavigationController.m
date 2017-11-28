//
//  XXTExplorerNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"

#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTEDispatchDefines.h"

#import "XXTExplorerViewController+SharedInstance.h"

@interface XXTExplorerNavigationController ()

@end

@implementation XXTExplorerNavigationController

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(NO, @"XXTExplorerNavigationController must be initialized with a rootViewController.");
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"XXTExplorerNavigationController is a singleton.");
            alreadyInitialized = YES;
            [self setup];
        });
    }
    return self;
}

- (void)setup {
    
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
    }
    
#ifndef APPSTORE
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Scripts", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
#else
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Files", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
#endif
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerNavigationController dealloc]");
#endif
}

- (XXTExplorerViewController *)topmostExplorerViewController {
    __block XXTExplorerViewController *topmostExplorerViewController = nil;
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[XXTExplorerViewController class]]) {
            topmostExplorerViewController = (XXTExplorerViewController *)obj;
            *stop = YES;
        }
    }];
    return topmostExplorerViewController;
}

@end
