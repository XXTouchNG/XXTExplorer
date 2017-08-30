//
//  XXTEMasterViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMasterViewController.h"
#import <LGAlertView/LGAlertView.h>

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

#import "XXTERespringAgent.h"
#import "XXTEDaemonAgent.h"

#import "XXTEAPTHelper.h"
#import "XXTEAPTPackage.h"
#import "XXTEUpdateAgent.h"

@interface XXTEMasterViewController () <XXTEDaemonAgentDelegate, XXTEAPTHelperDelegate, XXTEUpdateAgentDelegate, LGAlertViewDelegate>

@property(nonatomic, assign) BOOL checkUpdateInBackground;
@property(nonatomic, weak) LGAlertView *alertView;
@property(nonatomic, strong) XXTEDaemonAgent *daemonAgent;

@property (nonatomic, strong) NSString *packageIdentifier;
@property (nonatomic, strong) XXTEAPTHelper *aptHelper;
@property (nonatomic, strong) XXTEUpdateAgent *updateAgent;

@end

@implementation XXTEMasterViewController {
    BOOL firstTimeLoaded;
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setupAgents];
        [self setupAppearance];
        // UITabBarController is different
    }
    return self;
}

- (void)setupAppearance {
    [[UITabBar appearanceWhenContainedIn:[self class], nil] setTintColor:XXTE_COLOR];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.selectedViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.selectedViewController.prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!firstTimeLoaded) {
        [self launchAgents];
        firstTimeLoaded = YES;
    }
}

#pragma mark - Agents

- (void)setupAgents {
    NSString *packageIdentifier = uAppDefine(@"UPDATE_PACKAGE");
    self.packageIdentifier = packageIdentifier;
    
    NSString *repositoryURLString = uAppDefine(@"UPDATE_API");
    NSURL *repositoryURL = [NSURL URLWithString:repositoryURLString];
    
    XXTEAPTHelper *aptHelper = [[XXTEAPTHelper alloc] initWithRepositoryURL:repositoryURL];
    aptHelper.delegate = self;
    self.aptHelper = aptHelper;
    
    XXTEUpdateAgent *updateAgent = [[XXTEUpdateAgent alloc] initWithBundleIdentifier:packageIdentifier];
    updateAgent.delegate = self;
    self.updateAgent = updateAgent;
    
    XXTEDaemonAgent *daemonAgent = [[XXTEDaemonAgent alloc] init];
    daemonAgent.delegate = self;
    self.daemonAgent = daemonAgent;
}

- (void)launchAgents {
    BOOL shouldRespring = [XXTERespringAgent shouldPerformRespring];
    if (shouldRespring) {
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Needs Respring", nil)
                                                            message:NSLocalizedString(@"You should respring your device to continue using this application.", nil)
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:@[ ]
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:NSLocalizedString(@"Respring Now", nil)
                                                      actionHandler:nil
                                                      cancelHandler:nil
                                                 destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                                                     [alertView dismissAnimated];
                                                     blockUserInteractions(self, YES, 0);
                                                     [XXTERespringAgent performRespring];
                                                     blockUserInteractions(self, NO, 0);
                                                 }];
        if (self.alertView && self.alertView.isShowing) {
            [self.alertView transitionToAlertView:alertView completionHandler:nil];
        } else {
            self.alertView = alertView;
            [alertView showAnimated];
        }
    } else {
        [self.daemonAgent sync];
    }
}


#pragma mark - XXTEAPTHelperDelegate

