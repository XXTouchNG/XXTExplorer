//
//  XXTExplorerViewController+Notification.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+Notification.h"
#import "XXTExplorerViewController+Shortcuts.h"

#import "XXTExplorerDefaults.h"
#import "XXTENotificationCenterDefines.h"

@implementation XXTExplorerViewController (Notification)

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationShortcut object:nil];
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
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        }
        else if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive]) {
            [self refreshEntryListView:nil];
        }
    }
    else if ([aNotification.name isEqualToString:XXTENotificationShortcut]) {
        NSDictionary *userInfo = aNotification.userInfo;
        NSString *userDataString = userInfo[XXTENotificationShortcutUserData];
        
        NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray *urlQuery = [userDataString componentsSeparatedByString:@"&"];
        for (NSString *keyValuePair in urlQuery)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *value = [[pairComponents lastObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (key && value) {
                [queryStringDictionary setObject:value forKey:key];
            }
        }
        
        NSDictionary <NSString *, NSString *> *userDataDictionary = [[NSDictionary alloc] initWithDictionary:queryStringDictionary];
        NSMutableDictionary *mutableOperation = [@{ @"event": userInfo[XXTENotificationShortcutInterface] } mutableCopy];
        
        for (NSString *operationKey in userDataDictionary) {
            mutableOperation[operationKey] = userDataDictionary[operationKey];
        }
        
        NSDictionary *operationDictionary = [[NSDictionary alloc] initWithDictionary:mutableOperation];
        [self performShortcut:aNotification.object jsonOperation:operationDictionary];
    }
}

@end
