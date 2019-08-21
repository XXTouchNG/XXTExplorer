//
//  XXTEMasterViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMasterViewController.h"
#import <LGAlertView/LGAlertView.h>
#import "XXTEMasterViewController+Notifications.h"

#import "UIView+XXTEToast.h"
#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"

#ifndef APPSTORE

#import "NSString+Template.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import "XXTERespringAgent.h"
#import "XXTEDaemonAgent.h"

#import "XXTEUpdateHelper.h"
#import "XXTEUpdatePackage.h"
#import "XXTEUpdateAgent.h"

#endif

#ifndef APPSTORE
@interface XXTEMasterViewController () <XXTEDaemonAgentDelegate, XXTEUpdateHelperDelegate, XXTEUpdateAgentDelegate, LGAlertViewDelegate>

@property(nonatomic, assign) BOOL checkUpdateInBackground;
@property(nonatomic, weak) LGAlertView *alertView;
@property(nonatomic, strong) XXTEDaemonAgent *daemonAgent;

@property (nonatomic, strong) XXTEUpdateHelper *jsonHelper;
@property (nonatomic, strong) XXTEUpdateAgent *updateAgent;

@end
#endif

@implementation XXTEMasterViewController {
    BOOL firstTimeLoaded;
}

#pragma mark - Initializers

#ifndef APPSTORE
- (instancetype)init {
    if (self = [super init]) {
        // UITabBarController is different
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"XXTEMasterViewController is a singleton.");
            alreadyInitialized = YES;
            [self setupAgents];
            [self setupAppearance];
        });
    }
    return self;
}
#else
- (instancetype)init {
    if (self = [super init]) {
        NSAssert(NO, @"XXTEMasterViewController must be initialized with a rootViewController.");
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self setupAppearance];
    }
    return self;
}
#endif

+ (void)setupAlertDefaultAppearance:(LGAlertView *)alertAppearance {
    if (@available(iOS 8.0, *)) {
        alertAppearance.coverColor = [UIColor clearColor];
        alertAppearance.coverBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        alertAppearance.backgroundColor = [UIColor clearColor];
        alertAppearance.backgroundBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    } else {
        alertAppearance.coverColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        alertAppearance.backgroundColor = [UIColor clearColor];
    }
    alertAppearance.separatorsColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    alertAppearance.coverAlpha = 0.85;
    alertAppearance.layerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    alertAppearance.layerShadowRadius = 4.0;
    alertAppearance.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    alertAppearance.buttonsHeight = 44.0;
    alertAppearance.titleFont = [UIFont boldSystemFontOfSize:16.0];
    alertAppearance.titleTextColor = XXTColorPlainTitleText();
    alertAppearance.messageTextColor = XXTColorPlainTitleText();
    alertAppearance.activityIndicatorViewColor = XXTColorForeground();
    alertAppearance.progressViewProgressTintColor = XXTColorForeground();
    alertAppearance.progressLabelTextColor = XXTColorPlainTitleText();
    alertAppearance.buttonsFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.buttonsTitleColor = XXTColorForeground();
    alertAppearance.buttonsBackgroundColorHighlighted = XXTColorFixed();
    alertAppearance.cancelButtonFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.cancelButtonTitleColor = XXTColorForeground();
    alertAppearance.cancelButtonBackgroundColorHighlighted = XXTColorFixed();
    alertAppearance.destructiveButtonFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.destructiveButtonTitleColor = XXTColorDanger();
    alertAppearance.destructiveButtonBackgroundColorHighlighted = XXTColorDanger();
    alertAppearance.textFieldsBackgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    alertAppearance.textFieldsTextColor = XXTColorPlainTitleText();
    alertAppearance.progressLabelFont = [UIFont italicSystemFontOfSize:14.f];
    alertAppearance.progressLabelLineBreakMode = NSLineBreakByTruncatingHead;
    alertAppearance.dismissOnAction = NO;
    alertAppearance.buttonsIconPosition = LGAlertViewButtonIconPositionLeft;
    alertAppearance.buttonsTextAlignment = NSTextAlignmentCenter;
    if (@available(iOS 11.0, *)) {
        CGFloat bottomOffset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        alertAppearance.cancelButtonOffsetY = bottomOffset;
    }
}

