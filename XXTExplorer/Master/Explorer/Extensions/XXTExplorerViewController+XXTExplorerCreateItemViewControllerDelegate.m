//
//  XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 03/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTExplorerViewController+Notification.h"
#import "XXTExplorerViewController+XXTESwipeTableCellDelegate.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerEntryParser.h"

@implementation XXTExplorerViewController (XXTExplorerCreateItemViewControllerDelegate)

- (void)createItemViewControllerDidDismiss:(XXTExplorerCreateItemViewController *)controller {
    UIViewController *blockController = blockInteractions(self, YES);
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        if (XXTE_PAD) {
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        blockInteractions(blockController, NO);
    }];
}

- (void)createItemViewController:(XXTExplorerCreateItemViewController *)controller didFinishCreatingItemAtPath:(NSString *)path {
    UIViewController *blockController = blockInteractions(self, YES);
    @weakify(self);
    [self dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (controller.editImmediately) {
            NSError *entryError = nil;
            NSDictionary *entryAttributes = [[self.class explorerEntryParser] entryOfPath:path withError:&entryError];
            if (!entryError) {
                [self performUnchangedButtonAction:@"Edit" forEntry:entryAttributes];
            } else {
                toastMessage(self, entryError.localizedDescription);
            }
        } else {
            if (path) {
                [self.tableView reloadData];
                [self selectCellEntryAtPath:path];
            }
        }
        blockInteractions(blockController, NO);
    }];
}

@end
