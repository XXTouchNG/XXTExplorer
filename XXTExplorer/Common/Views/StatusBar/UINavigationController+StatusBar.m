//
//  UINavigationController+StatusBar.m
//  Courtesy
//
//  Created by Zheng on 8/10/16.
//  Copyright © 2016 82Flex. All rights reserved.
//

#import "UINavigationController+StatusBar.h"

@implementation UINavigationController (StatusBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.visibleViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.visibleViewController.prefersStatusBarHidden;
}

/*
- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.visibleViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.visibleViewController;
}
*/

#pragma mark - View Style

- (BOOL)shouldAutorotate {
    return self.visibleViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.visibleViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.visibleViewController.preferredInterfaceOrientationForPresentation;
}

@end
