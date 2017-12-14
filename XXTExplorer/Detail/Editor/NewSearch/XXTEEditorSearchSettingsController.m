//
//  XXTEEditorSearchSettingsController.m
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchSettingsController.h"

// Pre-Defines
#import "XXTEAppDefines.h"
#import "XXTEEditorDefaults.h"

// Cells & Subviews
#import "XXTEMoreSwitchCell.h"
#import "UIControl+BlockTarget.h"

@interface XXTEEditorSearchSettingsController ()

@end

@implementation XXTEEditorSearchSettingsController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
}

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.title = NSLocalizedString(@"Settings", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"" ];
    staticSectionFooters = @[ @"" ];
    
    XXTEMoreSwitchCell *cell17 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell17.titleLabel.text = NSLocalizedString(@"Regular Expression", nil);
    cell17.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    [cell17.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSearchRegularExpression, optionSwitch.on);
    }];
    
    XXTEMoreSwitchCell *cell18 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell18.titleLabel.text = NSLocalizedString(@"Case Sensitive", nil);
    cell18.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    [cell18.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSearchCaseSensitive, optionSwitch.on);
    }];
    
    staticCells = @[
                    @[ cell17, cell18 ],
                    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return staticCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [staticCells[section] count];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionTitles[(NSUInteger) section];
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionFooters[(NSUInteger) section];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorSearchSettingsController dealloc]");
#endif
}

@end
