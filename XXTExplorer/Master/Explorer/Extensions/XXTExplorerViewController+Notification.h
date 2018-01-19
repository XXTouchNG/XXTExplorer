//
//  XXTExplorerViewController+Notification.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@interface XXTExplorerViewController (Notification)

- (void)registerNotifications;
- (void)removeNotifications;

- (void)scrollToCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated;
- (void)selectCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated;
- (void)selectCellEntriesAtPaths:(NSArray <NSString *> *)entryPaths animated:(BOOL)animated;

@end
