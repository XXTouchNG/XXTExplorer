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

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTEUserInterfaceDefines.h"

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
        if (![eventType isKindOfClass:[NSString class]]) {
            return;
        }
        if ([eventType isEqualToString:XXTENotificationEventTypeInboxMoved] ||
            [eventType isEqualToString:XXTENotificationEventTypeFormSheetDismissed]
            ) {
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            NSString *movedPath = aNotification.object;
            if (movedPath) {
                [self.tableView reloadData];
                // fix indexPath misplace
                
                if ([movedPath isKindOfClass:[NSString class]]) {
                    
                    // instant view/run
                    NSNumber *instantRun = userInfo[XXTENotificationViewImmediately];
                    
                    if ([instantRun isKindOfClass:[NSNumber class]] &&
                        [instantRun boolValue] == YES)
                    {
                        NSError *entryError = nil;
                        NSDictionary *entryAttributes = [[self.class explorerEntryParser] entryOfPath:movedPath withError:&entryError];
                        
                        if (!entryError) {
                            [self performViewerActionForEntry:entryAttributes];
                        } else {
                            toastMessage(self, entryError.localizedDescription);
                        }
                        
                        [self scrollToCellEntryAtPath:movedPath];
                    } else {
                        [self selectCellEntryAtPath:movedPath];
                    }
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

- (void)scrollToCellEntryAtPath:(NSString *)entryPath shouldSelect:(BOOL)select {
    UITableView *tableView = self.tableView;
    NSIndexPath *indexPath = [self indexPathForEntryAtPath:entryPath];
    if (indexPath != nil) {
        if (select) {
            [self setEditing:YES animated:YES];
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        } else {
            [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
    if (select) {
        [self updateToolbarStatus];
    }
}

- (void)scrollToCellEntryAtPath:(NSString *)entryPath {
    [self scrollToCellEntryAtPath:entryPath shouldSelect:NO];
}

- (void)selectCellEntryAtPath:(NSString *)entryPath {
    [self scrollToCellEntryAtPath:entryPath shouldSelect:YES];
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
