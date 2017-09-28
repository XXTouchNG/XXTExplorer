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
#import "XXTENotificationCenterDefines.h"

#import "XXTERespringAgent.h"
#import "XXTEDaemonAgent.h"

#import "XXTEAPTHelper.h"
#import "XXTEAPTPackage.h"
#import "XXTEUpdateAgent.h"

#import "NSString+QueryItems.h"
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTECommonNavigationController.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

#import "XXTEViewer.h"

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
    
    LGAlertView *alertAppearance = [LGAlertView appearanceWhenContainedIn:[self class], nil];
    alertAppearance.coverColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        alertAppearance.coverBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    }
    XXTE_END_IGNORE_PARTIAL
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

- (BOOL)shouldAutorotate {
    return self.selectedViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.selectedViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.selectedViewController.preferredInterfaceOrientationForPresentation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
    [super viewWillAppear:animated];
    if (!firstTimeLoaded) {
        [self launchAgents];
        firstTimeLoaded = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
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
                                                     blockInteractionsWithDelay(self, YES, 0);
                                                     [XXTERespringAgent performRespring];
                                                     blockInteractions(self, NO);
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
            toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot open \"%@\".", nil), cydiaUrlString]));
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

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    if ([aNotification.name isEqualToString:XXTENotificationShortcut]) {
        NSString *userDataString = userInfo[XXTENotificationShortcutUserData];
        NSString *shortcutInterface = userInfo[XXTENotificationShortcutInterface];
        if (userDataString && shortcutInterface) {
            NSDictionary *queryStringDictionary = [userDataString queryItems];
            NSDictionary <NSString *, NSString *> *userDataDictionary = [[NSDictionary alloc] initWithDictionary:queryStringDictionary];
            NSMutableDictionary *mutableOperation = [@{ @"event": shortcutInterface } mutableCopy];
            for (NSString *operationKey in userDataDictionary)
                mutableOperation[operationKey] = userDataDictionary[operationKey];
            [self performShortcut:aNotification.object jsonOperation:[mutableOperation copy]];
        }
    }
}

- (void)performShortcut:(id)sender jsonOperation:(NSDictionary *)jsonDictionary {
    NSString *jsonEvent = jsonDictionary[@"event"];
    if (![jsonEvent isKindOfClass:[NSString class]]) {
        return;
    }
    if ([jsonEvent isEqualToString:@"xui"]) {
        NSString *bundlePath = jsonDictionary[@"bundle"];
        if (![bundlePath isKindOfClass:[NSString class]])
        {
            return; // invalid bundle path
        }
        if (bundlePath.length == 0) {
            return;
        }
        NSString *name = jsonDictionary[@"name"];
        if (!name) {
            // nothing to do... just left it as nil
        }
        if (name && ![name isKindOfClass:[NSString class]]) {
            return; // invalid name
        }
        if (name.length == 0) {
            // nothing to do... just left it as empty
        }
        BOOL interactive = NO;
        NSString *interactiveString = jsonDictionary[@"interactive"];
        if ([interactiveString isEqualToString:@"true"])
        {
            interactive = YES;
        }
        [self performAction:sender presentConfiguratorForBundleAtPath:bundlePath configurationName:name interactiveMode:interactive];
    }
}

- (void)performAction:(id)sender presentConfiguratorForBundleAtPath:(NSString *)bundlePath configurationName:(NSString *)name interactiveMode:(BOOL)interactive {
    NSError *entryError = nil;
    NSDictionary *entryDetail = [[XXTExplorerViewController explorerEntryParser] entryOfPath:bundlePath withError:&entryError];
    if (entryError) {
        toastMessageWithDelay(self, ([entryError localizedDescription]), 5.0);
        return;
    }
    if (!entryDetail) {
        return;
    }
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    if (![[XXTExplorerViewController explorerEntryService] hasConfiguratorForEntry:entryDetail]) {
        toastMessageWithDelay(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configurator can't be found.", nil), entryName]), 5.0);
        return;
    }
    UIViewController <XXTEViewer> *configurator = [[XXTExplorerViewController explorerEntryService] configuratorForEntry:entryDetail configurationName:name];
    if (!configurator) {
        toastMessageWithDelay(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configuration file can't be found or loaded.", nil), entryName]), 5.0);
        return;
    }
    configurator.awakeFromOutside = interactive;
    XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:configurator];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:^() {
        if (interactive)
            toastMessageWithDelay(configurator, NSLocalizedString(@"Press \"Home\" button to quit.\nTap to dismiss this notice.", nil), 6.0);
    }];
}

@end
