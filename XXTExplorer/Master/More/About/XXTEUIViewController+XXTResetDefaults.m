//
//  XXTEUIViewController+XXTResetDefaults.m
//  XXTExplorer
//
//  Created by Zheng Wu on 13/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+XXTResetDefaults.h"
#import <XUI/XUIButtonCell.h>
#import <LGAlertView/LGAlertView.h>

#import <PromiseKit/PromiseKit.h>
#import <NSURLConnection+PromiseKit.h>
#import <YYCache/YYCache.h>

#import <WebKit/WebKit.h>
#import "XXTExplorerEntryService.h"
#import "XXTECacheDefines.h"


@implementation XXTEUIViewController (XXTResetDefaults)

- (NSNumber *)xui_XXTResetDefaults:(XUIButtonCell *)cell {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Defaults", nil) message:NSLocalizedString(@"All user defaults will be removed, but your file will not be deleted.\nThis operation cannot be revoked.", nil) style:LGAlertViewStyleActionSheet buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Reset", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [self performResetDefaultsAtRemote];
    }];
    [alertView showAnimated];
    return @(YES);
}

#pragma mark - Reset Action

#ifndef APPSTORE
- (void)performResetDefaultsAtRemote {
    UIViewController *blockVC = blockInteractions(self, YES);
    [self promiseCleanCacheAndCookie]
    .then(^(id val) {
        return [NSURLConnection POST:uAppDaemonCommandUrl(@"reset_defaults") JSON:@{}];
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if (jsonDirectory[@"code"]) {
            // already been killed
            toastMessage(self, NSLocalizedString(@"Operation succeed.", nil));
#ifdef DEBUG
            UIApplication *app = [UIApplication sharedApplication];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [app performSelector:NSSelectorFromString(@"suspend")];
#pragma clang diagnostic pop
            if ([app.delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
                [app.delegate applicationWillTerminate:app];
            }
            [app performSelector:NSSelectorFromString(@"terminateWithSuccess") withObject:nil afterDelay:0.3];
#endif
        }
    })
    .catch(^(NSError *error) {
        toastDaemonError(self, error);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
}
#else
- (void)performResetDefaultsAtRemote {
    UIViewController *blockVC = blockInteractions(self, YES);
    [self promiseCleanCacheAndCookie]
    .then(^(NSNumber *val) {
        if (val && [val isKindOfClass:[NSNumber class]] && [val boolValue]) {
            toastMessage(self, NSLocalizedString(@"Operation succeed.", nil));
#ifdef DEBUG
            UIApplication *app = [UIApplication sharedApplication];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [app performSelector:NSSelectorFromString(@"suspend")];
#pragma clang diagnostic pop
            if ([app.delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
                [app.delegate applicationWillTerminate:app];
            }
            [app performSelector:NSSelectorFromString(@"terminateWithSuccess") withObject:nil afterDelay:0.3];
#endif
        }
    })
    .catch(^(NSError *error) {
        toastDaemonError(self, error);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
}
#endif

- (PMKPromise *)promiseCleanCacheAndCookie {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        [[XXTExplorerEntryService sharedInstance] setNeedsReload];
        [[YYCache cacheWithName:kEditorThemeMainColorCacheKey] removeAllObjects];
        
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            [storage deleteCookie:cookie];
        }
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
        NSURLCache *cache = [NSURLCache sharedURLCache];
        [cache removeAllCachedResponses];
        [cache setDiskCapacity:0];
        [cache setMemoryCapacity:0];
        
        if (@available(iOS 9.0, *)) {
            NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
            NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0.0];
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
                resolve(@(YES));
            }];
        } else {
            resolve(@(NO));
        }
        
    }];
}

@end