- (void)aptHelperDidSyncReady:(XXTEAPTHelper *)helper {
    dispatch_async_on_main_queue(^{
        NSString *currentVersion = uAppDefine(@"DAEMON_VERSION");
        NSString *packageIdentifier = self.packageIdentifier;
        XXTEAPTPackage *packageModel = helper.packageMap[packageIdentifier];
        NSString *packageVersion = packageModel.apt_Version;
        if ([currentVersion isEqualToString:packageVersion]) {
            if (YES == self.checkUpdateInBackground) {
                [self.updateAgent ignoreThisDay];
            } else {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Latest Version", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Your version v%@ is up-to-date with remote.", nil), currentVersion]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[]
                                                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                     destructiveButtonTitle:nil
                                                                   delegate:self];
                if (self.alertView && self.alertView.isShowing) {
                    [self.alertView transitionToAlertView:alertView completionHandler:nil];
                } else {
                    self.alertView = alertView;
                    [alertView showAnimated];
                }
            }
            return;
        }
        BOOL shouldRemind = [self.updateAgent shouldRemindWithVersion:packageVersion];
        if (NO == self.checkUpdateInBackground || shouldRemind) {
            NSString *channelId = uAppDefine(@"CHANNEL_ID");
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"New Version", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"New version found: v%@\nCurrent version: v%@", nil), packageVersion, currentVersion]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[[NSString stringWithFormat:NSLocalizedString(@"Install via %@", nil), channelId], NSLocalizedString(@"Remind me tomorrow", nil)]
                                                      cancelButtonTitle:NSLocalizedString(@"Remind me later", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Ignore this version", nil) delegate:self];
            alertView.buttonsTextAlignment = NSTextAlignmentCenter;
            if (self.alertView && self.alertView.isShowing) {
                [self.alertView transitionToAlertView:alertView completionHandler:nil];
            } else {
                self.alertView = alertView;
                [alertView showAnimated];
            }
        }
    });
}

- (void)aptHelper:(XXTEAPTHelper *)helper didSyncFailWithError:(NSError *)error {
    dispatch_async_on_main_queue(^{
        if (NO == self.checkUpdateInBackground) {
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Cannot check update: %@", nil), error.localizedDescription]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[]
                                                      cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                 destructiveButtonTitle:nil
                                                               delegate:self];
            if (self.alertView && self.alertView.isShowing) {
                [self.alertView transitionToAlertView:alertView completionHandler:nil];
            } else {
                self.alertView = alertView;
                [alertView showAnimated];
            }
        }
    });
}

#pragma mark - XXTEDaemonAgentDelegate

- (void)daemonAgentDidSyncReady:(XXTEDaemonAgent *)agent {
    if (agent == self.daemonAgent) {
        [self checkUpdateBackground];
    }
}

- (void)daemonAgent:(XXTEDaemonAgent *)agent didFailWithError:(NSError *)error {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Sync Failed", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Cannot sync with daemon: %@", nil), error.localizedDescription]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[]
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                         destructiveButtonTitle:nil
                                                       delegate:self];
    if (self.alertView && self.alertView.isShowing) {
        [self.alertView transitionToAlertView:alertView completionHandler:nil];
    } else {
        self.alertView = alertView;
        [alertView showAnimated];
    }
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
    } else if (index == 1) {
        [self.updateAgent ignoreThisDay];
    }
    [alertView dismissAnimated];
}

- (void)alertViewDestructed:(LGAlertView *)alertView {
    [alertView dismissAnimated];
    NSString *packageIdentifier = self.packageIdentifier;
    XXTEAPTHelper *helper = self.aptHelper;
    XXTEAPTPackage *packageModel = helper.packageMap[packageIdentifier];
    NSString *packageVersion = packageModel.apt_Version;
    [self.updateAgent ignoreVersion:packageVersion];
    [self.updateAgent ignoreThisDay];
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

- (void)checkUpdateBackground {
    self.checkUpdateInBackground = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.aptHelper sync];
    });
}

- (void)checkUpdate {
    self.checkUpdateInBackground = NO;
    LGAlertView *alertView = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Check Update", nil)
                                                                            message:nil
                                                                              style:LGAlertViewStyleActionSheet
                                                                  progressLabelText:NSLocalizedString(@"Connect to the APT server...", nil)
                                                                       buttonTitles:nil
                                                                  cancelButtonTitle:nil
                                                             destructiveButtonTitle:nil
                                                                           delegate:self];
    if (self.alertView && self.alertView.isShowing) {
        [self.alertView transitionToAlertView:alertView completionHandler:nil];
    } else {
        self.alertView = alertView;
        [alertView showAnimated];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.aptHelper sync];
    });
}

@end
