//
//  XXTExplorerViewController+Notification.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+Notification.h"

#import "XXTExplorerDefaults.h"
#import "XXTENotificationCenterDefines.h"

#import "NSString+QueryItems.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

@implementation XXTExplorerViewController (Notification)

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
}

- (void)removeNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UINotification

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    if ([aNotification.name isEqualToString:XXTENotificationEvent]) {
        NSDictionary *userInfo = aNotification.userInfo;
        NSString *eventType = userInfo[XXTENotificationEventType];
        if ([eventType isEqualToString:XXTENotificationEventTypeInboxMoved] ||
            [eventType isEqualToString:XXTENotificationEventTypeFormSheetDismissed]
            ) {
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            NSString *movedPath = aNotification.object;
            if (movedPath) {
                [self.tableView reloadData]; // fix indexPath misplace
                if ([movedPath isKindOfClass:[NSString class]]) {
                    [self selectCellEntryAtPath:movedPath];
                }
            }
        }
        else if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive] ||
                 [eventType isEqualToString:XXTENotificationEventTypeApplicationDidExtractResource] ||
                 [eventType isEqualToString:XXTENotificationEventTypeSelectedScriptPathChanged]) {
            [self refreshEntryListView:nil];
        }
    }
}

#pragma mark - Select Moved Cell

- (void)selectCellEntryAtPath:(NSString *)entryPath {
    NSIndexPath *indexPath = [self indexPathForEntryAtPath:entryPath];
    [self setEditing:YES animated:YES];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self updateToolbarStatus];
}

- (void)selectCellEntriesAtPaths:(NSArray <NSString *> *)entryPaths {
    for (NSString *importedPath in entryPaths) {
        NSIndexPath *importedIndexPath = [self indexPathForEntryAtPath:importedPath];
        if (importedIndexPath) {
            [self.tableView selectRowAtIndexPath:importedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    [self updateToolbarStatus];
}

@end
