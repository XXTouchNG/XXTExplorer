//
//  XXTExplorerViewController+PasteboardOperations.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@class LGAlertView;

@interface XXTExplorerViewController (PasteboardOperations)

+ (UIPasteboard *)explorerPasteboard;
- (void)alertView:(LGAlertView *)alertView copyPasteboardItemsAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;
- (void)alertView:(LGAlertView *)alertView clearPasteboardEntriesStored:(NSArray <NSIndexPath *> *)indexPaths;

@end
