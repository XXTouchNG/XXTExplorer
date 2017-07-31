//
//  XUIOptionViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIOptionViewController.h"
#import "XUI.h"
#import "XUIStyle.h"
#import "XUIBaseCell.h"

@interface XUIOptionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation XUIOptionViewController {
    
}

- (instancetype)initWithCell:(XUILinkListCell *)cell {
    if (self = [super init]) {
        _cell = cell;
        id rawValue = cell.xui_value;
        if (rawValue) {
            NSUInteger rawIndex = [self.cell.xui_validValues indexOfObject:rawValue];
            if ((rawIndex) != NSNotFound) {
                _selectedIndex = rawIndex;
            }
        }
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
        if (self.selectedIndex == indexPath.row) {
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
        self.selectedIndex = indexPath.row;
        for (UITableViewCell *cell in tableView.visibleCells) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
        selectCell.accessoryType = UITableViewCellAccessoryCheckmark;
        id selectedValue = self.cell.xui_validValues[self.selectedIndex];
        if (selectedValue) {
            self.cell.xui_value = selectedValue;
        }
        if (_delegate && [_delegate respondsToSelector:@selector(optionViewController:didSelectOption:)]) {
            [_delegate optionViewController:self didSelectOption:self.selectedIndex];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIOptionViewController dealloc]");
#endif
}

@end
