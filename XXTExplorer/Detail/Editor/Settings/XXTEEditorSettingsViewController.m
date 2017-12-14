//
//  XXTEEditorSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSettingsViewController.h"

// Pre-Defines
#import "XXTEAppDefines.h"
#import "XXTEEditorDefaults.h"

// Cells & Subviews
#import "XXTEEditorFontSizeView.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreSwitchCell.h"
#import "XXTEEditorFontSizeCell.h"
#import "XXTEEditorTabWidthCell.h"
#import "XXTEEditorWrapColumnCell.h"
#import "UIControl+BlockTarget.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"

// Children
#import "XXTEEditorThemeSettingsViewController.h"
#import "XXTEEditorFontSettingsViewController.h"

@interface XXTEEditorSettingsViewController () <XXTEEditorFontSizeViewDelegate, XXTEEditorFontSettingsViewControllerDelegate, XXTEEditorThemeSettingsViewControllerDelegate>

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
    staticSectionTitles = @[ NSLocalizedString(@"Font", nil), NSLocalizedString(@"Theme", nil), NSLocalizedString(@"Layout", nil), NSLocalizedString(@"Tabs", nil), NSLocalizedString(@"Word Wrap", nil), NSLocalizedString(@"Keyboard", nil), NSLocalizedString(@"Search", nil) ];
    staticSectionFooters = @[ @"", @"", @"", NSLocalizedString(@"Enable \"Soft Tabs\" to insert spaces instead of a tab character when you press the Tab key.", nil), @"", @"", @"" ];
    
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
    double fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
    
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
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
    cell3.valueLabel.text = XXTEDefaultsObject(XXTEEditorThemeName, NSLocalizedString(@"Mac Classic", nil));
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEMoreSwitchCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Syntax Highlight", nil);
    cell4.optionSwitch.on = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES);
    [cell4.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorHighlightEnabled, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Line Numbers", nil);
    cell5.optionSwitch.on = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, NO);
    [cell5.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorLineNumbersEnabled, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Show Invisible Characters", nil);
    cell6.optionSwitch.on = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO);
    [cell6.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorShowInvisibleCharacters, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *fullScreenCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    fullScreenCell.titleLabel.text = NSLocalizedString(@"Auto Fullscreen", nil);
    fullScreenCell.optionSwitch.on = XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO);
    [fullScreenCell.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorFullScreenWhenEditing, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Auto Indent", nil);
    cell7.optionSwitch.on = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
    [cell7.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorAutoIndent, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Soft Tabs", nil);
    cell8.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSoftTabs, YES);
    [cell8.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSoftTabs, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEEditorTabWidthCell *tabCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEEditorTabWidthCell class]) owner:nil options:nil] lastObject];
    tabCell.titleLabel.text = NSLocalizedString(@"Width", nil);
    XXTEEditorTabWidthValue widthValue = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
    NSUInteger widthIndex = 2;
    switch (widthValue) {
        case XXTEEditorTabWidthValue_2:
            widthIndex = 0;
            break;
        case XXTEEditorTabWidthValue_3:
            widthIndex = 1;
            break;
        case XXTEEditorTabWidthValue_4:
            widthIndex = 2;
            break;
        case XXTEEditorTabWidthValue_8:
            widthIndex = 3;
            break;
        default:
            break;
    }
    tabCell.segmentedControl.selectedSegmentIndex = widthIndex;
    [tabCell.segmentedControl addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        NSUInteger widthValue = XXTEEditorTabWidthValue_4;
        switch (segmentedControl.selectedSegmentIndex) {
            case 0:
                widthValue = XXTEEditorTabWidthValue_2;
                break;
            case 1:
                widthValue = XXTEEditorTabWidthValue_3;
                break;
            case 2:
                widthValue = XXTEEditorTabWidthValue_4;
                break;
            case 3:
                widthValue = XXTEEditorTabWidthValue_8;
                break;
            default:
                break;
        }
        XXTEDefaultsSetBasic(XXTEEditorTabWidth, widthValue);
        [self.editor setNeedsReload];
    }];
    
