//
//  XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <sys/stat.h>

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

#import <XUI/XUIViewController.h>
#import <XUI/XUINavigationController.h>


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
#ifndef APPSTORE
            [self performViewerExecutableActionForEntryAtPath:entryPath];
#endif
        }
        else if ([viewer isKindOfClass:[XXTEArchiveViewer class]]) {
            [self tableView:tableView unarchiveEntryCellTappedWithEntryPath:entryPath];
        }
        else
        {
            if (XXTE_COLLAPSED) {
                XXTE_START_IGNORE_PARTIAL
                if (@available(iOS 8.0, *)) {
                    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
                    [self.splitViewController showDetailViewController:navigationController sender:self];
                }
                XXTE_END_IGNORE_PARTIAL
            } else {
                [self.navigationController pushViewController:viewer animated:animated];
            }
        }
        [self linkHistoryEntryAtPath:entryPath];
    }
}

- (void)tableView:(UITableView *)tableView showFormSheetController:(UIViewController *)controller {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)]) {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        {
            XXTENavigationController *navigationController = nil;
            if ([viewer isKindOfClass:[XUIViewController class]]) {
                navigationController = [[XUINavigationController alloc] initWithRootViewController:viewer];
            } else {
                navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
            }
            navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
            navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
        }
    }
}

- (void)linkHistoryEntryAtPath:(NSString *)entryPath {
    if (self.historyMode) return;
    NSString *historyRelativePath = uAppDefine(XXTExplorerViewBuiltHistoryPath);
    NSString *historyPath = [XXTERootPath() stringByAppendingPathComponent:historyRelativePath];
    NSString *pathHash = [entryPath sha1String];
    if (pathHash.length > 8) {
        NSString *pathSubhash = [pathHash substringToIndex:7];
        NSString *entryName = [entryPath lastPathComponent];
        NSString *entryLinkName = [pathSubhash stringByAppendingFormat:@"@%@", entryName];
        NSString *entryLinkPath = [historyPath stringByAppendingPathComponent:entryLinkName];
//        BOOL linkResult = NO;
        NSError *linkError = nil;
        if (entryLinkPath.length > 0 && entryPath.length > 0) {
            NSFileManager *manager = [[self class] explorerFileManager];
//            BOOL cleanResult = NO;
            NSError *cleanError = nil;
            struct stat cleanStat;
            if (0 == lstat(entryLinkPath.fileSystemRepresentation, &cleanStat)) {
//                cleanResult =
                [manager removeItemAtPath:entryLinkPath error:&cleanError];
            }
//            linkResult =
            [manager createSymbolicLinkAtURL:[NSURL fileURLWithPath:entryLinkPath] withDestinationURL:[NSURL fileURLWithPath:entryPath] error:&linkError];
        }
    }
}

@end
