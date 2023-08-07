//
//  UIViewController+TopMostViewController.m
//  XXTExplorer
//
//  Created by Zheng on 06/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "UIViewController+TopMostViewController.h"

@implementation UIViewController (TopMostViewController)

- (UIViewController *)topMostViewController {
    if (self.presentedViewController == nil) {
        return self;
    }
    if ([self.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self.presentedViewController;
        return [navigationController.visibleViewController topMostViewController];
    }
    if ([self.presentedViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)self.presentedViewController;
        if (tabBarController.selectedViewController) {
            return [tabBarController.selectedViewController topMostViewController];
        } else {
            return [tabBarController topMostViewController];
        }
    }
    if ([self.presentedViewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.presentedViewController;
        if (splitViewController.viewControllers.count > 0) {
            return [splitViewController.viewControllers[0] topMostViewController];
        } else {
            return [splitViewController topMostViewController];
        }
    }
    return [self.presentedViewController topMostViewController];
}

- (void)dismissModalStackAnimated:(BOOL)animated {
    UIViewController *vc = self.presentingViewController;
    while (vc.presentingViewController) {
        vc = vc.presentingViewController;
    }
    [vc dismissViewControllerAnimated:animated completion:nil];
}

@end