+ (void)setupAlertDarkAppearance:(LGAlertView *)alertAppearance {
    UIColor *labelColor = [UIColor colorWithRed:197.0/255.0 green:200.0/255.0 blue:198.0/255.0 alpha:1.0];
    if (@available(iOS 8.0, *)) {
        alertAppearance.coverColor = [UIColor clearColor];
        alertAppearance.coverBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        alertAppearance.backgroundColor = [UIColor clearColor];
        alertAppearance.backgroundBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    } else {
        alertAppearance.coverColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        alertAppearance.backgroundColor = [UIColor clearColor];
    }
    alertAppearance.separatorsColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    alertAppearance.coverAlpha = 0.85;
    alertAppearance.buttonsHeight = 44.0;
    alertAppearance.titleFont = [UIFont boldSystemFontOfSize:16.0];
    alertAppearance.titleTextColor = labelColor;
    alertAppearance.messageTextColor = labelColor;
    alertAppearance.activityIndicatorViewColor = labelColor;
    alertAppearance.progressViewProgressTintColor = [UIColor whiteColor];
    alertAppearance.progressLabelTextColor = labelColor;
    alertAppearance.buttonsFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.buttonsTitleColor = XXTColorForeground();
    alertAppearance.buttonsBackgroundColorHighlighted = XXTColorCellSelected();
    alertAppearance.cancelButtonFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.cancelButtonTitleColor = labelColor;
    alertAppearance.cancelButtonBackgroundColorHighlighted = XXTColorCellSelected();
    alertAppearance.destructiveButtonFont = [UIFont systemFontOfSize:16.0];
    alertAppearance.destructiveButtonTitleColor = XXTColorDanger();
    alertAppearance.destructiveButtonBackgroundColorHighlighted = XXTColorDanger();
    alertAppearance.textFieldsBackgroundColor = [UIColor colorWithWhite:0.0 alpha:0.03];
    alertAppearance.textFieldsTextColor = labelColor;
    alertAppearance.textFieldsButtonClearColor = [labelColor colorWithAlphaComponent:0.6];
    alertAppearance.textFieldsButtonClearColorHighlighted = labelColor;
    alertAppearance.progressLabelFont = [UIFont italicSystemFontOfSize:14.f];
    alertAppearance.progressLabelLineBreakMode = NSLineBreakByTruncatingHead;
    alertAppearance.dismissOnAction = NO;
    alertAppearance.buttonsIconPosition = LGAlertViewButtonIconPositionLeft;
    alertAppearance.buttonsTextAlignment = NSTextAlignmentCenter;
    if (@available(iOS 11.0, *)) {
        CGFloat bottomOffset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
        alertAppearance.cancelButtonOffsetY = bottomOffset;
    }
}

- (void)setupAppearance {
    UITabBar *tabBarAppearance = [UITabBar appearanceWhenContainedIn:[self class], nil];
    [tabBarAppearance setTintColor:XXTColorForeground()];
    
#ifndef APPSTORE
    if (@available(iOS 11.0, *)) {
        self.tabBar.translucent = YES;
    } else {
        self.tabBar.translucent = NO;
    }
#else
    if (@available(iOS 11.0, *)) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
    }
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Files", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
#endif
    
    if (@available(iOS 13.0, *)) {
        [self updateAlertViewStyle];
    } else {
        LGAlertView *alertAppearanceDefault = [LGAlertView appearanceWhenContainedIn:[self class], nil];
        [self.class setupAlertDefaultAppearance:alertAppearanceDefault];
    }
    
    [XXTEToastManager setTapToDismissEnabled:YES];
    [XXTEToastManager setDefaultDuration:2.4f];
    [XXTEToastManager setQueueEnabled:NO];
    [XXTEToastManager setDefaultPosition:XXTEToastPositionCenter];
    
    XXTEToastStyle *toastStyle = [XXTEToastManager sharedStyle];
    toastStyle.backgroundColor = [UIColor colorWithWhite:0.f alpha:.6f];
    toastStyle.titleFont = [UIFont boldSystemFontOfSize:14.f];
    toastStyle.messageFont = [UIFont systemFontOfSize:14.f];
    toastStyle.activitySize = CGSizeMake(80.f, 80.f);
    toastStyle.verticalMargin = 16.f;
    toastStyle.horizontalPadding = 16.f;
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont systemFontOfSize:16.0]];
}

