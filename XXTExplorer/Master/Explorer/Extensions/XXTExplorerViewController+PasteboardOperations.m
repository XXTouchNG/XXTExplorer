//
//  XXTExplorerViewController+PasteboardOperations.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+PasteboardOperations.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

#import <LGAlertView/LGAlertView.h>

#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"

@implementation XXTExplorerViewController (PasteboardOperations)

+ (UIPasteboard *)explorerPasteboard {
    static UIPasteboard *explorerPasteboard = nil;
    if (!explorerPasteboard) {
        explorerPasteboard = ({
            [UIPasteboard pasteboardWithName:XXTExplorerPasteboardName create:YES];
        });
    }
    return explorerPasteboard;
}

#pragma mark - AlertView Actions

- (void)alertView:(LGAlertView *)alertView copyPasteboardItemsAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSMutableArray <NSString *> *selectedEntryPaths = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        [selectedEntryPaths addObject:self.entryList[indexPath.row].entryPath];
    }
    [self setEditing:NO animated:YES];
    UIViewController *blockController = blockInteractions(self, YES);
    [alertView dismissAnimated:YES completionHandler:^{
        [self.class.explorerPasteboard setStrings:[[NSArray alloc] initWithArray:selectedEntryPaths]];
        [self updateToolbarStatus];
        blockInteractions(blockController, NO);
    }];
}

- (void)alertView:(LGAlertView *)alertView clearPasteboardEntriesStored:(NSArray <NSIndexPath *> *)indexPaths {
    UIViewController *blockController = blockInteractions(self, YES);
    [alertView dismissAnimated:YES completionHandler:^{
        [self.class.explorerPasteboard setStrings:@[]];
        [self updateToolbarStatus];
        blockInteractions(blockController, NO);
    }];
}

@end
