//
//  XXTESplitViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"
#import <LGAlertView/LGAlertView.h>
#import "XXTENotificationCenterDefines.h"

#import "XXTEUserInterfaceDefines.h"

#import "XXTEWorkspaceViewController.h"
#import "XXTENavigationController.h"

@interface XXTESplitViewController () <UISplitViewControllerDelegate>

@end

@implementation XXTESplitViewController

- (BOOL)shouldAutorotate {
    return self.viewControllers.firstObject.shouldAutorotate;
}

#pragma mark - Restore State

- (NSString *)restorationIdentifier {
    return [NSString stringWithFormat:@"com.xxtouch.restoration.%@", NSStringFromClass(self.class)];
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"XXTESplitViewController is a singleton.");
            alreadyInitialized = YES;
            self.delegate = self;
            [self setRestorationIdentifier:self.restorationIdentifier];
            [self setupAppearance];
        });
    }
    return self;
}

- (void)setupAppearance {
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_PAD) {
        if (@available(iOS 8.0, *)) {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        }
    }
    XXTE_END_IGNORE_PARTIAL
}

- (UIViewController *)masterViewController {
    return (self.viewControllers.count > 0) ? self.viewControllers[0] : nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.masterViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.masterViewController.prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.masterViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.masterViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)restoreWorkspaceViewControllerFromViewController:(UIViewController *)sender {
    if (@available(iOS 8.0, *)) {
        XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
        XXTENavigationController *detailNavigationController = [[XXTENavigationController alloc] initWithRootViewController:detailViewController];
        [self showDetailViewController:detailNavigationController sender:sender];
    }
}

#pragma mark - UISplitViewDelegate

XXTE_START_IGNORE_PARTIAL
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:svc userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode, XXTENotificationDetailDisplayMode: @(displayMode)}]];
}
XXTE_END_IGNORE_PARTIAL

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return (splitViewController.viewControllers.count > 0) ? splitViewController.viewControllers[0] : nil;
}

// DO NOT OVERRIDE preferredDisplayMode

@end