#ifdef APPSTORE
- (UIViewController *)selectedViewController {
    return self.topViewController;
}
#endif

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
} // do not write any stuff inside this method...

- (void)viewWillAppear:(BOOL)animated {
    [self registerNotifications];
    [super viewWillAppear:animated];
#ifndef APPSTORE
    if (!firstTimeLoaded) {
        [self launchAgents];
        firstTimeLoaded = YES;
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeNotifications];
    [super viewWillDisappear:animated];
}

#pragma mark - Agents

#ifndef APPSTORE
- (void)setupAgents {
    NSString *productName = uAppDefine(@"UPDATE_PRODUCT");
    NSString *repositoryURLString = uAppDefine(@"UPDATE_API");
    NSURL *repositoryURL = [NSURL URLWithString:[NSString stringWithFormat:repositoryURLString, productName]];
    
    XXTEUpdateHelper *jsonHelper = [[XXTEUpdateHelper alloc] initWithRepositoryURL:repositoryURL];
    jsonHelper.delegate = self;
    self.jsonHelper = jsonHelper;
    
    XXTEUpdateAgent *updateAgent = [[XXTEUpdateAgent alloc] initWithBundleIdentifier:productName];
    updateAgent.delegate = self;
    self.updateAgent = updateAgent;
    
    XXTEDaemonAgent *daemonAgent = [[XXTEDaemonAgent alloc] init];
    daemonAgent.delegate = self;
    self.daemonAgent = daemonAgent;
}
#endif

#ifndef APPSTORE
- (void)launchAgents {
    BOOL shouldRespring = [XXTERespringAgent shouldPerformRespring];
    if (shouldRespring) {
        @weakify(self);
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Needs Respring", nil)
                                                            message:NSLocalizedString(@"You should respring your device to continue using this application.", nil)
                                                              style:LGAlertViewStyleAlert
                                                       buttonTitles:@[ NSLocalizedString(@"Troubleshooting", nil) ]
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:NSLocalizedString(@"Respring Now", nil)
                                                      actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                                                          @strongify(self);
                                                          [alertView dismissAnimated];
                                                          self.alertView = nil;
                                                          if (index == 0) {
                                                              NSURL *faqURL = [NSURL URLWithString:uAppDefine(@"XXTOUCH_FAQ_0018")];
                                                              if (faqURL) {
                                                                  [self presentWebViewControllerWithURL:faqURL];
                                                              }
                                                          }
                                                      }
                                                      cancelHandler:nil
                                                 destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                                                     @strongify(self);
                                                     [alertView dismissAnimated];
                                                     self.alertView = nil;
                                                     UIViewController *blockVC = blockInteractions(self, YES);
                                                     [XXTERespringAgent performRespring];
                                                     blockInteractions(blockVC, NO);
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
#endif

#pragma mark - XXTEUpdateHelperDelegate

#ifndef APPSTORE
- (void)jsonHelperDidSyncReady:(XXTEUpdateHelper *)helper {
    dispatch_async_on_main_queue(^{
        NSString *currentVersion = uAppDefine(kXXTDaemonVersionKey);
        XXTEUpdatePackage *packageModel = helper.respPackage;
        NSString *packageVersion = packageModel.latestVersion;
        NSString *packageDescription = packageModel.updateDescription;
        if ([currentVersion isEqualToString:packageVersion]) {
            if (YES == self.checkUpdateInBackground) {
                
            } else {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Latest Version", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Your version v%@ is up-to-date with remote.", nil), currentVersion]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[ ]
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
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"New Version: %@", nil), packageVersion]
                                                                message:[NSString stringWithFormat:@"%@", packageDescription]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[
                                                                          [NSString stringWithFormat:NSLocalizedString(@"Install via %@", nil), channelId], NSLocalizedString(@"Remind me tomorrow", nil)
                                                                          ]
                                                      cancelButtonTitle:NSLocalizedString(@"Remind me later", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Ignore this version", nil) delegate:self];
            if (self.alertView && self.alertView.isShowing) {
                [self.alertView transitionToAlertView:alertView completionHandler:nil];
            } else {
                self.alertView = alertView;
                [alertView showAnimated];
            }
        }
    });
}
#endif

