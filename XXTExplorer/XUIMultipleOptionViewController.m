//
//  XUIMultipleOptionViewController.m
//  XXTExplorer
//
//  Created by Zheng on 31/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIMultipleOptionViewController.h"
#import "XUI.h"
#import "XUIStyle.h"
#import "XUIBaseCell.h"

@interface XUIMultipleOptionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedValues;

@end

@implementation XUIMultipleOptionViewController

- (instancetype)initWithCell:(XUILinkMultipleListCell *)cell {
    if (self = [super init]) {
        _cell = cell;
        _selectedValues = cell.xui_value ? [cell.xui_value mutableCopy] : [NSMutableArray array];
    }
    return self;
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
}

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = NO;
        XUI_START_IGNORE_PARTIAL
        if (XUI_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XUI_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cell.xui_validTitles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (0 == section) {
        return self.cell.xui_staticTextMessage;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:XUIBaseCellReuseIdentifier];
        if (nil == cell)
        {
            cell = [[XUIBaseCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:XUIBaseCellReuseIdentifier];
        }
        cell.tintColor = XUI_COLOR;
        cell.textLabel.text = self.cell.xui_validTitles[(NSUInteger) indexPath.row];
        if ([self.selectedValues containsObject:@(indexPath.row)]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        NSNumber *selectedIndex = @(indexPath.row);
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([self.selectedValues containsObject:selectedIndex]) {
            [self.selectedValues removeObject:selectedIndex];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            [self.selectedValues addObject:selectedIndex];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        self.cell.xui_value = self.selectedValues;
        if (_delegate && [_delegate respondsToSelector:@selector(multipleOptionViewController:didSelectOption:)]) {
            [_delegate multipleOptionViewController:self didSelectOption:self.selectedValues];
        }
    }
}

@end
