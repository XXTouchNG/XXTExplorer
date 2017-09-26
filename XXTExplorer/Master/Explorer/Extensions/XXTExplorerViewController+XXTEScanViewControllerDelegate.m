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
    blockInteractionsWithDelay(self, YES, 0);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        blockInteractions(self, NO);
        BOOL internal = ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]);
        if (internal) {
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:url];
            webController.title = NSLocalizedString(@"Loading...", nil);
            if (webController) {
                if (XXTE_COLLAPSED) {
                    XXTE_START_IGNORE_PARTIAL
                    if (@available(iOS 8.0, *)) {
                        XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:webController];
                        [self.splitViewController showDetailViewController:navigationController sender:self];
                    }
                    XXTE_END_IGNORE_PARTIAL
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
    blockInteractions(self, YES);;
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
            blockInteractions(self, NO);;
        });
    }];
}

- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    [self performShortcut:controller jsonOperation:jsonDictionary];
}

@end
