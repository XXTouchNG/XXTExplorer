//
//  XXTESplitViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"
#import <LGAlertView/LGAlertView.h>


#import "XXTEWorkspaceViewController.h"
#import "XXTENavigationController.h"

#import <StoreKit/StoreKit.h>

#import "XXTEMasterViewController.h"
#import "XXTExplorerViewController.h"

static NSString * const kXXTERatingPromptDisplayed = @"XXTERatingPromptDisplayed";

@class XXTEMasterViewController;

@interface XXTESplitViewController () <UISplitViewControllerDelegate>

@end

@implementation XXTESplitViewController

- (BOOL)shouldAutorotate {
    return self.viewControllers.firstObject.shouldAutorotate;
}

#pragma mark - Restore State

- (NSString *)restorationIdentifier {
    return [NSString stringWithFormat:@"ch.xxtou.restoration.%@", NSStringFromClass(self.class)];
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
    if (XXTE_IS_IPAD) {
        if (@available(iOS 8.0, *)) {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
            self.maximumPrimaryColumnWidth = 320.0;
        }
    }
    XXTE_END_IGNORE_PARTIAL
}

- (UIViewController *)masterViewController {
    return (self.viewControllers.count > 0) ? self.viewControllers[0] : nil;
}

- (UIViewController *)detailViewController {
    return (self.viewControllers.count > 1) ? self.viewControllers[1] : nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (!XXTE_IS_IPAD) {
        return self.masterViewController.preferredStatusBarStyle;
    } else {
        return self.detailViewController.preferredStatusBarStyle;
    }
}

- (BOOL)prefersStatusBarHidden {
    if (!XXTE_IS_IPAD) {
        return self.masterViewController.prefersStatusBarHidden;
    } else {
        return self.detailViewController.prefersStatusBarHidden;
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    if (!XXTE_IS_IPAD) {
        return self.masterViewController;
    } else {
        return self.detailViewController;
    }
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    if (!XXTE_IS_IPAD) {
        return self.masterViewController;
    } else {
        return self.detailViewController;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do extra operations
    
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [self registerNotifications];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeNotifications];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#ifdef APPSTORE
    if (@available(iOS 10.3, *)) {
        if ([SKStoreReviewController respondsToSelector:@selector(requestReview)])
        {
            NSInteger launchedTimes = XXTEDefaultsInt(kXXTELaunchedTimes, 0);
            if (launchedTimes >= 15)
            {
                BOOL promptDisplayed = XXTEDefaultsBool(kXXTERatingPromptDisplayed, NO);
                if (!promptDisplayed) {
                    [SKStoreReviewController requestReview];
                    XXTEDefaultsSetBasic(kXXTERatingPromptDisplayed, YES);
                }
            }
        }
    }
#endif
}

- (void)restoreWorkspaceViewControllerFromViewController:(UIViewController *)sender
{
    if (XXTE_IS_IPAD) { // cannot use collapsed check here
        if (@available(iOS 8.0, *))
        {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillRestoreWorkspace}]];
            XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
            XXTENavigationController *detailNavigationController = [[XXTENavigationController alloc] initWithRootViewController:detailViewController];
            [self showDetailViewController:detailNavigationController sender:sender];
        }
    }
}

- (void)restoreWorkspaceViewControllerFromDetailCloseItem:(UIBarButtonItem *)sender {
    [self restoreWorkspaceViewControllerFromViewController:self];
}

#pragma mark - UISplitViewDelegate

XXTE_START_IGNORE_PARTIAL
- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:svc userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode, XXTENotificationDetailDisplayMode: @(displayMode)}]];
}
XXTE_END_IGNORE_PARTIAL

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(id)sender {
    [self restoreTheme];
    return NO;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
    [self restoreTheme];
    return NO;
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return (splitViewController.viewControllers.count > 0) ? splitViewController.viewControllers[0] : nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    if ([[self.viewControllers firstObject] isKindOfClass:[UITabBarController class]]) {
        return NO;
    }
    return YES;
}

// DO NOT OVERRIDE preferredDisplayMode

#pragma mark - UIView Getters

- (UIBarButtonItem *)detailCloseItem {
    if (!_detailCloseItem) {
        _detailCloseItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XUICloseIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(restoreWorkspaceViewControllerFromDetailCloseItem:)];
    }
    return _detailCloseItem;
}

#pragma mark - Notifications

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XXTENotificationShortcut object:nil];
}

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    if ([aNotification.name isEqualToString:XXTENotificationShortcut]) {
        NSString *shortcutInterface = userInfo[XXTENotificationShortcutInterface];
        if ([shortcutInterface isEqualToString:@"workspace"])
        {
            [self restoreWorkspaceViewControllerFromViewController:self];
        }
    }
}

#pragma mark - Theme

- (void)restoreTheme {
    if (@available(iOS 8.0, *)) {
        self.displayModeButtonItem.tintColor = XXTColorTint();
    }
    self.detailCloseItem.tintColor = XXTColorTint();
}

#pragma mark - Getters

- (XXTEMasterViewController *)xxteMasterViewController {
    UIViewController *firstVC = [self.viewControllers firstObject];
    if ([firstVC isKindOfClass:[XXTEMasterViewController class]]) {
        XXTEMasterViewController *masterVC = (XXTEMasterViewController *)firstVC;
        return masterVC;
    }
    return nil;
}

- (XXTExplorerViewController *)masterExplorerViewController {
    return self.xxteMasterViewController.topmostExplorerViewController;
}

- (UIViewController <XXTEDetailViewController> *)xxteDetailViewController {
    UINavigationController *lastNav = [self.viewControllers lastObject];
    if ([lastNav isKindOfClass:[UINavigationController class]]) {
        UIViewController *lastVC = [lastNav.viewControllers firstObject];
        if ([lastVC conformsToProtocol:@protocol(XXTEDetailViewController)]) {
            UIViewController <XXTEDetailViewController> *detailVC = (UIViewController <XXTEDetailViewController> *)lastVC;
            return detailVC;
        }
    }
    return nil;
}

- (NSString *)masterExplorerEntryPath {
    return self.masterExplorerViewController.entryPath;
}

- (NSString *)detailEntryPath {
    if ([self.xxteDetailViewController respondsToSelector:@selector(entryPath)]) {
        return self.xxteDetailViewController.entryPath;
    }
    return nil;
}

@end
