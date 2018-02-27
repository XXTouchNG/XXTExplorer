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
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

#pragma mark - Life Cycle

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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerNavigationController dealloc]");
#endif
}

#pragma mark - Convinence Getters

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

XXTE_START_IGNORE_PARTIAL
- (NSArray <id <UIPreviewActionItem>> *)previewActionItems {
    return [[self topmostExplorerViewController] previewActionItems];
}
XXTE_END_IGNORE_PARTIAL

@end
