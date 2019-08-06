//
//  XXTExplorerItemRepeatViewController.m
//  XXTExplorer
//
//  Created by Zheng on 06/04/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTExplorerItemRepeatViewController.h"
#import "XXTEMoreValueViewCell.h"
#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreTextFieldCell.h"
#import "XXTEMoreValueView.h"

#import "XXTExplorerItemDetailViewController.h"

#define LONGLONGMAX_STRING @"9223372036854775807"

@interface XXTExplorerItemRepeatViewController () <XXTEMoreValueViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) XXTEMoreValueViewCell *speedValueViewCell;
@property (nonatomic, strong) XXTEMoreSwitchCell *infiniteRepeatSwitchCell;
@property (nonatomic, strong) XXTEMoreTextFieldCell *repeatTimesFieldCell;
@property (nonatomic, strong) NSArray <NSString *> *scriptLines;
@end

@implementation XXTExplorerItemRepeatViewController {
    BOOL allowsExport;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        BOOL isLuaExtension = [[path pathExtension] isEqualToString:@"lua"];
        if (!isLuaExtension) {
            return nil;
        }
        BOOL isRecordingScript = [XXTExplorerItemDetailViewController checkRecordingScript:path];
        if (!isRecordingScript) {
            return nil;
        }
        _entryPath = path;
        allowsExport = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delaysContentTouches = NO;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
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
    
    [self updateCells];
    if (![self importRecordingScript]) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot read or parse specific script: \"%@\".", nil), self.entryPath.lastPathComponent]);
        [self.tableView setUserInteractionEnabled:NO];
        allowsExport = NO;
    } else {
        allowsExport = YES;
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        if (allowsExport) {
            [self exportRecordingScript];
        }
    }
}

#pragma mark - UIView Getters

