//
//  XXTEUIViewController+XUITitleValueCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XUITitleValueCell.h"

#import "XXTPickerSnippet.h"
#import "XXTPickerFactory.h"

@interface XXTEUIViewController (XUITitleValueCell) <XXTPickerFactoryDelegate>

- (void)tableView:(UITableView *)tableView XUITitleValueCell:(UITableViewCell *)cell;
- (void)tableView:(UITableView *)tableView accessoryXUITitleValueCell:(XUITitleValueCell *)cell;

@end
