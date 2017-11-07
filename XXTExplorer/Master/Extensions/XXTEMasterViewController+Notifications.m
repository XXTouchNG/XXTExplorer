//
//  XXTEMasterViewController+Notifications.m
//  XXTExplorer
//
//  Created by Zheng on 06/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMasterViewController+Notifications.h"

#import "XXTEDispatchDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTEViewer.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"
#import "NSString+QueryItems.h"

#import "XXTENavigationController.h"
#import "XXTECommonWebViewController.h"
#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"
#import "XXTExplorerViewController+SharedInstance.h"

#ifndef APPSTORE
    #import "XXTENetworkDefines.h"
    #import "XXTEMoreLicenseController.h"
    #import "XXTEDownloadViewController.h"
    #import <PromiseKit/PromiseKit.h>
    #import <PromiseKit/NSURLConnection+PromiseKit.h>
#endif

@implementation XXTEMasterViewController (Notifications)

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    if ([aNotification.name isEqualToString:XXTENotificationShortcut]) {
        id userData = userInfo[XXTENotificationShortcutUserData];
        NSString *shortcutInterface = userInfo[XXTENotificationShortcutInterface];
        if (userData && shortcutInterface) {
            NSDictionary *queryStringDictionary = nil;
            if ([userData isKindOfClass:[NSString class]]) {
                NSString *queryString = (NSString *)userData;
                queryStringDictionary = [queryString queryItems];
            } else if ([userData isKindOfClass:[NSDictionary class]]) {
                queryStringDictionary = (NSDictionary *)userData;
            } else {
                queryStringDictionary = @{};
            }
            NSDictionary <NSString *, NSString *> *userDataDictionary = [[NSDictionary alloc] initWithDictionary:queryStringDictionary];
            NSMutableDictionary *mutableOperation = [@{ @"event": shortcutInterface } mutableCopy];
            for (NSString *operationKey in userDataDictionary)
                mutableOperation[operationKey] = userDataDictionary[operationKey];
            BOOL performResult = [self performShortcut:aNotification.object jsonOperation:[mutableOperation copy]];
            if (!performResult) {
                toastMessage(self, NSLocalizedString(@"Invalid url parameters.", nil));
            }
        }
    }
}

