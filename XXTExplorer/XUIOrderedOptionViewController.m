//
//  XUIOrderedOptionViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIOrderedOptionViewController.h"
#import "XUI.h"
#import "XUIStyle.h"
#import "XUIBaseCell.h"

@interface XUIOrderedOptionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *selectedIndexes;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *unselectedIndexes;

@end

@implementation XUIOrderedOptionViewController

- (instancetype)initWithCell:(XUIOrderedOptionCell *)cell {
    if (self = [super init]) {
        _cell = cell;
        NSArray *validValues = cell.xui_validValues;
        if (validValues && [validValues isKindOfClass:[NSArray class]]) {
            NSMutableArray *unselectedIndexes = [[NSMutableArray alloc] initWithCapacity:validValues.count];
            for (NSUInteger unselectedIndex = 0; unselectedIndex < validValues.count; unselectedIndex++) {
                [unselectedIndexes addObject:@(unselectedIndex)];
            }
            NSArray *rawValues = cell.xui_value;
            if (rawValues && [rawValues isKindOfClass:[NSArray class]]) {
                NSMutableArray <NSNumber *> *selectedIndexes = [[NSMutableArray alloc] initWithCapacity:rawValues.count];
                for (id rawValue in rawValues) {
                    NSUInteger rawIndex = [cell.xui_validValues indexOfObject:rawValue];
                    if (rawIndex != NSNotFound) {
                        NSNumber *rawIndexObject = @(rawIndex);
                        [selectedIndexes addObject:rawIndexObject];
                        [unselectedIndexes removeObject:rawIndexObject];
                    }
                }
                _selectedIndexes = selectedIndexes;
            } else {
                _selectedIndexes = [[NSMutableArray alloc] init];
            }
            _unselectedIndexes = unselectedIndexes;
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
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = YES;
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.selectedIndexes.count;
    } else if (section == 1) {
        return self.unselectedIndexes.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (0 == section) {
        return NSLocalizedString(@"Selected", nil);
    }
    else if (1 == section) {
        return NSLocalizedString(@"Others", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (0 == section) {
        return self.cell.xui_staticTextMessage;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:XUIBaseCellReuseIdentifier];
    if (nil == cell)
    {
        cell = [[XUIBaseCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:XUIBaseCellReuseIdentifier];
    }
    cell.tintColor = XUI_COLOR;
    cell.showsReorderControl = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0)
    {
        NSUInteger selectedIndex = [self.selectedIndexes[(NSUInteger) indexPath.row] unsignedIntegerValue];
        cell.textLabel.text = self.cell.xui_validTitles[selectedIndex];
    }
    else if (indexPath.section == 1)
    {
        NSUInteger unselectedIndex = [self.unselectedIndexes[(NSUInteger) indexPath.row] unsignedIntegerValue];
        cell.textLabel.text = self.cell.xui_validTitles[unselectedIndex];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section == 1 && proposedDestinationIndexPath.section == 0) {
        // Move In
        NSNumber *maxCountObject = self.cell.xui_maxCount;
        if (maxCountObject) {
            NSUInteger maxCount = [maxCountObject unsignedIntegerValue];
            if (self.selectedIndexes.count >= maxCount) {
                return sourceIndexPath;
            }
        }
    } else if (sourceIndexPath.section == 0 && proposedDestinationIndexPath.section == 1) {
        // Move Out
        NSNumber *minCountOnbject = self.cell.xui_minCount;
        if (minCountOnbject) {
            NSUInteger minCount = [minCountOnbject unsignedIntegerValue];
            if (self.selectedIndexes.count <= minCount) {
                return sourceIndexPath;
            }
        }
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.section == 0 && destinationIndexPath.section == 0) {
        [self.selectedIndexes exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    } else if (sourceIndexPath.section == 1 && destinationIndexPath.section == 1) {
        [self.unselectedIndexes exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    } else if (sourceIndexPath.section == 0 && destinationIndexPath.section == 1) {
        [self.unselectedIndexes insertObject:self.selectedIndexes[sourceIndexPath.row] atIndex:destinationIndexPath.row];
        [self.selectedIndexes removeObjectAtIndex:sourceIndexPath.row];
    } else if (sourceIndexPath.section == 1 && destinationIndexPath.section == 0) {
        [self.selectedIndexes insertObject:self.unselectedIndexes[sourceIndexPath.row] atIndex:destinationIndexPath.row];
        [self.unselectedIndexes removeObjectAtIndex:sourceIndexPath.row];
    }
    NSMutableArray *selectedValues = [[NSMutableArray alloc] initWithCapacity:self.selectedIndexes.count];
    for (NSNumber *selectedIndex in self.selectedIndexes) {
        NSUInteger selectedIndexValue = [selectedIndex unsignedIntegerValue];
        id selectedValue = self.cell.xui_validValues[selectedIndexValue];
        [selectedValues addObject:selectedValue];
    }
    self.cell.xui_value = [[NSArray alloc] initWithArray:selectedValues];
    if (_delegate && [_delegate respondsToSelector:@selector(orderedOptionViewController:didSelectOption:)]) {
        [_delegate orderedOptionViewController:self didSelectOption:self.selectedIndexes];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIOrderedOptionViewController dealloc]");
#endif
}

@end