//
//  XUISliderCell.m
//  XXTExplorer
//
//  Created by Zheng on 29/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISliderCell.h"
#import "XUI.h"
#import "XUILogger.h"

@interface XUISliderCell ()

@property (weak, nonatomic) IBOutlet UISlider *xui_slider;
@property (weak, nonatomic) IBOutlet UILabel *xui_slider_valueLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *xui_slider_valueLabel_width;
@property (assign, nonatomic) BOOL shouldUpdateValue;

@end

@implementation XUISliderCell

@synthesize xui_value = _xui_value, theme = _theme;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"min": [NSNumber class],
      @"max": [NSNumber class],
      @"showValue": [NSNumber class],
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
    [self.xui_slider addTarget:self action:@selector(xuiSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.xui_slider addTarget:self action:@selector(xuiSliderValueDidFinishChanging:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_slider.enabled = enabled;
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    [self setNeedsUpdateValue];
    [self updateValueIfNeeded];
}

- (void)setXui_min:(NSNumber *)xui_min {
    _xui_min = xui_min;
    self.xui_slider.minimumValue = [xui_min floatValue];
    [self updateValueIfNeeded];
}

- (void)setXui_max:(NSNumber *)xui_max {
    _xui_max = xui_max;
    self.xui_slider.maximumValue = [xui_max floatValue];
    [self updateValueIfNeeded];
}

- (void)setXui_showValue:(NSNumber *)xui_showValue {
    _xui_showValue = xui_showValue;
    BOOL showValue = [xui_showValue boolValue];
    if (showValue) {
        self.xui_slider_valueLabel_width.constant = 64.f;
    } else {
        self.xui_slider_valueLabel_width.constant = 0.f;
    }
}

- (IBAction)xuiSliderValueChanged:(UISlider *)sender {
    if (sender == self.xui_slider) {
//        self.xui_slider_valueLabel.text = [@(sender.value) stringValue];
        self.xui_slider_valueLabel.text = [NSString stringWithFormat:@"%.2f", sender.value];
    }
}

- (IBAction)xuiSliderValueDidFinishChanging:(UISlider *)sender {
    if (sender == self.xui_slider) {
        self.xui_value = @(sender.value);
        [self.adapter saveDefaultsFromCell:self];
        
//        self.xui_slider_valueLabel.text = [@(sender.value) stringValue];
        self.xui_slider_valueLabel.text = [NSString stringWithFormat:@"%.2f", sender.value];
    }
}

- (void)setTheme:(XUITheme *)theme {
    _theme = theme;
    self.xui_slider_valueLabel.textColor = theme.valueColor;
    self.xui_slider.minimumTrackTintColor = theme.successColor;
}

- (void)setNeedsUpdateValue {
    self.shouldUpdateValue = YES;
}

- (void)updateValueIfNeeded {
    if (self.shouldUpdateValue) {
        self.shouldUpdateValue = NO;
        float value = [self.xui_value floatValue];
        self.xui_slider.value = value;
        self.xui_slider_valueLabel.text = [NSString stringWithFormat:@"%.2f", value];
    }
}

@end
