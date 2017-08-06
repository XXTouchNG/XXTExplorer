//
//  XXTExplorerViewController+XXTExplorerToolbarDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"
#import "XXTExplorerToolbar.h"

@interface XXTExplorerViewController (XXTExplorerToolbarDelegate) <XXTExplorerToolbarDelegate>

- (void)configureToolbar;

#pragma mark - toolbar

- (void)updateToolbarButton;
- (void)updateToolbarStatus;

@end
