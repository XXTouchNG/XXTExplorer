//
//  XXTExplorerViewController+XXTESwipeTableCellDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"
#import "XXTESwipeTableCell.h"

static NSString * const XXTExplorerEntryButtonActionLaunch = @"Launch";
static NSString * const XXTExplorerEntryButtonActionProperty = @"Property";
static NSString * const XXTExplorerEntryButtonActionContents = @"Contents";
static NSString * const XXTExplorerEntryButtonActionConfigure = @"Configure";
static NSString * const XXTExplorerEntryButtonActionEdit = @"Edit";
static NSString * const XXTExplorerEntryButtonActionEncrypt = @"Encrypt";
static NSString * const XXTExplorerEntryButtonActionTrash = @"Trash";

@class XXTExplorerEntry;

@interface XXTExplorerViewController (XXTESwipeTableCellDelegate) <XXTESwipeTableCellDelegate>

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)previewActionsForEntry:(XXTExplorerEntry *)entryDetail forEntryCell:(XXTESwipeTableCell *)entryCell;
XXTE_END_IGNORE_PARTIAL

- (BOOL)performButtonAction:(NSString *)buttonAction forEntryCell:(XXTESwipeTableCell *)cell;
- (BOOL)performUnchangedButtonAction:(NSString *)buttonAction forEntry:(XXTExplorerEntry *)entry;

@end