#ifdef DEBUG
    XXTEMoreSwitchCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Indent Wrapped Lines", nil);
    cell9.optionSwitch.on = XXTEDefaultsBool(XXTEEditorIndentWrappedLines, NO);
    [cell9.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorIndentWrappedLines, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Auto Word Wrap", nil);
    cell10.optionSwitch.on = XXTEDefaultsBool(XXTEEditorAutoWordWrap, YES);
    [cell10.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorAutoWordWrap, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEEditorWrapColumnCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEEditorWrapColumnCell class]) owner:nil options:nil] lastObject];
    cell11.titleLabel.text = NSLocalizedString(@"Word Column", nil);
    XXTEEditorWordColumnValue columnValue = XXTEDefaultsEnum(XXTEEditorWrapColumn, XXTEEditorWordColumnValue_160);
    NSUInteger columnIndex = 2;
    switch (columnValue) {
        case XXTEEditorWordColumnValue_40:
            columnIndex = 0;
            break;
        case XXTEEditorWordColumnValue_80:
            columnIndex = 1;
            break;
        case XXTEEditorWordColumnValue_160:
            columnIndex = 2;
            break;
        case XXTEEditorWordColumnValue_240:
            columnIndex = 3;
            break;
        default:
            break;
    }
    cell11.segmentedControl.selectedSegmentIndex = columnIndex;
    [cell11.segmentedControl addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        NSUInteger columnValue = XXTEEditorWordColumnValue_160;
        switch (segmentedControl.selectedSegmentIndex) {
            case 0:
                columnValue = XXTEEditorWordColumnValue_40;
                break;
            case 1:
                columnValue = XXTEEditorWordColumnValue_80;
                break;
            case 2:
                columnValue = XXTEEditorWordColumnValue_160;
                break;
            case 3:
                columnValue = XXTEEditorWordColumnValue_240;
                break;
            default:
                break;
        }
        XXTEDefaultsSetBasic(XXTEEditorWrapColumn, columnValue);
        [self.editor setNeedsReload];
    }];
#endif
    
    XXTEMoreSwitchCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell12.titleLabel.text = NSLocalizedString(@"Read Only", nil);
    cell12.optionSwitch.on = XXTEDefaultsBool(XXTEEditorReadOnly, NO);
    [cell12.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorReadOnly, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell13.titleLabel.text = NSLocalizedString(@"Accessory Keyboard", nil);
    cell13.optionSwitch.on = XXTEDefaultsBool(XXTEEditorKeyboardRowEnabled, NO);
    [cell13.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorKeyboardRowEnabled, optionSwitch.on);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell14.titleLabel.text = NSLocalizedString(@"Auto Correction", nil);
    cell14.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo) != UITextAutocorrectionTypeNo;
    [cell14.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorAutoCorrection, optionSwitch.on ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell15.titleLabel.text = NSLocalizedString(@"Auto Capitalization", nil);
    cell15.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone) != UITextAutocapitalizationTypeNone;
    [cell15.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorAutoCapitalization, optionSwitch.on ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone);
        [self.editor setNeedsReload];
    }];
    
    XXTEMoreSwitchCell *cell16 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell16.titleLabel.text = NSLocalizedString(@"Spell Checking", nil);
    cell16.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo) != UITextSpellCheckingTypeNo;
    [cell16.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        XXTEDefaultsSetBasic(XXTEEditorSpellChecking, optionSwitch.on ? UITextSpellCheckingTypeYes : UITextSpellCheckingTypeNo);
        [self.editor setNeedsReload];
    }];
    
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
    
    NSArray *layoutSection = nil;
    if (XXTE_PAD) {
        layoutSection = @[ cell5, cell6 ];
    } else {
        layoutSection = @[ fullScreenCell, cell5, cell6 ];
    }
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    @[ cell3, cell4 ],
                    layoutSection,
                    @[ cell7, cell8, tabCell ],
#ifdef DEBUG
                    @[ cell9, cell10, cell11 ],
#endif
                    @[ cell12, cell13, cell14, cell15, cell16 ],
                    @[ cell17, cell18 ]
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
            fontSettingsViewController.selectedFontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
            [self.navigationController pushViewController:fontSettingsViewController animated:YES];
        }
        else if (indexPath.section == 1 && indexPath.row == 0) {
            XXTEEditorThemeSettingsViewController *themeSettingsViewController = [[XXTEEditorThemeSettingsViewController alloc] initWithStyle:UITableViewStylePlain];
            themeSettingsViewController.delegate = self;
            themeSettingsViewController.selectedThemeName = XXTEDefaultsObject(XXTEEditorThemeName, @"Mac Classic");
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
    XXTEDefaultsSetBasic(XXTEEditorFontSize, view.fontSize);
    [self.editor setNeedsReload];
}

#pragma mark - XXTEEditorFontSettingsViewControllerDelegate

- (void)fontSettingsViewControllerSettingsDidChanged:(XXTEEditorFontSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTEEditorFontName, controller.selectedFontName);
    UIFont *font = [UIFont fontWithName:controller.selectedFontName size:17.f];
    if (font) {
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.text = [font familyName];
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.font = font;
    }
    [self.editor setNeedsReload];
}

#pragma mark - XXTEEditorThemeSettingsViewControllerDelegate

- (void)themeSettingsViewControllerSettingsDidChanged:(XXTEEditorThemeSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTEEditorThemeName, controller.selectedThemeName);
    ((XXTEMoreTitleValueCell *)staticCells[1][0]).valueLabel.text = controller.selectedThemeName;
    [self.editor setNeedsReload];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorSettingsViewController dealloc]");
#endif
}

@end
