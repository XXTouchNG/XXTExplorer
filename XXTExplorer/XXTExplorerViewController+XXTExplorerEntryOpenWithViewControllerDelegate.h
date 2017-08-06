//
//  XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"
#import "XXTExplorerEntryOpenWithViewController.h"
#import "XXTEViewer.h"

@interface XXTExplorerViewController (XXTExplorerEntryOpenWithViewControllerDelegate) <XXTExplorerEntryOpenWithViewControllerDelegate>

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController <XXTEViewer> *)viewer;

@end
