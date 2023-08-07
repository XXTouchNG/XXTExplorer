//
//  XXTEMasterViewController+Notifications.m
//  XXTExplorer
//
//  Created by Zheng on 06/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTEMasterViewController+Notifications.h"


#import "XXTEViewer.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

#import "XXTENavigationController.h"
#import "XXTECommonWebViewController.h"
#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "NSString+QueryItems.h"
#import "UIViewController+TopMostViewController.h"

#import "XXTExplorerDefaults.h"

#import "XXTEMoreLicenseController.h"
#import "XXTEDownloadViewController.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>


@implementation XXTEMasterViewController (Notifications)

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
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
    else if ([aNotification.name isEqualToString:XXTENotificationEvent])
    {
        if ([eventType isEqualToString:XXTENotificationEventTypeInboxMoved]) {
            if (self.viewControllers.count >= kMasterViewControllerIndexExplorer &&
                self.selectedIndex != kMasterViewControllerIndexExplorer)
            {
                // switch to explorer
                [self setSelectedIndex:kMasterViewControllerIndexExplorer];
                NSMutableDictionary *mutableInfo = [aNotification.userInfo mutableCopy];
                if (!mutableInfo[XXTENotificationForwardedBy])
                {
                    mutableInfo[XXTENotificationForwardedBy] = self;
                    NSTimeInterval delaySeconds = [mutableInfo[XXTENotificationForwardDelay] doubleValue];
                    if (delaySeconds > 0.01)
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:aNotification.name object:aNotification.object userInfo:[mutableInfo copy]];
                        });
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:aNotification.name object:aNotification.object userInfo:[mutableInfo copy]];
                    }
                    // post this notification again
                }
            }
        } else if ([eventType isEqualToString:XXTENotificationEventTypeInbox]) {
            
            NSURL *inboxURL = aNotification.object;
            NSNumber *instantRun = userInfo[XXTENotificationViewImmediately];
            if (instantRun == nil) instantRun = @(NO);
            
            NSString *lastComponent = [inboxURL lastPathComponent];
            NSString *formerPath = [inboxURL path];
            NSString *currentPath = XXTExplorerViewController.initialPath;
            
            XXTExplorerNavigationController *explorerNavigationController = (self.viewControllers.count > 0) ? self.viewControllers[0] : nil;
            XXTExplorerViewController *topmostExplorerViewController = explorerNavigationController.topmostExplorerViewController;
            if (topmostExplorerViewController) {
                currentPath = topmostExplorerViewController.entryPath;
            }
            
            NSString *lastComponentName = [lastComponent stringByDeletingPathExtension];
            NSString *lastComponentExt = [lastComponent pathExtension];
            
            NSString *testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
            NSUInteger testedIndex = 2;
            struct stat inboxTestStat;
            while (0 == lstat(testedPath.UTF8String, &inboxTestStat)) {
                lastComponent = [[NSString stringWithFormat:@"%@-%lu", lastComponentName, (unsigned long)testedIndex] stringByAppendingPathExtension:lastComponentExt];
                testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
                testedIndex++;
            }
            
            @weakify(self);
            UIViewController *blockVC = blockInteractions(self, YES);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                @strongify(self);
                promiseFixPermission(currentPath, NO); // fix permission
                
                NSError *err = nil;
                NSFileManager *manager = [NSFileManager new];
                BOOL result = [manager moveItemAtPath:formerPath toPath:testedPath error:&err];
                dispatch_async_on_main_queue(^{
                    blockInteractions(blockVC, NO);
                    
                    if (result && err == nil) {
                        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:testedPath userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInboxMoved, XXTENotificationViewImmediately: instantRun}]];
                        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" saved.", nil), lastComponent]);
                    } else {
                        toastError(self, err);
                    }
                    
                });
                
            });
        }
        else if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive]) {
            XXTExplorerPasteboardDetectType detectType = XXTEDefaultsEnum(XXTExplorerPasteboardDetectOnActiveKey, XXTExplorerPasteboardDetectTypeNone);
            
            if (detectType != XXTExplorerPasteboardDetectTypeNone) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    UIPasteboard *pb = [UIPasteboard generalPasteboard];
                    if (detectType == XXTExplorerPasteboardDetectTypeAll || detectType == XXTExplorerPasteboardDetectTypeURL) {
                        NSURL *pasteboardURL = [pb URL];
                        if (!pasteboardURL) {
                            NSString *pasteboardString = [pb string];
                            if ([pasteboardString hasPrefix:@"http://"] || [pasteboardString hasPrefix:@"https://"]) {
                                pasteboardURL = [NSURL URLWithString:pasteboardString];
                            }
                        }
                        NSString *scheme = [pasteboardURL scheme];
                        if (scheme.length > 0) {
                            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
                            { // Download
                                dispatch_async_on_main_queue(^{
                                    NSString *pasteboardString = [pasteboardURL absoluteString];
                                    BOOL performResult = [self performShortcut:nil jsonOperation:@{ @"event": @"download", @"url": pasteboardString }];
                                    if (!performResult) {
                                        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot perform operation \"%@\" on Pasteboard URL \"%@\".", nil), NSLocalizedString(@"Download", nil), pasteboardURL]);
                                    }
                                    else {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                            [pb setValue:@"" forPasteboardType:UIPasteboardNameGeneral];
                                        });
                                    }
                                });
                            }
                            else if ([scheme isEqualToString:@"xxt"])
                            { // Native Open
                                dispatch_async_on_main_queue(^{
                                    if ([[UIApplication sharedApplication] canOpenURL:pasteboardURL])
                                    {
                                        XXTE_START_IGNORE_PARTIAL
                                        [[UIApplication sharedApplication] openURL:pasteboardURL];
                                        XXTE_END_IGNORE_PARTIAL
                                    }
                                    else
                                    {
                                        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot perform operation \"%@\" on Pasteboard URL \"%@\".", nil), NSLocalizedString(@"Native Open", nil), pasteboardURL]);
                                    }
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                        [pb setValue:@"" forPasteboardType:UIPasteboardNameGeneral];
                                    });
                                });
                            }
                            else
                            { // Unsupported
                                dispatch_async_on_main_queue(^{
                                    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Unsupported Pasteboard URL: \"%@\".", nil), pasteboardURL]);
                                });
                            }
                        }
                    }
                    if (detectType == XXTExplorerPasteboardDetectTypeAll || detectType == XXTExplorerPasteboardDetectTypeLicense) {
                        NSString *pasteboardString = [pb string];
                        if (pasteboardString) {
                            dispatch_async_on_main_queue(^{
                                NSString *regex = @"\\b([3-9A-Z]{16}|[3-9A-Z]{12})\\b";
                                NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:NULL];
                                NSTextCheckingResult *validMatch = ([pattern firstMatchInString:pasteboardString options:0 range:NSMakeRange(0, pasteboardString.length)]);
                                if (validMatch) {
                                    NSString *finalCode = [pasteboardString substringWithRange:validMatch.range];
                                    BOOL performResult = [self performShortcut:nil jsonOperation:@{ @"event": @"license", @"code": finalCode }];
                                    if (!performResult) {
                                        
                                    }
                                    else {
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                            [pb setValue:@"" forPasteboardType:UIPasteboardNameGeneral];
                                        });
                                    }
                                }
                            });
                        }
                    }
                });
            }
        }
    }
}