#ifndef APPSTORE
- (void)jsonHelper:(XXTEUpdateHelper *)helper didSyncFailWithError:(NSError *)error {
    dispatch_async_on_main_queue(^{
        if (NO == self.checkUpdateInBackground) {
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Cannot check update: %@", nil), error.localizedDescription]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[ ]
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
#endif

#pragma mark - XXTEDaemonAgentDelegate

#ifndef APPSTORE
- (void)daemonAgentDidSyncReady:(XXTEDaemonAgent *)agent {
    if (agent == self.daemonAgent) {
        [self checkUpdateBackground];
    }
}
#endif

#ifndef APPSTORE
- (void)daemonAgent:(XXTEDaemonAgent *)agent didFailWithError:(NSError *)error {
    @weakify(self);
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Sync Failed", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Cannot sync with daemon: %@", nil), error.localizedDescription]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[ NSLocalizedString(@"Troubleshooting", nil) ]
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                         destructiveButtonTitle:nil
                                                  actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                                                      @strongify(self);
                                                      [alertView dismissAnimated];
                                                      self.alertView = nil;
                                                      if (index == 0) {
                                                          NSURL *faqURL = [NSURL URLWithString:uAppDefine(@"XXTOUCH_FAQ_0017")];
                                                          if (faqURL) {
                                                              [self presentWebViewControllerWithURL:faqURL];
                                                          }
                                                      }
                                                  } cancelHandler:^(LGAlertView * _Nonnull alertView) {
                                                      @strongify(self);
                                                      [alertView dismissAnimated];
                                                      self.alertView = nil;
                                                  } destructiveHandler:nil];
    if (self.alertView && self.alertView.isShowing) {
        [self.alertView transitionToAlertView:alertView completionHandler:nil];
    } else {
        self.alertView = alertView;
        [alertView showAnimated];
    }
}
#endif

#pragma mark - LGAlertViewDelegate

#ifndef APPSTORE
- (void (^)(NSString *cydiaURLString))cydiaFinallyBlock {
    return ^void(NSString *cydiaURLString) {
        if (cydiaURLString)
        {
            NSURL *cydiaURL = [NSURL URLWithString:cydiaURLString];
            if ([[UIApplication sharedApplication] canOpenURL:cydiaURL])
            {
                [[UIApplication sharedApplication] openURL:cydiaURL];
            }
            else
            {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot open \"%@\".", nil), cydiaURLString]));
            }
        }
    };
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    if (index == 0)
    {
        XXTEUpdateHelper *helper = self.jsonHelper;
        XXTEUpdatePackage *packageModel = helper.respPackage;
        if (!helper || !packageModel)
        {
            [alertView dismissAnimated]; self.alertView = nil;
            return;
        }
        
        NSString *templateURLString = packageModel.templateURLString;
        if (templateURLString)
        {
            [self processingTemplateAtURLString:templateURLString];
        }
        else
        {
            NSString *urlString = packageModel.cydiaURLString;
            if (urlString)
            {
                [self cydiaFinallyBlock](urlString);
            }
        }
        
    } else if (index == 1) {
        [self.updateAgent ignoreThisDay];
    }
    [alertView dismissAnimated];
    self.alertView = nil;
}
#endif

