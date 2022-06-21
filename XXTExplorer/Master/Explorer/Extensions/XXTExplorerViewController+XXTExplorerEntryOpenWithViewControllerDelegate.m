//
//  XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import <SafariServices/SafariServices.h>

#import "XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h"
#import "XXTExplorerViewController+ArchiverOperation.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryService.h"

#import "XXTEArchiveViewer.h"
#import "XXTEExecutableViewer.h"

#import "XXTENavigationController.h"
#import "XXTExplorerViewCell.h"
#import "NSString+SHA1.h"


@implementation XXTExplorerViewController (XXTExplorerEntryOpenWithViewControllerDelegate)

#pragma mark - XXTExplorerEntryOpenWithViewControllerDelegate

- (void)openWithViewController:(XXTExplorerEntryOpenWithViewController *)controller viewerDidSelected:(NSString *)controllerName {
    [controller dismissViewControllerAnimated:YES completion:^{
        XXTExplorerEntry *entry = controller.entry;
        NSString *entryPath = entry.entryPath;
        UIViewController *detailController = [[self.class explorerEntryService] viewerWithName:controllerName forEntryPath:entryPath];
        [self tableView:self.tableView showDetailController:detailController];
    }];
}

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController *)controller {
    [self tableView:tableView showDetailController:controller animated:YES];
}

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController *)controller animated:(BOOL)animated {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)])
    {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        NSString *entryPath = viewer.entryPath;
        if ([viewer isKindOfClass:[XXTEExecutableViewer class]])
        {
            [self performViewerExecutableActionForEntryAtPath:entryPath];
        }
        else if ([viewer isKindOfClass:[XXTEArchiveViewer class]]) {
            [self tableView:tableView unarchiveEntryCellTappedWithEntryPath:entryPath];
        }
        else
        {
            if (XXTE_COLLAPSED) {
                XXTE_START_IGNORE_PARTIAL
                XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
                [self.splitViewController showDetailViewController:navigationController sender:self];
                XXTE_END_IGNORE_PARTIAL
            } else if ([viewer isKindOfClass:[SFSafariViewController class]]) {
                [self.navigationController presentViewController:viewer animated:YES completion:nil];
            } else {
                [self.navigationController pushViewController:viewer animated:animated];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView showFormSheetController:(UIViewController *)controller {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)]) {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        {
            UIViewController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
            navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
            navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            navigationController.presentationController.delegate = self;
            [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
        }
    }
}

@end
