//
//  XXTEEditorSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSettingsViewController.h"
#import "XXTEEditorController.h"
#import "XXTEEditorTheme.h"

#import "XXTEEditorFontSizeView.h"

#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreSwitchNoIconCell.h"
#import "XXTEEditorFontSizeCell.h"

#import "XXTEEditorDefaults.h"
#import "XXTEAppDefines.h"

#import "XXTEEditorThemeSettingsViewController.h"
#import "XXTEEditorFontSettingsViewController.h"

#import "UIControl+BlockTarget.h"

@interface XXTEEditorSettingsViewController () <XXTEEditorFontSizeViewDelegate, XXTEEditorFontSettingsViewControllerDelegate>

@end

@implementation XXTEEditorSettingsViewController {
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

- (instancetype) initWithStyle:(UITableViewStyle)style {
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
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.title = NSLocalizedString(@"Settings", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self reloadStaticTableViewData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Font", nil), NSLocalizedString(@"Theme", nil), NSLocalizedString(@"Layout", nil), NSLocalizedString(@"Tabs", nil), NSLocalizedString(@"Keyboard", nil), NSLocalizedString(@"Search", nil) ];
    staticSectionFooters = @[ @"", @"", @"", NSLocalizedString(@"Enable \"Soft Tabs\" to insert spaces instead of a tab character when you press the Tab key.", nil), @"", @"" ];
    
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
    UIFont *font = [UIFont fontWithName:fontName size:14.0];
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Font Family", nil);
    cell1.valueLabel.text = font.familyName;
    cell1.valueLabel.font = [font fontWithSize:17.f];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEEditorFontSizeCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEEditorFontSizeCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Font Size", nil);
    cell2.sizeView.fontSize = (NSUInteger)font.pointSize;
    cell2.sizeView.delegate = self;
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Theme", nil);
    cell3.valueLabel.text = XXTEDefaultsObject(XXTEEditorThemeName, @"Mac Classic");
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEMoreSwitchNoIconCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Syntax Highlight", nil);
    cell4.optionSwitch.on = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES);
    [cell4.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorHighlightEnabled, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Line Numbers", nil);
    cell5.optionSwitch.on = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, NO);
    [cell5.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorLineNumbersEnabled, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Show Invisible Characters", nil);
    cell6.optionSwitch.on = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO);
    [cell6.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorShowInvisibleCharacters, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Auto Indent", nil);
    cell7.optionSwitch.on = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
    [cell7.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorAutoIndent, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Soft Tabs", nil);
    cell8.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSoftTabs, YES);
    [cell8.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSoftTabs, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Read Only", nil);
    cell9.optionSwitch.on = XXTEDefaultsBool(XXTEEditorReadOnly, NO);
    [cell9.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorReadOnly, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Auto Correction", nil);
    cell10.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo) != UITextAutocorrectionTypeNo;
    
    XXTEMoreSwitchNoIconCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell11.titleLabel.text = NSLocalizedString(@"Auto Capitalization", nil);
    cell11.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone) != UITextAutocapitalizationTypeNone;
    
    XXTEMoreSwitchNoIconCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell12.titleLabel.text = NSLocalizedString(@"Spell Checking", nil);
    cell12.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo) != UITextSpellCheckingTypeNo;
    
    XXTEMoreSwitchNoIconCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell13.titleLabel.text = NSLocalizedString(@"Regular Expression", nil);
    cell13.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    [cell13.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSearchRegularExpression, optionSwitch.on);
    }];
    
    XXTEMoreSwitchNoIconCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchNoIconCell class]) owner:nil options:nil] lastObject];
    cell14.titleLabel.text = NSLocalizedString(@"Case Sensitive", nil);
    cell14.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    [cell14.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSearchCaseSensitive, optionSwitch.on);
    }];
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    @[ cell3, cell4 ],
                    @[ cell5, cell6 ],
                    @[ cell7, cell8 ],
                    @[ cell9, cell10, cell11, cell12 ],
                    @[ cell13, cell14 ],
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
            XXTEEditorFontSettingsViewController *fontSettingsViewController = [[XXTEEditorFontSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            fontSettingsViewController.delegate = self;
            fontSettingsViewController.selectedFontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
            [self.navigationController pushViewController:fontSettingsViewController animated:YES];
        }
        else if (indexPath.section == 1 && indexPath.row == 0) {
            XXTEEditorThemeSettingsViewController *themeSettingsViewController = [[XXTEEditorThemeSettingsViewController alloc] initWithStyle:UITableViewStylePlain];
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

#pragma mark - XXTEEditorFontSizeViewDelegate

- (void)fontViewSizeDidChanged:(XXTEEditorFontSizeView *)view {
    
}

#pragma mark - XXTEEditorFontSettingsViewControllerDelegate

- (void)fontSettingsViewControllerSettingsDidChanged:(XXTEEditorFontSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTEEditorFontName, controller.selectedFontName);
    UIFont *font = [UIFont fontWithName:controller.selectedFontName size:17.f];
    if (font) {
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.text = [font familyName];
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.font = font;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEEditorSettingsViewController dealloc]");
#endif
}

@end
