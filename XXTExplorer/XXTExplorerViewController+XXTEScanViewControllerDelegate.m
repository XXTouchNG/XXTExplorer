//
//  XXTExplorerViewController+XXTEScanViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTEScanViewControllerDelegate.h"
#import "XXTExplorerViewController+Shortcuts.h"

#import "XXTEUserInterfaceDefines.h"

#import "XXTECommonWebViewController.h"
#import "XXTECommonNavigationController.h"

#import <PromiseKit/PromiseKit.h>

@implementation XXTExplorerViewController (XXTEScanViewControllerDelegate)

#pragma mark - XXTEScanViewControllerDelegate

- (void)scanViewController:(XXTEScanViewController *)controller urlOperation:(NSURL *)url {
    blockUserInteractions(self, YES, 0.2);
    [controller dismissViewControllerAnimated:YES completion:^{
        blockUserInteractions(self, NO, 0.2);
        BOOL internal = ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]);
        if (internal) {
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:url];
            webController.title = NSLocalizedString(@"Loading...", nil);
            if (webController) {
                if (XXTE_COLLAPSED) {
                    XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:webController];
                    [self.splitViewController showDetailViewController:navigationController sender:self];
                } else {
                    [self.navigationController pushViewController:webController animated:YES];
                }
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }];
}

- (void)scanViewController:(XXTEScanViewController *)controller textOperation:(NSString *)detailText {
    blockUserInteractions(self, YES, 0.2);
    [controller dismissViewControllerAnimated:YES completion:^{
        [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[UIPasteboard generalPasteboard] setString:detailText];
                fulfill(nil);
            });
        }].finally(^() {
            showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
            blockUserInteractions(self, NO, 0.2);
        });
    }];
}

- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    [self performShortcut:controller jsonOperation:jsonDictionary];
}

@end
