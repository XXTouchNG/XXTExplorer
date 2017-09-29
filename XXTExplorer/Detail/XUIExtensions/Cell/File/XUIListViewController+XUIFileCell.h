//
//  XUIListViewController+XUIFileCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController.h"
#import "XXTExplorerItemPicker.h"

@interface XUIListViewController (XUIFileCell) <XXTExplorerItemPickerDelegate>

- (void)tableView:(UITableView *)tableView XUIFileCell:(UITableViewCell *)cell;

@end
