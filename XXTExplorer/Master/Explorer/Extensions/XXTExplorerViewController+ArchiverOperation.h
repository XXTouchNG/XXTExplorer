//
//  XXTExplorerViewController+ArchiverOperation.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@class LGAlertView;

@interface XXTExplorerViewController (ArchiverOperation)

- (void)tableView:(UITableView *)tableView archiveEntryCellTappedWithEntryPath:(NSString *)entryPath;
- (void)alertView:(LGAlertView *)alertView archiveEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)alertView:(LGAlertView *)alertView unarchiveEntryPath:(NSString *)entryPath;

@end