- (BOOL)performShortcut:(id)sender jsonOperation:(NSDictionary *)jsonDictionary {
    NSString *jsonEvent = jsonDictionary[@"event"];
    if (![jsonEvent isKindOfClass:[NSString class]]) {
        return NO;
    }
    if ([jsonEvent isEqualToString:@"workspace"]) {
        return YES; // handled by split view controller
    }
    else if ([jsonEvent isEqualToString:@"bind_code"] ||
             [jsonEvent isEqualToString:@"license"]) {
        NSString *licenseCode = jsonDictionary[@"code"];
        UIViewController *blockVC = blockInteractions(self, YES);
        @weakify(self);
        void (^ completionBlock)(void) = ^() {
            @strongify(self);
            blockInteractions(blockVC, NO);
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
        
        // check URL
        if (![jsonDictionary[@"url"] isKindOfClass:[NSString class]]) {
            return NO;
        }
        NSString *rawSourceURLString = jsonDictionary[@"url"];
        if (rawSourceURLString.length == 0) {
            return NO;
        }
        NSURL *sourceURL = [NSURL URLWithString:[rawSourceURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        
        // check Path
        if ((jsonDictionary[@"path"] && ![jsonDictionary[@"path"] isKindOfClass:[NSString class]])) {
            return NO;
        } // optional
        BOOL targetAutoDetection = NO;
        NSString *rawTargetPathString = jsonDictionary[@"path"];
        if (rawTargetPathString.length > 0) {
            targetAutoDetection = NO;
        } else {
            rawTargetPathString = [rawSourceURLString lastPathComponent];
            targetAutoDetection = YES;
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
        
        BOOL autoInstantRun = NO;
        if ([jsonDictionary[@"instantView"] isKindOfClass:[NSString class]]) {
            autoInstantRun = [jsonDictionary[@"instantView"] isEqualToString:@"true"];
        }
        UIViewController *blockVC = blockInteractions(self, YES);
        @weakify(self);
        void (^ completionBlock)(void) = ^() {
            @strongify(self);
            blockInteractions(blockVC, NO);
            XXTEDownloadViewController *downloadController = [[XXTEDownloadViewController alloc] initWithSourceURL:sourceURL targetPath:targetFixedPath];
            downloadController.allowsAutoDetection = targetAutoDetection;
            downloadController.autoInstantView = autoInstantRun;
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
    return NO;
}


#pragma mark - Button Actions

- (void)performAction:(id)sender stopSelectedScript:(NSString *)entryPath {
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"recycle") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot stop script: %@", nil), jsonDirectory[@"message"]];
        }
    })
    .catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (void)performAction:(id)sender launchScript:(NSString *)entryPath {
    BOOL selectAfterLaunch = XXTEDefaultsBool(XXTExplorerViewEntrySelectLaunchedScriptKey, NO);
    UIViewController *blockVC = blockInteractions(self, YES);
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
            if ([jsonDirectory[@"detail"] isKindOfClass:[NSString class]]) {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"detail"]];
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
            }
        }
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            if (selectAfterLaunch) {
                if (entryPath)
                {
                    return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ @"filename": entryPath }];
                } else {
                    return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ }];
                }
            }
        } else {
            if ([jsonDirectory[@"detail"] isKindOfClass:[NSString class]]) {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"detail"]];
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
            }
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
                if ([jsonDirectory[@"detail"] isKindOfClass:[NSString class]]) {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDirectory[@"detail"]];
                } else {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDirectory[@"message"]];
                }
            }
        }
    })
    .catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
}

#pragma mark - XXTEScanViewControllerDelegate

- (void)presentWebViewControllerWithURL:(NSURL *)url {
    XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:url];
    webController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:webController animated:YES completion:nil];
}

- (void)scanViewController:(XXTEScanViewController *)controller urlOperation:(NSURL *)url {
    UIViewController *blockVC = blockInteractions(self, YES);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        blockInteractions(blockVC, NO);
        BOOL internal = ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]);
        if (internal) {
            [self presentWebViewControllerWithURL:url];
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                XXTE_START_IGNORE_PARTIAL
                [[UIApplication sharedApplication] openURL:url];
                XXTE_END_IGNORE_PARTIAL
            }
        }
    }];
}

- (void)scanViewController:(XXTEScanViewController *)controller textOperation:(NSString *)detailText {
    UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
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
            blockInteractions(blockVC, NO);
        });
    }];
}

- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    [self performShortcut:controller jsonOperation:jsonDictionary];
}

@end