#ifndef APPSTORE
- (void)processingTemplateAtURLString:(NSString *)templateURLString {
    XXTEUpdateHelper *helper = self.jsonHelper;
    XXTEUpdatePackage *packageModel = helper.respPackage;
    if (!helper || !packageModel)
    {
        return;
    }
    UIViewController *blockController = blockInteractions(self, YES);
    [NSURLConnection GET:templateURLString query:@{}]
    .then(^(NSString *templateResp) {
        XXTEUpdatePackage *pkg = helper.respPackage;
        NSString *loc = helper.temporarilyLocation;
        if (pkg && loc)
        {
            if ([templateResp isKindOfClass:[NSString class]])
            {
                NSString *templateString = templateResp;
                templateString = [templateString stringByReplacingTagsInDictionary:[pkg toDictionary]];
                NSString *uuidString = [[NSUUID UUID] UUIDString];
                NSString *templatePath = [[loc stringByAppendingPathComponent:[@"template-" stringByAppendingString:uuidString]] stringByAppendingPathExtension:@"html"];
                BOOL writeResult = [[templateString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:templatePath atomically:YES];
                if (writeResult)
                {
                    return [PMKPromise promiseWithValue:templatePath];
                }
            }
        }
        return [PMKPromise promiseWithValue:nil];
    })
    .then(^(NSString *templatePath) {
        if (templatePath) {
            NSString *cydiaURLString = uAppDefine(@"CYDIA_URL");
            if (cydiaURLString) {
                return [PMKPromise promiseWithValue:[NSString stringWithFormat:cydiaURLString, templatePath]];
            }
        }
        return [PMKPromise promiseWithValue:nil];
    })
    .then(^(NSString *cydiaURLString) {
        if (cydiaURLString) {
            [self cydiaFinallyBlock](cydiaURLString);
        } else {
            NSString *urlString = packageModel.cydiaURLString;
            if (urlString) {
                [self cydiaFinallyBlock](urlString);
            }
        }
    })
    .catch(^(NSError *error) {
        toastError(self, error);
    })
    .finally(^ {
        blockInteractions(blockController, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertViewDestructed:(LGAlertView *)alertView {
    [alertView dismissAnimated]; self.alertView = nil;
    XXTEUpdateHelper *helper = self.jsonHelper;
    XXTEUpdatePackage *packageModel = helper.respPackage;
    NSString *packageVersion = packageModel.latestVersion;
    [self.updateAgent ignoreVersion:packageVersion];
    [self.updateAgent ignoreThisDay];
}
#endif

#ifndef APPSTORE
- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated]; self.alertView = nil;
}
#endif

#ifndef APPSTORE
- (void)checkUpdateBackground {
    self.checkUpdateInBackground = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self.jsonHelper sync];
    });
}
#endif

#ifndef APPSTORE
- (void)checkUpdate {
    self.checkUpdateInBackground = NO;
    LGAlertView *alertView = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Check Update", nil)
                                                                            message:nil
                                                                              style:LGAlertViewStyleActionSheet
                                                                  progressLabelText:NSLocalizedString(@"Connect to the update server...", nil)
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
        [self.jsonHelper sync];
    });
}
#endif

#pragma mark - Getters

#ifndef APPSTORE
- (XXTExplorerViewController *)topmostExplorerViewController {
    UIViewController *firstFirstVC = [self.viewControllers firstObject];
    if ([firstFirstVC isKindOfClass:[XXTExplorerNavigationController class]]) {
        XXTExplorerNavigationController *navVC = (XXTExplorerNavigationController *)firstFirstVC;
        return [navVC topmostExplorerViewController];
    }
    return nil;
}
#else
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
#endif

#pragma mark - UITraitEnvironment

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self updateAlertViewStyle];
}

- (void)updateAlertViewStyle {
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
            LGAlertView *alertAppearanceDefault = [LGAlertView appearanceWhenContainedIn:[self class], nil];
            [self.class setupAlertDefaultAppearance:alertAppearanceDefault];
        } else {
            LGAlertView *alertAppearanceDark = [LGAlertView appearanceWhenContainedIn:[self class], nil];
            [self.class setupAlertDarkAppearance:alertAppearanceDark];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
