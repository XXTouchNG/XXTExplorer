//
//  XXTEEditorSettingsViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSettingsViewController.h"

// Pre-Defines
#import "XXTEEditorDefaults.h"

// Cells & Subviews
#import "XXTEMoreValueView.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreValueViewCell.h"
#import "XXTEEditorTabWidthCell.h"
#import "XXTEMoreTextFieldCell.h"
#import "UIControl+BlockTarget.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"

// Children
#import "XXTEEditorThemeSettingsViewController.h"
#import "XXTEEditorFontSettingsViewController.h"

@interface XXTEEditorSettingsViewController () <XXTEMoreValueViewDelegate, XXTEEditorFontSettingsViewControllerDelegate, XXTEEditorThemeSettingsViewControllerDelegate, UITextFieldDelegate>

@end

@implementation XXTEEditorSettingsViewController {
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
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated]; // good for UITableViewController to handle keyboard events
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
    BOOL editorHasLongLine = self.editor.hasLongLine;
    
    staticSectionTitles = @[ NSLocalizedString(@"Font", nil), NSLocalizedString(@"Theme", nil), NSLocalizedString(@"Layout", nil), NSLocalizedString(@"Tabs", nil), NSLocalizedString(@"Word Wrap", nil), NSLocalizedString(@"Keyboard", nil), NSLocalizedString(@"Text", nil), NSLocalizedString(@"Search", nil) ];
    staticSectionFooters = @[ @"", editorHasLongLine ? NSLocalizedString(@"❗️\"Syntax Highlight\" is skipped for files with long lines for performance reasons.", nil) : @"", @"", NSLocalizedString(@"Enable \"Soft Tabs\" to insert spaces instead of a tab character when you press the Tab key.", nil), NSLocalizedString(@"\"Word Column\" is used only when \"Auto Word Wrap\" is disabled.", nil), @"", @"", @"" ];
    
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"Courier");
    double fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
    
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
    cell3.valueLabel.text = XXTEDefaultsObject(XXTEEditorThemeName, NSLocalizedString(@"Mac Classic", nil));
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    XXTEMoreSwitchCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Syntax Highlight", nil);
    if (editorHasLongLine) {
        cell4.optionSwitch.on = NO;
        cell4.optionSwitch.enabled = NO;
    } else {
        cell4.optionSwitch.on = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES);
        cell4.optionSwitch.enabled = YES;
    }
    {
        @weakify(self);
        [cell4.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorHighlightEnabled, optionSwitch.on);
            [self.editor setNeedsReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Line Numbers", nil);
    cell5.optionSwitch.on = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, (XXTE_IS_IPAD ? YES : NO));
    {
        @weakify(self);
        [cell5.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorLineNumbersEnabled, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Show Invisible Characters", nil);
    cell6.optionSwitch.on = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO);
    {
        @weakify(self);
        [cell6.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorShowInvisibleCharacters, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *fullScreenCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    fullScreenCell.titleLabel.text = NSLocalizedString(@"Auto Fullscreen", nil);
    fullScreenCell.optionSwitch.on = XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO);
    {
        [fullScreenCell.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorFullScreenWhenEditing, optionSwitch.on);
        }];
    }
    
    XXTEMoreSwitchCell *simpleTitleViewCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    simpleTitleViewCell.titleLabel.text = NSLocalizedString(@"Simple Title", nil);
    simpleTitleViewCell.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSimpleTitleView, (XXTE_IS_IPAD ? NO : YES));
    {
        @weakify(self);
        [simpleTitleViewCell.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorSimpleTitleView, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Auto Indent", nil);
    cell7.optionSwitch.on = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
    {
        @weakify(self);
        [cell7.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorAutoIndent, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Soft Tabs", nil);
    cell8.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSoftTabs, YES);
    {
        @weakify(self);
        [cell8.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorSoftTabs, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
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
    {
        @weakify(self);
        [tabCell.segmentedControl addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
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
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Indent Wrapped Lines", nil);
    cell9.optionSwitch.on = XXTEDefaultsBool(XXTEEditorIndentWrappedLines, YES);
    {
        @weakify(self);
        [cell9.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorIndentWrappedLines, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Auto Word Wrap", nil);
    cell10.optionSwitch.on = XXTEDefaultsBool(XXTEEditorAutoWordWrap, YES);
    {
        @weakify(self);
        [cell10.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorAutoWordWrap, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreTextFieldCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTextFieldCell class]) owner:nil options:nil] lastObject];
    cell11.titleLabel.text = NSLocalizedString(@"Word Column", nil);
    NSInteger columnValue = XXTEDefaultsInt(XXTEEditorWrapColumn, 160);
    cell11.valueField.text = [NSString stringWithFormat:@"%ld", (long)columnValue];
    cell11.valueField.delegate = self;
    {
        @weakify(self);
        [cell11.valueField addActionforControlEvents:UIControlEventEditingDidEnd respond:^(UIControl *sender) {
            @strongify(self);
            UITextField *valueField = (UITextField *)sender;
            int columnValue = [valueField.text intValue];
            if (columnValue < 10 || columnValue > 10000)
            {
                columnValue = 160; // restore to default value
            }
            XXTEDefaultsSetBasic(XXTEEditorWrapColumn, columnValue);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell12.titleLabel.text = NSLocalizedString(@"Read Only", nil);
    cell12.optionSwitch.on = XXTEDefaultsBool(XXTEEditorReadOnly, NO);
    {
        @weakify(self);
        [cell12.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorReadOnly, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell13.titleLabel.text = NSLocalizedString(@"Accessory Keyboard", nil);
    cell13.optionSwitch.on = XXTEDefaultsBool(XXTEEditorKeyboardRowAccessoryEnabled, NO);
    {
        @weakify(self);
        [cell13.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorKeyboardRowAccessoryEnabled, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cellBrackets = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cellBrackets.titleLabel.text = NSLocalizedString(@"Auto Insert Brackets", nil);
    cellBrackets.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoBrackets, NO);
    {
        @weakify(self);
        [cellBrackets.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorAutoBrackets, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell14.titleLabel.text = NSLocalizedString(@"Auto Correction", nil);
    cell14.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo) != UITextAutocorrectionTypeNo;
    {
        @weakify(self);
        [cell14.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorAutoCorrection, optionSwitch.on ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell15.titleLabel.text = NSLocalizedString(@"Auto Capitalization", nil);
    cell15.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone) != UITextAutocapitalizationTypeNone;
    {
        @weakify(self);
        [cell15.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorAutoCapitalization, optionSwitch.on ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell16 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell16.titleLabel.text = NSLocalizedString(@"Spell Checking", nil);
    cell16.optionSwitch.on = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo) != UITextSpellCheckingTypeNo;
    {
        @weakify(self);
        [cell16.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorSpellChecking, optionSwitch.on ? UITextSpellCheckingTypeYes : UITextSpellCheckingTypeNo);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell17 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell17.titleLabel.text = NSLocalizedString(@"Regular Expression", nil);
    cell17.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    {
        @weakify(self);
        [cell17.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorSearchRegularExpression, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    XXTEMoreSwitchCell *cell18 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell18.titleLabel.text = NSLocalizedString(@"Case Sensitive", nil);
    cell18.optionSwitch.on = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    {
        @weakify(self);
        [cell18.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            UISwitch *optionSwitch = (UISwitch *)sender;
            XXTEDefaultsSetBasic(XXTEEditorSearchCaseSensitive, optionSwitch.on);
            [self.editor setNeedsSoftReload];
        }];
    }
    
    NSArray *layoutSection = nil;
    NSArray *keyboardSection = nil;
    
    if (XXTE_IS_IPAD) {
        layoutSection = @[ simpleTitleViewCell, cell5, cell6 ];
    } else {
        layoutSection = @[ simpleTitleViewCell, fullScreenCell, cell5, cell6 ];
    }
    
    if (XXTE_IS_IPAD && XXTE_SYSTEM_9) {
        keyboardSection = @[ cell12 ];
    } else {
        keyboardSection = @[ cell12, cell13 ];
    }
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    @[ cell3, cell4 ],
                    layoutSection,
                    @[ cell7, cell8, tabCell ],
                    @[ cell9, cell10, cell11 ],
                    keyboardSection,
                    @[ cellBrackets, cell14, cell15, cell16 ],
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
            fontSettingsViewController.selectedFontName = XXTEDefaultsObject(XXTEEditorFontName, @"Courier");
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

#pragma mark - XXTEMoreValueViewDelegate

- (void)valueViewValueDidChanged:(XXTEMoreValueView *)view {
    XXTEDefaultsSetBasic(XXTEEditorFontSize, view.value);
    [self.editor setNeedsReload];
}

#pragma mark - XXTEEditorFontSettingsViewControllerDelegate

- (void)fontSettingsViewControllerSettingsDidChanged:(XXTEEditorFontSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTEEditorFontName, [controller.selectedFontName copy]);
    UIFont *font = [UIFont fontWithName:controller.selectedFontName size:17.f];
    if (font) {
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.text = [font familyName];
        ((XXTEMoreTitleValueCell *)staticCells[0][0]).valueLabel.font = font;
    }
    [self.editor setNeedsReload];
}

#pragma mark - XXTEEditorThemeSettingsViewControllerDelegate

- (void)themeSettingsViewControllerSettingsDidChanged:(XXTEEditorThemeSettingsViewController *)controller {
    XXTEDefaultsSetObject(XXTEEditorThemeName, [controller.selectedThemeName copy]);
    ((XXTEMoreTitleValueCell *)staticCells[1][0]).valueLabel.text = controller.selectedThemeName;
    [self.editor setNeedsReload];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
