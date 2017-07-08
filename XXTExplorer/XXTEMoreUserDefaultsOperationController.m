//
//  XXTEMoreUserDefaultsOperationController.m
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreUserDefaultsOperationController.h"
#import "XXTEMoreLinkNoIconCell.h"

@interface XXTEMoreUserDefaultsOperationController ()

@end

@implementation XXTEMoreUserDefaultsOperationController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    
    self.title = self.userDefaultsEntry[@"title"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreLinkNoIconCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return ((NSArray *)self.userDefaultsEntry[@"options"]).count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return 44.f;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger selectedOperation = (NSUInteger)indexPath.row;
    if (_delegate && [_delegate respondsToSelector:@selector(userDefaultsOperationController:operationSelectedWithIndex:completion:)]) {
        [_delegate userDefaultsOperationController:self operationSelectedWithIndex:selectedOperation completion:^(BOOL succeed) {
            if (succeed) {
                self.selectedOperation = selectedOperation;
                [self.tableView reloadData];
            }
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTEMoreLinkNoIconCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreLinkNoIconCellReuseIdentifier];
    if ((NSUInteger) indexPath.row == self.selectedOperation) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.titleLabel.text = ((NSArray *)self.userDefaultsEntry[@"options"])[(NSUInteger) indexPath.row];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return self.userDefaultsEntry[@"description"];
    }
    return @"";
}

@end
