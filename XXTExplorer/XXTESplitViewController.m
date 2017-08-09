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
#import "XXTENotificationCenterDefines.h"
#import "XXTESplitViewController_APTUpdate.h"

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"

@interface XXTESplitViewController () <UISplitViewControllerDelegate>


@end

@implementation XXTESplitViewController

- (instancetype)init {
    if (self = [super init]) {
        self.delegate = self;
        [self setupAPT];
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
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
    [self checkUpdate];
}

#pragma mark - UISplitViewDelegate

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:svc userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode, XXTENotificationDetailDisplayMode: @(displayMode)}]];
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return splitViewController.viewControllers[0];
}

#pragma mark - APTUpdate

- (void)setupAPT {
    NSString *packageIdentifier = uAppDefine(@"UPDATE_PACKAGE");
    self.packageIdentifier = packageIdentifier;
    
    NSString *repositoryURLString = uAppDefine(@"UPDATE_API");
    NSURL *repositoryURL = [NSURL URLWithString:repositoryURLString];
    
    XXTEAPTHelper *aptHelper = [[XXTEAPTHelper alloc] initWithRepositoryURL:repositoryURL];
    aptHelper.delegate = self;
    self.aptHelper = aptHelper;
    
    XXTEUpdateReminder *updateReminder = [[XXTEUpdateReminder alloc] initWithBundleIdentifier:packageIdentifier];
    updateReminder.delegate = self;
    self.updateReminder = updateReminder;
}

#pragma mark - XXTEAPTHelperDelegate

- (void)aptHelperDidSyncReady:(XXTEAPTHelper *)helper {
    NSString *currentVersion = uAppDefine(@"DAEMON_VERSION");
    NSString *packageIdentifier = self.packageIdentifier;
    XXTEAPTPackage *packageModel = helper.packageMap[packageIdentifier];
    NSString *packageVersion = packageModel.apt_Version;
    if ([currentVersion isEqualToString:packageVersion]) {
        [self.updateReminder ignoreThisDay];
        return;
    }
    BOOL shouldRemind = [self.updateReminder shouldRemindWithVersion:packageVersion];
    if (shouldRemind) {
        NSString *channelId = uAppDefine(@"CHANNEL_ID");
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"New Version", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"New version found: v%@\nCurrent version: v%@", nil), packageVersion, currentVersion]
                                                              style:LGAlertViewStyleActionSheet
                                                       buttonTitles:@[ [NSString stringWithFormat:NSLocalizedString(@"Install via %@", nil), channelId], NSLocalizedString(@"Only Download", nil), NSLocalizedString(@"Remind me tomorrow", nil) ]
                                                  cancelButtonTitle:NSLocalizedString(@"Remind me later", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Ignore this version", nil) delegate:self];
        alertView.buttonsTextAlignment = NSTextAlignmentCenter;
        [alertView showAnimated];
    }
}

- (void)aptHelper:(XXTEAPTHelper *)helper didSyncFailWithError:(NSError *)error {
    
}

#pragma mark - LGAlertViewDelegate

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    if (index == 0) {
        NSString *cydiaUrlString = uAppDefine(@"CYDIA_URL");
        NSURL *cydiaUrl = [NSURL URLWithString:cydiaUrlString];
        if ([[UIApplication sharedApplication] canOpenURL:cydiaUrl]) {
            [[UIApplication sharedApplication] openURL:cydiaUrl];
        } else {
            showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot open \"%@\".", nil), cydiaUrlString]);
        }
    }
    else if (index == 1) {
        showUserMessage(self, NSLocalizedString(@"Not implemented.", nil));
    }
    else if (index == 2) {
        [self.updateReminder ignoreThisDay];
    }
    [alertView dismissAnimated];
}

- (void)alertViewDestructed:(LGAlertView *)alertView {
    [alertView dismissAnimated];
    NSString *packageIdentifier = self.packageIdentifier;
    XXTEAPTHelper *helper = self.aptHelper;
    XXTEAPTPackage *packageModel = helper.packageMap[packageIdentifier];
    NSString *packageVersion = packageModel.apt_Version;
    [self.updateReminder ignoreVersion:packageVersion];
    [self.updateReminder ignoreThisDay];
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

- (void)checkUpdate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.aptHelper sync];
    });
}

// TODO: server respring test
// TODO: server connection test

@end