- (XXTEMoreValueViewCell *)speedValueViewCell {
    if (!_speedValueViewCell) {
        XXTEMoreValueViewCell *cell = [[[UINib nibWithNibName:NSStringFromClass([XXTEMoreValueViewCell class]) bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
        cell.titleLabel.text = NSLocalizedString(@"Speed", nil);
        cell.valueViewWidth = 128.0;
        cell.valueView.maxValue = 9.9;
        cell.valueView.minValue = 0.1;
        cell.valueView.stepValue = 0.1;
        cell.valueView.value = 1.0;
        cell.valueView.isInteger = NO;
        cell.valueView.unitString = @"x";
        cell.valueView.delegate = self;
        _speedValueViewCell = cell;
    }
    return _speedValueViewCell;
}

- (void)updateCells {
    XXTEMoreSwitchCell *cell1 = [[[UINib nibWithNibName:NSStringFromClass([XXTEMoreSwitchCell class]) bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Infinite Repeat", nil);
    [cell1.optionSwitch addTarget:self action:@selector(infiniteSwitchTapped:) forControlEvents:UIControlEventValueChanged];
    _infiniteRepeatSwitchCell = cell1;
    
    XXTEMoreTextFieldCell *cell2 = [[[UINib nibWithNibName:NSStringFromClass([XXTEMoreTextFieldCell class]) bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Repeat Times", nil);
    cell2.valueField.text = @"1";
    cell2.valueField.delegate = self;
    _repeatTimesFieldCell = cell2;
}

#pragma mark - Actions

- (void)infiniteSwitchTapped:(UISwitch *)sender {
    [self updateCells];
    self.infiniteRepeatSwitchCell.optionSwitch.on = sender.on;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - XXTEMoreValueViewDelegate

- (void)valueViewValueDidChanged:(XXTEMoreValueView *)view {
    if (view == self.speedValueViewCell.valueView) {
        
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        if (self.infiniteRepeatSwitchCell.optionSwitch.on) {
            return 1;
        } else {
            return 2;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return self.speedValueViewCell;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            return self.infiniteRepeatSwitchCell;
        } else if (indexPath.row == 1) {
            return self.repeatTimesFieldCell;
        }
    }
    return [UITableViewCell new];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return NSLocalizedString(@"Speed", nil);
        } else if (section == 1) {
            return NSLocalizedString(@"Repeat", nil);
        }
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 88.f;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            return 44.f;
        } else if (indexPath.row == 1) {
            return 44.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            BOOL switchVal = self.infiniteRepeatSwitchCell.optionSwitch.on;
            if (switchVal == YES) {
                toastMessage(self, NSLocalizedString(@"If \"Infinite Repeat\" is enabled, \"Repeat Times\" will make no sense.", nil));
                return;
            }
        }
    }
}

#pragma mark - Parse

- (NSArray <NSString *> *)scriptLines {
    if (!_scriptLines) {
        NSString *entryPath = self.entryPath;
        if (!entryPath) return nil;
        NSData *checkData = [[NSData alloc] initWithContentsOfFile:entryPath options:0 error:nil];
        if (!checkData) return nil;
        NSString *checkString = [[NSString alloc] initWithData:checkData encoding:NSUTF8StringEncoding];
        if (!checkString) return nil;
        checkString = [checkString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray <NSString *> *checkArray = [checkString componentsSeparatedByString:@"\n"];
        if (checkArray.count < 6) return nil;
        _scriptLines = checkArray;
    }
    return _scriptLines;
}

- (BOOL)importRecordingScript {
    NSArray <NSString *> *checkArray = self.scriptLines;
    
    NSString *playSpeedLine = checkArray[2];
    NSString *playTimesLine = checkArray[3];
    NSTextCheckingResult *speedCheck = [[[self class] speedLineRegex] firstMatchInString:playSpeedLine options:0 range:NSMakeRange(0, playSpeedLine.length)];
    if (!speedCheck || speedCheck.numberOfRanges != 2) return NO;
    NSTextCheckingResult *timesCheck = [[[self class] repeatTimesLineRegex] firstMatchInString:playTimesLine options:0 range:NSMakeRange(0, playTimesLine.length)];
    if (!timesCheck || timesCheck.numberOfRanges != 2) return NO;
    
    NSRange speedRange = [speedCheck rangeAtIndex:1];
    NSRange timesRange = [timesCheck rangeAtIndex:1];
    NSString *speedStr = [playSpeedLine substringWithRange:speedRange];
    NSString *timesStr = [playTimesLine substringWithRange:timesRange];
    
    if (speedStr.length > 4) return NO;
    double speedDouble = [speedStr doubleValue];
    float speedValue = roundf(speedDouble * 100.0);
    if (speedValue < 10 || speedValue > 990) return NO;
    self.speedValueViewCell.valueView.value = speedValue / 100.0;
    
    BOOL isNumberTimes = ([[[self class] numberRegex] firstMatchInString:timesStr options:0 range:NSMakeRange(0, timesStr.length)] != nil);
    
    BOOL infiniteRepeat = NO;
    
    if ([timesStr isEqualToString:LONGLONGMAX_STRING]) {
        infiniteRepeat = YES;
        timesStr = LONGLONGMAX_STRING;
    } else if (isNumberTimes && timesStr.length > 18) {
        infiniteRepeat = YES;
        timesStr = LONGLONGMAX_STRING;
    } else if (isNumberTimes && timesStr.length > 0 && timesStr.length <= 18) {
        infiniteRepeat = NO;
        long long timesValue = [timesStr longLongValue];
        if (timesValue < 1) return NO;
        timesStr = [NSString stringWithFormat:@"%lld", timesValue];
    } else {
        timesStr = @"1";
    }
    
    self.infiniteRepeatSwitchCell.optionSwitch.on = infiniteRepeat;
    self.repeatTimesFieldCell.valueField.text = timesStr;
    
    return YES;
}

+ (NSRegularExpression *)speedLineRegex {
    static NSRegularExpression *exp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exp = [NSRegularExpression regularExpressionWithPattern:@"local play_speed = ([\\d\\.]+)" options:0 error:nil];
    });
    return exp;
}

+ (NSRegularExpression *)repeatTimesLineRegex {
    static NSRegularExpression *exp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exp = [NSRegularExpression regularExpressionWithPattern:@"local play_times = (\\d+)" options:0 error:nil];
    });
    return exp;
}

+ (NSRegularExpression *)numberRegex {
    static NSRegularExpression *exp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exp = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)" options:0 error:nil];
    });
    return exp;
}

- (BOOL)exportRecordingScript {
    NSString *entryPath = self.entryPath;
    NSMutableArray <NSString *> *checkArray = [self.scriptLines mutableCopy];
    
    NSString *playSpeedLineTemplate = NSLocalizedString(@"local play_speed = %@  -- Speed", nil);
    NSString *playTimesLineTemplate = NSLocalizedString(@"local play_times = %@  -- Repeat Times", nil);
    NSString *newPlaySpeedLine = [NSString stringWithFormat:playSpeedLineTemplate, [NSString stringWithFormat:@"%.1f", self.speedValueViewCell.valueView.value]];
    
    NSString *timesValueString = nil;
    NSString *timesString = self.repeatTimesFieldCell.valueField.text;
    BOOL switchVal = self.infiniteRepeatSwitchCell.optionSwitch.on;
    
    BOOL isNumberTimes = ([[[self class] numberRegex] firstMatchInString:timesString options:0 range:NSMakeRange(0, timesString.length)] != nil);
    if (switchVal == YES) {
        timesValueString = LONGLONGMAX_STRING;
    } else if (isNumberTimes && timesString.length > 18) {
        return NO;
    } else if (isNumberTimes && timesString.length > 0 && timesString.length <= 18) {
        long long timesValue = [timesString longLongValue];
        if (timesValue < 1) return NO;
        timesValueString = [NSString stringWithFormat:@"%lld", timesValue];
    } else {
        return NO;
    }
    
    NSString *newPlayTimesLine = [NSString stringWithFormat:playTimesLineTemplate, timesValueString];
    checkArray[2] = newPlaySpeedLine;
    checkArray[3] = newPlayTimesLine;
    NSString *newContent = [checkArray componentsJoinedByString:@"\n"];
    return [newContent writeToFile:entryPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
