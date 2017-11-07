//
//  XXTExplorerViewController+LGAlertViewDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+LGAlertViewDelegate.h"
#import "XXTExplorerViewController+PasteboardOperations.h"
#import "XXTExplorerViewController+FileOperation.h"

#import "XXTExplorerDefaults.h"

#import <objc/message.h>

@implementation XXTExplorerViewController (LGAlertViewDelegate)

#pragma mark - LGAlertViewDelegate

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    NSString *action = objc_getAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String]);
    id obj = objc_getAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String]);
    if (action) {
        if ([action isEqualToString:XXTExplorerAlertViewActionPasteboardImport]) {
            if (index == 0)
                [self alertView:alertView copyPasteboardItemsAtIndexPaths:obj];
        } else if ([action isEqualToString:XXTExplorerAlertViewActionPasteboardExport]) {
            if (index == 0)
                [self alertView:alertView pastePasteboardItemsAtPath:obj];
            else if (index == 1)
                [self alertView:alertView movePasteboardItemsAtPath:obj];
            else if (index == 2)
                [self alertView:alertView symlinkPasteboardItemsAtPath:obj];
        }
    }
}

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(alertView:removeEntryCell:),
        @selector(alertView:removeEntriesAtIndexPaths:),
        @selector(alertView:archiveEntriesAtIndexPaths:),
        @selector(alertView:unarchiveEntryPath:),
        @selector(alertView:clearPasteboardEntriesStored:),
#ifndef APPSTORE
        @selector(alertView:encryptItemAtPath:),
#endif
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        if (obj) {
            [self performSelector:selector withObject:alertView withObject:obj];
            break;
        }
    }
#pragma clang diagnostic pop
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    if (self.busyOperationProgressFlag) {
        self.busyOperationProgressFlag = NO;
    } else {
        [alertView dismissAnimated];
    }
}

@end
