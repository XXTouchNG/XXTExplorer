//
//  XXTExplorerViewController+Shortcuts.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+Shortcuts.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTEMoreLicenseController.h"
#import "XXTENavigationController.h"

#import "XXTEScanViewController.h"

#import "XXTExplorerDownloadViewController.h"
#import "XXTENavigationController.h"

#import "XXTENetworkDefines.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

@interface XXTExplorerViewController () <XXTEScanViewControllerDelegate>

@end

@implementation XXTExplorerViewController (Shortcut)

- (void)performShortcut:(id)sender jsonOperation:(NSDictionary *)jsonDictionary {
    NSString *jsonEvent = jsonDictionary[@"event"];
    if (![jsonEvent isKindOfClass:[NSString class]]) {
        return;
    }
    if ([jsonEvent isEqualToString:@"bind_code"] || [jsonEvent isEqualToString:@"license"]) {
        if ([jsonDictionary[@"code"] isKindOfClass:[NSString class]]) {
            NSString *licenseCode = jsonDictionary[@"code"];
            blockInteractionsWithDelay(self, YES, 0);
            @weakify(self);
            void (^ completionBlock)(void) = ^() {
                @strongify(self);
                blockInteractions(self, NO);
                XXTEMoreLicenseController *licenseController = [[XXTEMoreLicenseController alloc] initWithLicenseCode:licenseCode];
                XXTENavigationController *licenseNavigationController = [[XXTENavigationController alloc] initWithRootViewController:licenseController];
                licenseNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                licenseNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                [self.navigationController presentViewController:licenseNavigationController animated:YES completion:nil];
            };
            if (sender && [sender isKindOfClass:[UIViewController class]]) {
                UIViewController *controller = sender;
                [controller dismissViewControllerAnimated:YES completion:completionBlock];
            }
            completionBlock();
            return;
        }
    } else if ([jsonEvent isEqualToString:@"down_script"] || [jsonEvent isEqualToString:@"download"]) {
        if ([jsonDictionary[@"path"] isKindOfClass:[NSString class]] &&
            [jsonDictionary[@"url"] isKindOfClass:[NSString class]]) {
            NSString *rawSourceURLString = jsonDictionary[@"url"];
            NSURL *sourceURL = [NSURL URLWithString:[rawSourceURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            NSString *rawTargetPathString = jsonDictionary[@"path"];
            NSString *targetPath = [rawTargetPathString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
            NSString *targetFullPath = nil;
            if ([targetPath isAbsolutePath]) {
                targetFullPath = targetPath;
            } else {
                targetFullPath = [self.entryPath stringByAppendingPathComponent:targetPath];
            }
            NSString *targetFixedPath = [targetFullPath stringByRemovingPercentEncoding];
            blockInteractionsWithDelay(self, YES, 0);
            @weakify(self);
            void (^ completionBlock)(void) = ^() {
                @strongify(self);
                blockInteractions(self, NO);
                XXTExplorerDownloadViewController *downloadController = [[XXTExplorerDownloadViewController alloc] initWithSourceURL:sourceURL targetPath:targetFixedPath];
                XXTENavigationController *downloadNavigationController = [[XXTENavigationController alloc] initWithRootViewController:downloadController];
                downloadNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                downloadNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                [self.navigationController presentViewController:downloadNavigationController animated:YES completion:nil];
            };
            if (sender && [sender isKindOfClass:[UIViewController class]]) {
                UIViewController *controller = sender;
                [controller dismissViewControllerAnimated:YES completion:completionBlock];
            }
            completionBlock();
            return;
        }
    } else if ([jsonEvent isEqualToString:@"scan"]) {
        XXTEScanViewController *scanViewController = [[XXTEScanViewController alloc] init];
        scanViewController.shouldConfirm = YES;
        scanViewController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else if ([jsonEvent isEqualToString:@"launch"]) {
        [self performAction:sender launchScript:self.class.selectedScriptPath];
    } else if ([jsonEvent isEqualToString:@"stop"]) {
        [self performAction:sender stopSelectedScript:self.class.selectedScriptPath];
    }
}

#pragma mark - Button Actions

- (void)performAction:(id)sender stopSelectedScript:(NSString *)entryPath {
    if (!entryPath) return;
    blockInteractions(self, YES);;
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
        blockInteractions(self, NO);;
    });
}

- (void)performAction:(id)sender launchScript:(NSString *)entryPath {
    if (!entryPath) return;
    BOOL selectAfterLaunch = XXTEDefaultsBool(XXTExplorerViewEntrySelectLaunchedScriptKey, NO);
    blockInteractions(self, YES);;
    [NSURLConnection POST:uAppDaemonCommandUrl(@"is_running") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            return [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{@"filename": entryPath, @"envp": uAppConstEnvp()}];
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            if (selectAfterLaunch) {
                return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{@"filename": entryPath}];
            }
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
        return [PMKPromise promiseWithValue:@{}];
    })
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, entryPath);
            [self loadEntryListData];
            [self.tableView reloadData];
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
        blockInteractions(self, NO);;
    });
}

@end
