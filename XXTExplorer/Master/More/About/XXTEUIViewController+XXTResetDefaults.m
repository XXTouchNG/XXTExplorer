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

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"
#import <PromiseKit/PromiseKit.h>
#import <NSURLConnection+PromiseKit.h>

#import <WebKit/WebKit.h>

@implementation XXTEUIViewController (XXTResetDefaults)

- (NSNumber *)xui_XXTResetDefaults:(XUIButtonCell *)cell {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Defaults", nil) message:NSLocalizedString(@"All user defaults will be removed, but your file will not be deleted.\nThis operation cannot be revoked.", nil) style:LGAlertViewStyleActionSheet buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Reset", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        [alertView dismissAnimated];
        [self performResetDefaultsAtRemote];
    }];
    [alertView showAnimated];
    return @(YES);
}

#pragma mark - Reset Action

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
        }
    })
    .catch(^(NSError *error) {
        if (error) {
            if (error.code == -1004) {
                toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                toastMessage(self, [error localizedDescription]);
            }
        }
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (PMKPromise *)promiseCleanCacheAndCookie {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
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
