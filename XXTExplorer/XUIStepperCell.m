//
//  XUIStepperCell.m
//  XXTExplorer
//
//  Created by Zheng on 04/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIStepperCell.h"
#import "XUI.h"
#import "XUILogger.h"

@interface XUIStepperCell ()

@property (weak, nonatomic) IBOutlet UIStepper *xui_stepper;
@property (weak, nonatomic) IBOutlet UILabel *xui_numberLabel;

@end

@implementation XUIStepperCell

@synthesize xui_value = _xui_value;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return YES;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"min": [NSNumber class],
      @"max": [NSNumber class],
      @"step": [NSNumber class],
      @"value": [NSNumber class],
      @"autoRepeat": [NSNumber class],
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.xui_stepper.wraps = NO;
    self.xui_stepper.continuous = YES;
    
    [self.xui_stepper addTarget:self action:@selector(xuiStepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.xui_stepper addTarget:self action:@selector(xuiStepperValueDidFinishChanging:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_stepper.enabled = enabled;
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    double value = [xui_value doubleValue];
    self.xui_stepper.value = value;
    [self xuiSetDisplayValue:value];
}

- (void)setXui_min:(NSNumber *)xui_min {
    _xui_min = xui_min;
    self.xui_stepper.minimumValue = [xui_min doubleValue];
}

- (void)setXui_max:(NSNumber *)xui_max {
    _xui_max = xui_max;
    self.xui_stepper.maximumValue = [xui_max doubleValue];
}

- (void)setXui_step:(NSNumber *)xui_step {
    _xui_step = xui_step;
    self.xui_stepper.stepValue = [xui_step doubleValue];
}

- (void)setXui_autoRepeat:(NSNumber *)xui_autoRepeat {
    _xui_autoRepeat = xui_autoRepeat;
    self.xui_stepper.autorepeat = [xui_autoRepeat boolValue];
}

- (IBAction)xuiStepperValueChanged:(UIStepper *)sender {
    if (sender == self.xui_stepper) {
        [self xuiSetDisplayValue:sender.value];
    }
}

- (IBAction)xuiStepperValueDidFinishChanging:(UIStepper *)sender {
    if (sender == self.xui_stepper) {
        self.xui_value = @(sender.value);
        [self.defaultsService saveDefaultsFromCell:self];
        [self xuiSetDisplayValue:sender.value];
    }
}

- (void)xuiSetDisplayValue:(double)value {
    if (self.xui_isInteger) {
        self.xui_numberLabel.text = [NSString stringWithFormat:@"%d", (int)value];
    } else {
        self.xui_numberLabel.text = [NSString stringWithFormat:@"%.2f", value];
    }
}

@end
