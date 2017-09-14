//
//  XUISegmentCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISegmentCell.h"
#import "XUILogger.h"

@interface XUISegmentCell ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *xui_segmentControl;

@end

@implementation XUISegmentCell

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

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"options": [NSArray class]
      };
}

+ (NSDictionary <NSString *, Class> *)optionValueTypes {
    return
    @{
      XUIOptionCellTitleKey: [NSString class],
      XUIOptionCellShortTitleKey: [NSString class],
      XUIOptionCellIconKey: [NSString class],
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    
    [self.xui_segmentControl addTarget:self action:@selector(xuiSegmentValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setXui_options:(NSArray<NSDictionary *> *)xui_options {
    for (NSDictionary *pair in xui_options) {
        for (NSString *pairKey in pair.allKeys) {
            Class pairClass = [[self class] optionValueTypes][pairKey];
            if (pairClass) {
                if (![pair[pairKey] isKindOfClass:pairClass]) {
                    return; // invalid option, ignore
                }
            }
        }
    }
    _xui_options = xui_options;
    [self.xui_segmentControl removeAllSegments];
    NSUInteger titleIdx = 0;
    for (NSDictionary *option in xui_options) {
        NSString *validTitle = option[XUIOptionCellTitleKey];
        [self.xui_segmentControl insertSegmentWithTitle:validTitle atIndex:titleIdx animated:NO];
        titleIdx++;
    }
    if (self.xui_value) {
        NSInteger selectedIdx = [self.xui_value integerValue];
        [self.xui_segmentControl setSelectedSegmentIndex:selectedIdx];
    }
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    if (xui_value) {
        NSUInteger selectedIndex = [self.xui_options indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([xui_value isEqual:obj[XUIOptionCellValueKey]]) {
                return YES;
            }
            return NO;
        }];
        if (selectedIndex != NSNotFound) {
            if (self.xui_segmentControl.numberOfSegments > selectedIndex) {
                [self.xui_segmentControl setSelectedSegmentIndex:selectedIndex];
            }
        }
    }
}

- (void)setXui_enabled:(NSNumber *)xui_enabled {
    [super setXui_enabled:xui_enabled];
    BOOL enabled = [xui_enabled boolValue];
    self.xui_segmentControl.enabled = enabled;
}

- (IBAction)xuiSegmentValueChanged:(UISegmentedControl *)sender {
    if (sender == self.xui_segmentControl) {
        NSUInteger selectedIndex = sender.selectedSegmentIndex;
        if (selectedIndex < self.xui_options.count) {
            id selectedValue = self.xui_options[selectedIndex][XUIOptionCellValueKey];
            self.xui_value = selectedValue;
            [self.defaultsService saveDefaultsFromCell:self];
        }
    }
}

- (void)setTheme:(XUITheme *)theme {
    _theme = theme;
    self.xui_segmentControl.tintColor = theme.tintColor;
}

@end
