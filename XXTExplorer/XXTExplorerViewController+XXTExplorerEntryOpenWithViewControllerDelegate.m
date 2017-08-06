//
//  XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h"
#import "XXTExplorerViewController+ArchiverOperations.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"

#import "XXTEArchiveViewer.h"
#import "XXTEExecutableViewer.h"

#import "XXTECommonNavigationController.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import "XXTExplorerEntryService.h"

@implementation XXTExplorerViewController (XXTExplorerEntryOpenWithViewControllerDelegate)

#pragma mark - XXTExplorerEntryOpenWithViewControllerDelegate

- (void)openWithViewController:(XXTExplorerEntryOpenWithViewController *)controller viewerDidSelected:(NSString *)controllerName {
    [controller dismissViewControllerAnimated:YES completion:^{
        NSDictionary *entry = controller.entry;
        NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
        UIViewController *detailController = [[self.class explorerEntryService] viewerWithName:controllerName forEntryPath:entryPath];
        [self tableView:self.tableView showDetailController:(UIViewController <XXTEViewer> *)detailController];
    }];
}

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController <XXTEViewer> *)viewer {
    if (viewer) {
        if ([viewer isKindOfClass:[XXTEExecutableViewer class]]) {
            blockUserInteractions(self, YES);
            [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{@"filename": viewer.entryPath}]
            .then(convertJsonString)
            .then(^(NSDictionary *jsonDictionary) {
                if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                    XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, viewer.entryPath);
                } else {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDictionary[@"message"]];
                }
            })
            .catch(^(NSError *serverError) {
                if (serverError.code == -1004) {
                    showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
                } else {
                    showUserMessage(self, [serverError localizedDescription]);
                }
            })
            .finally(^() {
                blockUserInteractions(self, NO);
                [self loadEntryListData];
                [self.tableView reloadData];
            });
        } else if ([viewer isKindOfClass:[XXTEArchiveViewer class]]) {
            [self tableView:tableView archiveEntryCellTappedWithEntryPath:viewer.entryPath];
        } else {
            if (XXTE_COLLAPSED) {
                XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:viewer];
                [self.splitViewController showDetailViewController:navigationController sender:self];
            } else {
                [self.navigationController pushViewController:viewer animated:YES];
            }
        }
    }
}

@end
