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
#import <XUI/XUIStepperCell.h>

#import "XXTExplorerItemDetailViewController.h"

#define LONGLONGMAX_STRING @"9223372036854775807"

@interface XXTExplorerItemRepeatViewController () <XXTEMoreValueViewDelegate>
@property (nonatomic, strong) XXTEMoreValueViewCell *speedValueViewCell;
@property (nonatomic, strong) XUISwitchCell *infiniteRepeatSwitchCell;
@property (nonatomic, strong) XUIStepperCell *repeatTimesValueViewCell;
@end

@implementation XXTExplorerItemRepeatViewController

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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    if (![self importRecordingScript]) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot read or parse specific script: \"%@\".", nil), self.entryPath]);
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self exportAction];
    }
}

#pragma mark - UIView Getters

- (XXTEMoreValueViewCell *)speedValueViewCell {
    if (!_speedValueViewCell) {
        _speedValueViewCell = [[[UINib nibWithNibName:NSStringFromClass([XXTEMoreValueViewCell class]) bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
        _speedValueViewCell.titleLabel.text = NSLocalizedString(@"Speed", nil);
        _speedValueViewCell.valueViewWidth = 128.0;
        _speedValueViewCell.valueView.maxValue = 3.0;
        _speedValueViewCell.valueView.minValue = 0.1;
        _speedValueViewCell.valueView.stepValue = 0.1;
        _speedValueViewCell.valueView.value = 1.0;
        _speedValueViewCell.valueView.isInteger = NO;
        _speedValueViewCell.valueView.unitString = @"x";
        _speedValueViewCell.valueView.delegate = self;
    }
    return _speedValueViewCell;
}

- (XUIStepperCell *)repeatTimesValueViewCell {
    if (!_repeatTimesValueViewCell) {
        _repeatTimesValueViewCell = [[XUIStepperCell alloc] init];
        _repeatTimesValueViewCell.xui_label = NSLocalizedString(@"Repeat Times", nil);
        _repeatTimesValueViewCell.xui_max = @(9999);
        _repeatTimesValueViewCell.xui_min = @(1);
        _repeatTimesValueViewCell.xui_step = @(1);
        _repeatTimesValueViewCell.xui_isInteger = @(YES);
        _repeatTimesValueViewCell.xui_autoRepeat = @(YES);
        _repeatTimesValueViewCell.xui_value = @(1);
    }
    return _repeatTimesValueViewCell;
}

- (XUISwitchCell *)infiniteRepeatSwitchCell {
    if (!_infiniteRepeatSwitchCell) {
        _infiniteRepeatSwitchCell = [[XUISwitchCell alloc] init];
        _infiniteRepeatSwitchCell.xui_label = NSLocalizedString(@"Infinite Repeat", nil);
        _infiniteRepeatSwitchCell.xui_value = @(NO);
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
            return self.repeatTimesValueViewCell;
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

- (BOOL)importRecordingScript {
    
    NSString *entryPath = self.entryPath;
    if (!entryPath) return NO;
    NSData *checkData = [[NSData alloc] initWithContentsOfFile:entryPath options:0 error:nil];
    if (!checkData) return NO;
    NSString *checkString = [[NSString alloc] initWithData:checkData encoding:NSUTF8StringEncoding];
    if (!checkString) return NO;
    NSArray <NSString *> *checkArray = [checkString componentsSeparatedByString:@"\n"];
    if (checkArray.count < 6) return NO;
    
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
    double speedValue = [speedStr doubleValue];
    if (speedValue - 0.1 < 0.01) return NO;
    self.speedValueViewCell.valueView.value = speedValue;
    
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
    if (!entryPath) return NO;
    NSData *checkData = [[NSData alloc] initWithContentsOfFile:entryPath options:0 error:nil];
    if (!checkData) return NO;
    NSString *checkString = [[NSString alloc] initWithData:checkData encoding:NSUTF8StringEncoding];
    if (!checkString) return NO;
    NSMutableArray <NSString *> *checkArray = [[checkString componentsSeparatedByString:@"\n"] mutableCopy];
    if (checkArray.count < 6) return NO;
    
    NSString *playSpeedLine = checkArray[2];
    NSString *playTimesLine = checkArray[3];
    NSTextCheckingResult *speedCheck = [[[self class] speedLineRegex] firstMatchInString:playSpeedLine options:0 range:NSMakeRange(0, playSpeedLine.length)];
    if (!speedCheck || speedCheck.numberOfRanges != 2) return NO;
    NSTextCheckingResult *timesCheck = [[[self class] repeatTimesLineRegex] firstMatchInString:playTimesLine options:0 range:NSMakeRange(0, playTimesLine.length)];
    if (!timesCheck || timesCheck.numberOfRanges != 2) return NO;
    
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerItemRepeatViewController dealloc]");
#endif
}

@end
