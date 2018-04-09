//
//  XXTExplorerItemRepeatViewController.m
//  XXTExplorer
//
//  Created by Zheng on 06/04/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTExplorerItemRepeatViewController.h"
#import "XXTEMoreValueViewCell.h"
#import "XXTEMoreValueView.h"

#import <XUI/XUISwitchCell.h>
#import <XUI/XUITitleValueCell.h>

#import <LGAlertView/LGAlertView.h>
#import "XXTENumberTextInputObject.h"
#import <objc/runtime.h>

#import "XXTExplorerItemDetailViewController.h"

#define LONGLONGMAX_STRING @"9223372036854775807"

@interface XXTExplorerItemRepeatViewController () <XXTEMoreValueViewDelegate, LGAlertViewDelegate>
@property (nonatomic, strong) XXTEMoreValueViewCell *speedValueViewCell;
@property (nonatomic, strong) XUISwitchCell *infiniteRepeatSwitchCell;
@property (nonatomic, strong) XUITitleValueCell *repeatTimesValueViewCell;
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
    
    if (![self importRecordingScript]) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot read or parse specific script: \"%@\".", nil), self.entryPath]);
        [self.tableView setUserInteractionEnabled:NO];
        allowsExport = NO;
    } else {
        allowsExport = YES;
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        if (allowsExport) {
            [self exportAction];
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

- (XUITitleValueCell *)repeatTimesValueViewCell {
    if (!_repeatTimesValueViewCell) {
        XUITitleValueCell *cell = [[XUITitleValueCell alloc] init];
        cell.xui_label = NSLocalizedString(@"Repeat Times", nil);
        cell.xui_value = @(1);
        cell.selectedBackgroundView.backgroundColor = XXTColorCellSelected();
        _repeatTimesValueViewCell = cell;
    }
    return _repeatTimesValueViewCell;
}

- (XUISwitchCell *)infiniteRepeatSwitchCell {
    if (!_infiniteRepeatSwitchCell) {
        XUISwitchCell *cell = [[XUISwitchCell alloc] init];
        cell.xui_label = NSLocalizedString(@"Infinite Repeat", nil);
        cell.xui_value = @(NO);
        _infiniteRepeatSwitchCell = cell;
    }
    return _infiniteRepeatSwitchCell;
}

#pragma mark - Actions

- (void)exportAction {
    if (![self exportRecordingScript]) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot parse and override specific script: \"%@\".", nil), self.entryPath]);
    }
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
        return 2;
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
            UITableViewCell *cell = self.repeatTimesValueViewCell;
            [self resetCell:cell];
            return cell;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            
        } else if (section == 1) {
            return NSLocalizedString(@"If \"Infinite Repeat\" is enabled, \"Repeat Times\" will make no sense.", nil);
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
            id switchVal = self.infiniteRepeatSwitchCell.xui_value;
            if ([switchVal isKindOfClass:[NSNumber class]] && [switchVal boolValue] == YES) {
                toastMessage(self, NSLocalizedString(@"If \"Infinite Repeat\" is enabled, \"Repeat Times\" will make no sense.", nil));
                return;
            }
            
            XUITitleValueCell *cell = self.repeatTimesValueViewCell;
            
            LGAlertView *alertView = [LGAlertView alertViewWithTextFieldsAndTitle:NSLocalizedString(@"Repeat Times", nil) message:NSLocalizedString(@"Please enter a valid positive integer.", nil) numberOfTextFields:1 textFieldsSetupHandler:^(UITextField * _Nonnull textField, NSUInteger index) {
                textField.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Integer (1 ~ %ld)", nil), INT_MAX];
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.text = [NSString stringWithFormat:@"%@", cell.xui_value];
            } buttonTitles:@[ NSLocalizedString(@"Save", nil) ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil];
            [alertView setDelegate:self];
            [alertView showAnimated:YES completionHandler:nil];
            
            UITextField *textField = [alertView.textFieldsArray firstObject];
            XXTENumberTextInputObject *numberDelegate = [[XXTENumberTextInputObject alloc] init];
            [numberDelegate setMaxLength:10];
            [numberDelegate setTextInput:textField];
            objc_setAssociatedObject(alertView, NSStringFromClass([XXTENumberTextInputObject class]).UTF8String, numberDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (!speedCheck || speedCheck.numberOfRanges != 2) return nil;
    NSTextCheckingResult *timesCheck = [[[self class] repeatTimesLineRegex] firstMatchInString:playTimesLine options:0 range:NSMakeRange(0, playTimesLine.length)];
    if (!timesCheck || timesCheck.numberOfRanges != 2) return nil;
    
    NSRange speedRange = [speedCheck rangeAtIndex:1];
    NSRange timesRange = [timesCheck rangeAtIndex:1];
    NSString *speedStr = [playSpeedLine substringWithRange:speedRange];
    NSString *timesStr = [playTimesLine substringWithRange:timesRange];
    
    if (speedStr.length > 4) return NO;
    double speedDouble = [speedStr doubleValue];
    float speedValue = roundf(speedDouble * 100.0);
    if (speedValue < 10 || speedValue > 990) return NO;
    self.speedValueViewCell.valueView.value = speedValue / 100.0;
    
    if ([timesStr isEqualToString:LONGLONGMAX_STRING]) {
        self.repeatTimesValueViewCell.xui_value = @(1);
        self.infiniteRepeatSwitchCell.xui_value = @(YES);
    } else {
        NSInteger timesValue = [timesStr integerValue];
        if (timesValue < 1) return NO;
        self.repeatTimesValueViewCell.xui_value = @(timesValue);
        self.infiniteRepeatSwitchCell.xui_value = @(NO);
    }
    
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

- (BOOL)exportRecordingScript {
    NSString *entryPath = self.entryPath;
    NSMutableArray <NSString *> *checkArray = [self.scriptLines mutableCopy];
    
    NSString *playSpeedLineTemplate = NSLocalizedString(@"local play_speed = %@  -- Speed", nil);
    NSString *playTimesLineTemplate = NSLocalizedString(@"local play_times = %@  -- Repeat Times", nil);
    NSString *newPlaySpeedLine = [NSString stringWithFormat:playSpeedLineTemplate, [NSString stringWithFormat:@"%.1f", self.speedValueViewCell.valueView.value]];
    
    NSString *timesValueString = nil;
    id switchVal = self.infiniteRepeatSwitchCell.xui_value;
    if ([switchVal isKindOfClass:[NSNumber class]] && [switchVal boolValue] == YES) {
        timesValueString = LONGLONGMAX_STRING;
    } else {
        id timesVal = self.repeatTimesValueViewCell.xui_value;
        if ([timesVal isKindOfClass:[NSNumber class]]) {
            timesValueString = [NSString stringWithFormat:@"%ld", [timesVal integerValue]];
        }
    }
    
    NSString *newPlayTimesLine = [NSString stringWithFormat:playTimesLineTemplate, timesValueString];
    checkArray[2] = newPlaySpeedLine;
    checkArray[3] = newPlayTimesLine;
    NSString *newContent = [checkArray componentsJoinedByString:@"\n"];
    return [newContent writeToFile:entryPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - LGAlertViewDelegate

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    if (index == 0) {
        XUITitleValueCell *cell = self.repeatTimesValueViewCell;
        
        UITextField *textField = [alertView.textFieldsArray firstObject];
        NSString *text = textField.text;
        long long textVal = [text longLongValue];
        
        BOOL isNumber = ([[XXTENumberTextInputObject numberRegex] firstMatchInString:text options:0 range:NSMakeRange(0, text.length)] != nil);
        if (!isNumber) {
            textVal = 1;
        }
        if (textVal < 1) {
            textVal = 1;
        } else if (textVal > INT_MAX) {
            textVal = INT_MAX;
        }
        
        NSInteger newTextVal = (NSInteger)textVal;
        cell.xui_value = @(newTextVal);
        [self resetCell:cell];
        
        [alertView dismissAnimated];
    }
}

- (void)resetCell:(UITableViewCell *)cell {
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerItemRepeatViewController dealloc]");
#endif
}

@end
