//
//  XXTExplorerViewController+UIDocumentPickerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+UIDocumentPickerDelegate.h"
#import "XXTENotificationCenterDefines.h"

@implementation XXTExplorerViewController (UIDocumentPickerDelegate)

#pragma mark - UIDocumentPickerDelegate

XXTE_START_IGNORE_PARTIAL
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:url userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInbox}]];
}
XXTE_END_IGNORE_PARTIAL

@end
