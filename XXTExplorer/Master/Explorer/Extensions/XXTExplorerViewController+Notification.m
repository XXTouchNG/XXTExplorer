//
//  XXTExplorerViewController+Notification.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+Notification.h"

#import "XXTExplorerDefaults.h"

#import "NSString+QueryItems.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerViewController+SharedInstance.h"

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
        if ([eventType isEqualToString:XXTENotificationEventTypeInboxMoved]) {
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, XXTExplorerViewSectionIndexMax)] withRowAnimation:UITableViewRowAnimationAutomatic];
            
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
                        XXTExplorerEntry *entryDetail = [[self.class explorerEntryParser] entryOfPath:movedPath withError:&entryError];
                        
                        if (!entryError) {
                            [self performViewerActionForEntry:entryDetail animated:NO];
                        } else {
                            toastError(self, entryError);
                        }
                        
                        [self scrollToCellEntryAtPath:movedPath animated:NO];
                    } else {
                        [self selectCellEntryAtPath:movedPath animated:YES];
                    }
                    
                }
            }
        }
        else if ([eventType isEqualToString:XXTENotificationEventTypeFormSheetDismissed]) {
            [self reloadEntryListView];
        }
        else if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive] ||
                 [eventType isEqualToString:XXTENotificationEventTypeApplicationDidExtractResource] ||
                 [eventType isEqualToString:XXTENotificationEventTypeSelectedScriptPathChanged])
        {
            [self reloadEntryListView];
            [self updateToolbarStatus];
        }
    }
}

@end
