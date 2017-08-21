//
//  XXTEEditorController+State.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+State.h"

#import "XXTENotificationCenterDefines.h"

@implementation XXTEEditorController (State)

- (void)registerStateNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
}

- (void)dismissStateNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XXTENotificationEvent object:nil];
}

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidEnterBackground])
    {
        [self saveDocumentIfNecessary];
    }
}

@end
