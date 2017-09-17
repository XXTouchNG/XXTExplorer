//
//  XUISwitchCell.m
//  XXTExplorer
//
//  Created by Zheng on 28/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISwitchCell.h"

@interface XUISwitchCell ()

@property (weak, nonatomic) IBOutlet UISwitch *xui_switch;
@property (assign, nonatomic) BOOL shouldUpdateValue;

@end

@implementation XUISwitchCell

@synthesize xui_value = _xui_value;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return YES;
}

+ (BOOL)layoutNeedsImageView {
    return YES;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"negate": [NSNumber class],
      @"value": [NSNumber class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.xui_switch addTarget:self action:@selector(xuiSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    [self setNeedsUpdateValue];
    [self updateValueIfNeeded];
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_switch.enabled = enabled;
}

- (void)setXui_negate:(NSNumber *)xui_negate {
    _xui_negate = xui_negate;
    [self updateValueIfNeeded];
}

- (IBAction)xuiSwitchValueChanged:(UISwitch *)sender {
    if (sender == self.xui_switch) {
        self.xui_value = self.xui_negate ? @(!(BOOL)sender.on) : @((BOOL)sender.on);
        [self.adapter saveDefaultsFromCell:self];
    }
}

- (void)setTheme:(XUITheme *)theme {
    [super setTheme:theme];
    self.xui_switch.onTintColor = theme.successColor;
}

- (void)setNeedsUpdateValue {
    self.shouldUpdateValue = YES;
}

- (void)updateValueIfNeeded {
    if (self.shouldUpdateValue) {
        self.shouldUpdateValue = NO;
        BOOL value = [self.xui_value boolValue];
        self.xui_switch.on = self.xui_negate ? !value : value;
    }
}

@end
