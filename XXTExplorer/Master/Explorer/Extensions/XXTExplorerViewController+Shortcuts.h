//
//  XXTExplorerViewController+Shortcuts.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@interface XXTExplorerViewController (Shortcuts)

- (void)performShortcut:(id)sender jsonOperation:(NSDictionary *)jsonDictionary;
- (void)performAction:(id)sender stopSelectedScript:(NSString *)entryPath;
- (void)performAction:(id)sender launchScript:(NSString *)entryPath;

@end
