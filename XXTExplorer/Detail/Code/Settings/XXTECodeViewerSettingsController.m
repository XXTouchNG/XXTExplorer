//
//  XXTECodeViewerSettingsController.m
//  XXTExplorer
//
//  Created by Darwin on 7/29/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTECodeViewerSettingsController.h"

// Pre-Defines
#import "XXTECodeViewerDefaults.h"

// Cells
#import "XXTEMoreValueView.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreValueViewCell.h"
#import "XXTEMoreSwitchCell.h"

// Helpers
#import "UIControl+BlockTarget.h"

// Children
#import "XXTEEditorFontSettingsViewController.h"
#import "XXTEEditorThemeSettingsViewController.h"


@interface XXTECodeViewerSettingsController () <XXTEEditorFontSettingsViewControllerDelegate, XXTEEditorThemeSettingsViewControllerDelegate, XXTEMoreValueViewDelegate>

@end

@implementation XXTECodeViewerSettingsController {
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
    self.automaticallyAdjustsScrollViewInsets = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.title = NSLocalizedString(@"Settings", nil);
    
    self.tableView.delaysContentTouches = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
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

- (void)viewWillAppear:(BOOL)animated {
    if ([_delegate respondsToSelector:@selector(codeViewerNeedsRestoreNavigationBar:)]) {
        [self.delegate codeViewerNeedsRestoreNavigationBar:YES];
    }
    [super viewWillAppear:animated]; // good for UITableViewController to handle keyboard events
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if ([_delegate respondsToSelector:@selector(codeViewerNeedsRestoreNavigationBar:)]) {
        if (parent == nil) {
            [self.delegate codeViewerNeedsRestoreNavigationBar:NO];
        } else {
            [self.delegate codeViewerNeedsRestoreNavigationBar:YES];
        }
    }
    [super willMoveToParentViewController:parent];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Font", nil), NSLocalizedString(@"Theme", nil), NSLocalizedString(@"Layout", nil), ];
    staticSectionFooters = @[ @"", @"", @"" ];
    
    NSString *fontName = XXTEDefaultsObject(XXTECodeViewerFontName, @"Courier");
    double fontSize = XXTEDefaultsDouble(XXTECodeViewerFontSize, 14.0);
    
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Font Family", nil);
    cell1.valueLabel.text = font.familyName;
    cell1.valueLabel.font = [font fontWithSize:17.f];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEMoreValueViewCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreValueViewCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Font Size", nil);
    cell2.valueView.maxValue = 32.0;
    cell2.valueView.minValue = 8.0;
    cell2.valueView.unitString = @"pt";
    cell2.valueView.isInteger = YES;
    cell2.valueView.value = (NSUInteger)font.pointSize;
    cell2.valueView.delegate = self;
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Theme", nil);
    cell3.valueLabel.text = XXTEDefaultsObject(XXTECodeViewerThemeName, NSLocalizedString(@"Xcode", nil));
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEMoreSwitchCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Syntax Highlight", nil);
    cell4.optionSwitch.on = XXTEDefaultsBool(XXTECodeViewerHighlightEnabled, YES);
    {
        @weakify(self);
        [cell4.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTECodeViewerHighlightEnabled, optionSwitch.on);
            if ([self.delegate respondsToSelector:@selector(codeViewerSettingsControllerDidChange:)]) {
                [self.delegate codeViewerSettingsControllerDidChange:self];
            }
        }];
    }
    
    XXTEMoreSwitchCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Line Numbers", nil);
    cell5.optionSwitch.on = XXTEDefaultsBool(XXTECodeViewerLineNumbersEnabled, (XXTE_IS_IPAD ? YES : NO));
    {
        @weakify(self);
        [cell5.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTECodeViewerLineNumbersEnabled, optionSwitch.on);
            if ([self.delegate respondsToSelector:@selector(codeViewerSettingsControllerDidChange:)]) {
                [self.delegate codeViewerSettingsControllerDidChange:self];
            }
        }];
    }
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    @[ cell3, cell4 ],
                    @[ cell5 ],
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
        if (indexPath.section == 0 && indexPath.row == 1) {
            return 88.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            XXTEEditorFontSettingsViewController *fontSettingsViewController = [[XXTEEditorFontSettingsViewController alloc] initWithStyle:UITableViewStylePlain];
            fontSettingsViewController.delegate = self;
            fontSettingsViewController.selectedFontName = XXTEDefaultsObject(XXTECodeViewerFontName, @"Courier");
            [self.navigationController pushViewController:fontSettingsViewController animated:YES];
        }
        else if (indexPath.section == 1 && indexPath.row == 0) {
            NSString *definesPath = [[NSBundle mainBundle] pathForResource:@"HLTheme" ofType:@"plist"];
            XXTEEditorThemeSettingsViewController *themeSettingsViewController = [[XXTEEditorThemeSettingsViewController alloc] initWithStyle:UITableViewStylePlain definesPath:definesPath];
            themeSettingsViewController.delegate = self;
            themeSettingsViewController.selectedThemeName = XXTEDefaultsObject(XXTECodeViewerThemeName, @"Xcode");
            [self.navigationController pushViewController:themeSettingsViewController animated:YES];
        }
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

#pragma mark - XXTEMoreValueViewDelegate

- (void)valueViewValueDidChanged:(XXTEMoreValueView *)view {
    XXTEDefaultsSetBasic(XXTECodeViewerFontSize, view.value);
    if ([_delegate respondsToSelector:@selector(codeViewerSettingsControllerDidChange:)]) {
        [_delegate codeViewerSettingsControllerDidChange:self];
    }
}

#pragma mark - XXTEEditorFontSettingsViewControllerDelegate

- (void)fontSettingsViewControllerSettingsDidChanged:(XXTEEditorFontSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTECodeViewerFontName, [controller.selectedFontName copy]);
    UIFont *font = [UIFont fontWithName:controller.selectedFontName size:17.f];
    if (font) {
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.text = [font familyName];
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.font = font;
    }
    if ([_delegate respondsToSelector:@selector(codeViewerSettingsControllerDidChange:)]) {
        [_delegate codeViewerSettingsControllerDidChange:self];
    }
}

#pragma mark - XXTEEditorThemeSettingsViewControllerDelegate

- (void)themeSettingsViewControllerSettingsDidChanged:(XXTEEditorThemeSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTECodeViewerThemeName, [controller.selectedThemeName copy]);
    XXTEDefaultsSetObject(XXTECodeViewerThemeLocation, [controller.selectedThemeEntry objectForKey:@"location"]);
    ((XXTEMoreTitleValueCell *)staticCells[1][0]).valueLabel.text = controller.selectedThemeName;
    if ([_delegate respondsToSelector:@selector(codeViewerSettingsControllerDidChange:)]) {
        [_delegate codeViewerSettingsControllerDidChange:self];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
