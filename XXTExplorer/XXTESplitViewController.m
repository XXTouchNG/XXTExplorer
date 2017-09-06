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

@interface XXTESplitViewController () <UISplitViewControllerDelegate>

@end

@implementation XXTESplitViewController

#pragma mark - Restore State

- (NSString *)restorationIdentifier {
    return [NSString stringWithFormat:@"com.xxtouch.restoration.%@", NSStringFromClass(self.class)];
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        self.delegate = self;
        [self setRestorationIdentifier:self.restorationIdentifier];
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_8 && XXTE_PAD) {
        self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    XXTE_END_IGNORE_PARTIAL
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.viewControllers[0].preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.viewControllers[0].prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[0];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - UISplitViewDelegate

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:svc userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode, XXTENotificationDetailDisplayMode: @(displayMode)}]];
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return splitViewController.viewControllers[0];
}

// DO NOT OVERRIDE preferredDisplayMode

@end
