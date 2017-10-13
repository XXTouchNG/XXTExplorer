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
    blockInteractions(self, YES);;
    [NSURLConnection POST:uAppDaemonCommandUrl(@"reset_defaults") JSON:@{}]
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
        blockInteractions(self, NO);;
    });
}

@end
