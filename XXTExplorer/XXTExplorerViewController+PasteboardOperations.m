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
        [selectedEntryPaths addObject:self.entryList[indexPath.row][XXTExplorerViewEntryAttributePath]];
    }
    [self.class.explorerPasteboard setStrings:[[NSArray alloc] initWithArray:selectedEntryPaths]];
    [alertView dismissAnimated];
    [self setEditing:NO animated:YES];
}

- (void)alertView:(LGAlertView *)alertView clearPasteboardEntriesStored:(NSArray <NSIndexPath *> *)indexPaths {
    [self.class.explorerPasteboard setStrings:@[]];
    [alertView dismissAnimated];
    [self updateToolbarStatus];
}

@end