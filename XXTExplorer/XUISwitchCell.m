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
    BOOL value = [xui_value boolValue];
    self.xui_switch.on = self.xui_negate ? !value : value;
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_switch.enabled = enabled;
}

- (void)setXui_negate:(NSNumber *)xui_negate {
    _xui_negate = xui_negate;
    BOOL value = [self.xui_value boolValue];
    self.xui_switch.on = xui_negate ? !value : value;
}

- (IBAction)xuiSwitchValueChanged:(UISwitch *)sender {
    if (sender == self.xui_switch) {
        self.xui_value = @(sender.on);
        [self.defaultsService saveDefaultsFromCell:self];
    }
}

@end
