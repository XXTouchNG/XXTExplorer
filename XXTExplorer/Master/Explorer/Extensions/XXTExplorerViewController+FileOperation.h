//
//  XXTExplorerViewController+FileOperation.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@class LGAlertView;

@interface XXTExplorerViewController (FileOperation)

#ifndef APPSTORE
    - (void)alertView:(LGAlertView *)alertView encryptItemAtPath:(NSString *)entryPath;
#endif

- (void)alertView:(LGAlertView *)alertView movePasteboardItemsAtPath:(NSString *)path;
- (void)alertView:(LGAlertView *)alertView pastePasteboardItemsAtPath:(NSString *)path;
- (void)alertView:(LGAlertView *)alertView symlinkPasteboardItemsAtPath:(NSString *)path;
- (void)alertView:(LGAlertView *)alertView removeEntryCell:(UITableViewCell *)cell;
- (void)alertView:(LGAlertView *)alertView removeEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths;

@end