- (BOOL)performShortcut:(id)sender jsonOperation:(NSDictionary *)jsonDictionary {
    NSString *jsonEvent = jsonDictionary[@"event"];
    if (![jsonEvent isKindOfClass:[NSString class]]) {
        return NO;
    }
    if ([jsonEvent isEqualToString:@"xui"]) {
        NSString *bundlePath = jsonDictionary[@"bundle"];
        if (![bundlePath isKindOfClass:[NSString class]])
        {
            return NO; // invalid bundle path
        }
        if (bundlePath.length == 0) {
            return NO;
        }
        NSString *name = jsonDictionary[@"name"];
        if (!name) {
            // nothing to do... just left it as nil
        }
        if (name && ![name isKindOfClass:[NSString class]]) {
            return NO; // invalid name
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
        return YES;
    }
#ifndef APPSTORE
    else if ([jsonEvent isEqualToString:@"bind_code"] ||
             [jsonEvent isEqualToString:@"license"]) {
        NSString *licenseCode = jsonDictionary[@"code"];
        blockInteractions(self, YES);
        @weakify(self);
        void (^ completionBlock)(void) = ^() {
            @strongify(self);
            blockInteractions(self, NO);
            XXTEMoreLicenseController *licenseController = [[XXTEMoreLicenseController alloc] initWithLicenseCode:licenseCode];
            XXTENavigationController *licenseNavigationController = [[XXTENavigationController alloc] initWithRootViewController:licenseController];
            licenseNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            licenseNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:licenseNavigationController animated:YES completion:nil];
        };
        if (sender && [sender isKindOfClass:[UIViewController class]])
        {
            UIViewController *controller = sender;
            [controller dismissViewControllerAnimated:YES completion:completionBlock];
            return YES;
        }
        completionBlock();
        return YES;
    }
    else if ([jsonEvent isEqualToString:@"down_script"] ||
             [jsonEvent isEqualToString:@"download"]) {
        if (![jsonDictionary[@"path"] isKindOfClass:[NSString class]] ||
            ![jsonDictionary[@"url"] isKindOfClass:[NSString class]]) {
            return NO;
        }
        NSString *rawSourceURLString = jsonDictionary[@"url"];
        if (rawSourceURLString.length == 0) {
            return NO;
        }
        NSURL *sourceURL = [NSURL URLWithString:[rawSourceURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        NSString *rawTargetPathString = jsonDictionary[@"path"];
        if (rawTargetPathString.length == 0) {
            return NO;
        }
        NSString *targetPath = [rawTargetPathString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        NSString *targetFullPath = nil;
        if ([targetPath isAbsolutePath]) {
            targetFullPath = targetPath;
        } else {
            XXTExplorerNavigationController *explorerNavigationController = (self.viewControllers.count > 0) ? self.viewControllers[0] : nil;
            XXTExplorerViewController *topmostExplorerViewController = explorerNavigationController.topmostExplorerViewController;
            targetFullPath = [topmostExplorerViewController.entryPath stringByAppendingPathComponent:targetPath];
        }
        NSString *targetFixedPath = [targetFullPath stringByRemovingPercentEncoding];
        blockInteractions(self, YES);
        @weakify(self);
        void (^ completionBlock)(void) = ^() {
            @strongify(self);
            blockInteractions(self, NO);
            XXTEDownloadViewController *downloadController = [[XXTEDownloadViewController alloc] initWithSourceURL:sourceURL targetPath:targetFixedPath];
            XXTENavigationController *downloadNavigationController = [[XXTENavigationController alloc] initWithRootViewController:downloadController];
            downloadNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            downloadNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:downloadNavigationController animated:YES completion:nil];
        };
        if (sender && [sender isKindOfClass:[UIViewController class]]) {
            UIViewController *controller = sender;
            [controller dismissViewControllerAnimated:YES completion:completionBlock];
            return YES;
        }
        completionBlock();
        return YES;
    }
    else if ([jsonEvent isEqualToString:@"launch"])
    {
        NSString *scriptPath = jsonDictionary[@"path"];
        if (![scriptPath isKindOfClass:[NSString class]]) {
            scriptPath = [XXTExplorerViewController selectedScriptPath];
        }
        [self performAction:sender launchScript:scriptPath];
        return YES;
    } else if ([jsonEvent isEqualToString:@"stop"])
    {
        NSString *scriptPath = jsonDictionary[@"path"];
        if (![scriptPath isKindOfClass:[NSString class]]) {
            scriptPath = [XXTExplorerViewController selectedScriptPath];
        }
        [self performAction:sender stopSelectedScript:scriptPath];
        return YES;
    }
    else if ([jsonEvent isEqualToString:@"scan"]) {
        XXTEScanViewController *scanViewController = [[XXTEScanViewController alloc] init];
        scanViewController.shouldConfirm = YES;
        scanViewController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
        return YES;
    }
#endif
    return NO;
}

- (BOOL)performAction:(id)sender presentConfiguratorForBundleAtPath:(NSString *)bundlePath configurationName:(NSString *)name interactiveMode:(BOOL)interactive {
    NSError *entryError = nil;
    NSDictionary *entryDetail = [[XXTExplorerViewController explorerEntryParser] entryOfPath:bundlePath withError:&entryError];
    if (entryError) {
        toastMessageWithDelay(self, ([entryError localizedDescription]), 5.0);
        return NO;
    }
    if (!entryDetail) {
        return NO;
    }
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    if (![[XXTExplorerViewController explorerEntryService] hasConfiguratorForEntry:entryDetail]) {
        toastMessageWithDelay(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configurator can't be found.", nil), entryName]), 5.0);
        return NO;
    }
    UIViewController <XXTEViewer> *configurator = [[XXTExplorerViewController explorerEntryService] configuratorForEntry:entryDetail configurationName:name];
    if (!configurator) {
        toastMessageWithDelay(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configuration file can't be found or loaded.", nil), entryName]), 5.0);
        return NO;
    }
    configurator.awakeFromOutside = interactive;
    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:configurator];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:^() {
        if (interactive)
            toastMessageWithDelay(configurator, NSLocalizedString(@"Press \"Home\" button to quit.\nTap to dismiss this notice.", nil), 6.0);
    }];
    return YES;
}

#pragma mark - Button Actions

#ifndef APPSTORE
- (void)performAction:(id)sender stopSelectedScript:(NSString *)entryPath {
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"recycle") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot stop script: %@", nil), jsonDirectory[@"message"]];
        }
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)performAction:(id)sender launchScript:(NSString *)entryPath {
    BOOL selectAfterLaunch = XXTEDefaultsBool(XXTExplorerViewEntrySelectLaunchedScriptKey, NO);
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"is_running") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            if (entryPath)
            {
                return [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{@"filename": entryPath, @"envp": uAppConstEnvp()}];
            } else {
                return [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{ }];
            }
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            if (selectAfterLaunch) {
                if (entryPath)
                {
                    return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{@"filename": entryPath}];
                } else {
                    return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ }];
                }
            }
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
        return [PMKPromise promiseWithValue:@{}];
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            if (entryPath)
            {
                XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, entryPath);
            }
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:sender userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeSelectedScriptPathChanged}]];
        } else {
            if (selectAfterLaunch) {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDirectory[@"message"]];
            }
        }
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#pragma mark - XXTEScanViewControllerDelegate

#ifndef APPSTORE
- (void)scanViewController:(XXTEScanViewController *)controller urlOperation:(NSURL *)url {
    blockInteractions(self, YES);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        blockInteractions(self, NO);
        BOOL internal = ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]);
        if (internal) {
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:url];
            webController.title = NSLocalizedString(@"Loading...", nil);
            XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:webController];
            if (webController) {
                if (XXTE_COLLAPSED) {
                    XXTE_START_IGNORE_PARTIAL
                    if (@available(iOS 8.0, *)) {
                        [self.splitViewController showDetailViewController:navigationController sender:self];
                    }
                    XXTE_END_IGNORE_PARTIAL
                } else {
                    [self presentViewController:navigationController animated:YES completion:^{
                        
                    }];
                }
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];
}
#endif

#ifndef APPSTORE
- (void)scanViewController:(XXTEScanViewController *)controller textOperation:(NSString *)detailText {
    blockInteractions(self, YES);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[UIPasteboard generalPasteboard] setString:detailText];
                fulfill(nil);
            });
        }].finally(^() {
            toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
            blockInteractions(self, NO);
        });
    }];
}
#endif

#ifndef APPSTORE
- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    [self performShortcut:controller jsonOperation:jsonDictionary];
}
#endif

@end
