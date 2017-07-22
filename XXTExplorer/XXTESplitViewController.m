//
//  XXTESplitViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"
#import <LGAlertView/LGAlertView.h>
#import "UIView+XXTEToast.h"
#import "XXTECommonNavigationController.h"
#import "XXTEWorkspaceViewController.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTEDetailViewController.h"

@interface XXTESplitViewController () <UISplitViewControllerDelegate>

@end

@implementation XXTESplitViewController

- (instancetype)init {
    if (self = [super init]) {
        self.delegate = self;
    }
    return self;
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
    
    LGAlertView *alertAppearance = [LGAlertView appearanceWhenContainedIn:[self class], nil];
    alertAppearance.coverColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    alertAppearance.coverBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    alertAppearance.coverAlpha = 0.85;
    alertAppearance.layerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    alertAppearance.layerShadowRadius = 4.0;
    alertAppearance.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    alertAppearance.buttonsHeight = 44.0;
    alertAppearance.titleFont = [UIFont boldSystemFontOfSize:18.0];
    alertAppearance.titleTextColor = [UIColor blackColor];
    alertAppearance.messageTextColor = [UIColor blackColor];
    alertAppearance.activityIndicatorViewColor = XXTE_COLOR;
    alertAppearance.buttonsTitleColor = XXTE_COLOR;
    alertAppearance.buttonsBackgroundColorHighlighted = XXTE_COLOR;
    alertAppearance.cancelButtonTitleColor = XXTE_COLOR;
    alertAppearance.cancelButtonBackgroundColorHighlighted = XXTE_COLOR;
    alertAppearance.destructiveButtonTitleColor = XXTE_COLOR_DANGER;
    alertAppearance.destructiveButtonBackgroundColorHighlighted = XXTE_COLOR_DANGER;
    alertAppearance.progressLabelFont = [UIFont italicSystemFontOfSize:14.f];
    alertAppearance.progressLabelLineBreakMode = NSLineBreakByTruncatingHead;
    alertAppearance.dismissOnAction = NO;
    alertAppearance.buttonsIconPosition = LGAlertViewButtonIconPositionLeft;
    alertAppearance.buttonsTextAlignment = NSTextAlignmentLeft;
    
    [XXTEToastManager setTapToDismissEnabled:YES];
    [XXTEToastManager setDefaultDuration:2.f];
    [XXTEToastManager setQueueEnabled:NO];
    [XXTEToastManager setDefaultPosition:XXTEToastPositionCenter];
    
    XXTEToastStyle *toastStyle = [XXTEToastManager sharedStyle];
    toastStyle.backgroundColor = [UIColor colorWithWhite:0.f alpha:.6f];
    toastStyle.titleFont = [UIFont boldSystemFontOfSize:14.f];
    toastStyle.messageFont = [UIFont systemFontOfSize:14.f];
    toastStyle.activitySize = CGSizeMake(80.f, 80.f);
    toastStyle.verticalMargin = 16.f;
    
}

#pragma mark - UISplitViewDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UINavigationController *)secondaryViewController ontoPrimaryViewController:(UITabBarController *)primaryViewController {
    if ([primaryViewController isKindOfClass:[UITabBarController class]] &&
        [primaryViewController.selectedViewController isKindOfClass:[UINavigationController class]] &&
        [secondaryViewController isKindOfClass:[UINavigationController class]] &&
        NO == [secondaryViewController.viewControllers[0] isKindOfClass:[XXTEWorkspaceViewController class]]
        )
    {
        UINavigationController *navigationController = primaryViewController.selectedViewController;
        secondaryViewController.viewControllers[0].navigationItem.leftBarButtonItem = secondaryViewController.viewControllers[0].navigationItem.backBarButtonItem;
        navigationController.viewControllers = [navigationController.viewControllers arrayByAddingObjectsFromArray:secondaryViewController.viewControllers];
        return YES;
    } else {
        return NO;
    }
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:svc userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode, XXTENotificationDetailDisplayMode: @(displayMode)}]];
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return splitViewController.viewControllers[0];
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UITabBarController *)primaryViewController {
    UINavigationController *navigationController = primaryViewController.selectedViewController;
    UIViewController *topViewController = navigationController.topViewController;
    if ([primaryViewController isKindOfClass:[UITabBarController class]] &&
        [primaryViewController.selectedViewController isKindOfClass:[UINavigationController class]] &&
        [topViewController conformsToProtocol:@protocol(XXTEDetailViewController)]
        ) {
        NSMutableArray <UIViewController *> *viewControllers = [navigationController.viewControllers mutableCopy];
        [viewControllers removeObject:topViewController];
        [navigationController setViewControllers:[[NSArray alloc] initWithArray:viewControllers] animated:NO];
        topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
        XXTECommonNavigationController *detailNavigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:topViewController];
        return detailNavigationController;
    } else if (splitViewController.viewControllers.count < 2) {
        XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
        XXTECommonNavigationController *detailNavigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:detailViewController];
        return detailNavigationController;
    }
    return splitViewController.viewControllers[1];
}

@end
