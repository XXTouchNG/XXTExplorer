//
//  XXTEUIViewController+XUIFileCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XXTExplorerItemPicker.h"

@interface XXTEUIViewController (XUIFileCell) <XXTExplorerItemPickerDelegate>

- (void)tableView:(UITableView *)tableView XUIFileCell:(UITableViewCell *)cell;

@end
