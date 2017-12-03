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
static NSString * const XXTExplorerEntryButtonActionInside = @"Inside";
static NSString * const XXTExplorerEntryButtonActionConfigure = @"Configure";
static NSString * const XXTExplorerEntryButtonActionEdit = @"Edit";
static NSString * const XXTExplorerEntryButtonActionEncrypt = @"Encrypt";
static NSString * const XXTExplorerEntryButtonActionTrash = @"Trash";

@interface XXTExplorerViewController (XXTESwipeTableCellDelegate) <XXTESwipeTableCellDelegate>

- (BOOL)performButtonAction:(NSString *)buttonAction forEntryCell:(XXTESwipeTableCell *)cell;
- (BOOL)performUnchangedButtonAction:(NSString *)buttonAction forEntry:(NSDictionary *)entryDetail;

@end
