//
//  XXTExplorerSearchResultsViewController.m
//  XXTouch
//
//  Created by Darwin on 8/21/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTExplorerSearchResultsViewController.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerEntry.h"
#import "XXTExplorerViewController+SharedInstance.h"


@interface XXTExplorerSearchResultsViewController ()

@end

@implementation XXTExplorerSearchResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tableView = self.tableView;
    tableView.dataSource = self;
    tableView.backgroundColor = XXTColorPlainBackground();
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredEntryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        XXTExplorerEntry *entryDetail = self.filteredEntryList[indexPath.row];
        XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
        if (!entryCell) {
            entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
        }
        [self.explorer configureCell:entryCell withEntry:entryDetail];
        return entryCell;
    }
    return [UITableViewCell new];
}

@end
