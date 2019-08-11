//
//  XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 03/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.h"

#import "XXTExplorerViewController+Notification.h"
#import "XXTExplorerViewController+XXTESwipeTableCellDelegate.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerEntryParser.h"

@implementation XXTExplorerViewController (XXTExplorerCreateItemViewControllerDelegate)

- (void)createItemViewControllerDidDismiss:(XXTExplorerCreateItemViewController *)controller {
    UIViewController *blockController = blockInteractionsWithToastAndDelay(self, YES, YES, 2.0);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        if (XXTE_IS_IPAD) {
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        blockInteractions(blockController, NO);
    }];
}

- (void)createItemViewController:(XXTExplorerCreateItemViewController *)controller didFinishCreatingItemAtPath:(NSString *)path {
    UIViewController *blockController = blockInteractionsWithToastAndDelay(self, YES, YES, 2.0);
    @weakify(self);
    [self dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (controller.editImmediately) {
            if (path) {
                NSError *entryError = nil;
                XXTExplorerEntry *entryDetail = [[self.class explorerEntryParser] entryOfPath:path withError:&entryError];
                if (!entryError) {
                    [self performUnchangedButtonAction:@"Edit" forEntry:entryDetail];
                } else {
                    toastError(self, entryError);
                }
                [self.tableView reloadData];
                [self selectCellEntryAtPath:path animated:NO];
            }
        } else {
            if (path) {
                [self.tableView reloadData];
                [self selectCellEntryAtPath:path animated:YES];
            }
        }
        blockInteractions(blockController, NO);
    }];
}

@end
