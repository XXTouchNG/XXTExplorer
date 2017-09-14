//
//  XUIMultipleOptionCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIMultipleOptionCell.h"
#import "XUI.h"
#import "XUILogger.h"

@implementation XUIMultipleOptionCell

@synthesize xui_value = _xui_value, theme = _theme;

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return YES;
}

+ (BOOL)layoutNeedsImageView {
    return YES;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"options": [NSArray class],
      @"maxCount": [NSNumber class],
      @"staticTextMessage": [NSString class],
      @"value": [NSArray class]
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
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        NSArray *validOptions = cellEntry[@"options"];
        NSUInteger maxCount = [cellEntry[@"maxCount"] unsignedIntegerValue];
        if (maxCount > validOptions.count) {
            superResult = NO;
            checkType = kXUICellFactoryErrorInvalidValueDomain;
            @throw [NSString stringWithFormat:NSLocalizedString(@"the value \"%@\" of key \"%@\" is invalid.", nil), cellEntry[@"maxCount"], @"maxCount"];
        }
    } @catch (NSString *exceptionReason) {
        superResult = NO;
        NSError *exceptionError = [NSError errorWithDomain:checkType code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (error) {
            *error = exceptionError;
        }
    } @finally {
        
    }
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    XUI_START_IGNORE_PARTIAL
    if (XUI_SYSTEM_9) {
        self.detailTextLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightLight];
    }
    XUI_END_IGNORE_PARTIAL
    self.detailTextLabel.textColor = UIColor.grayColor;
    self.detailTextLabel.text = nil;
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
}

- (void)setXui_value:(id)xui_value {
    NSArray *value = xui_value;
    NSUInteger maxCount = [self.xui_maxCount unsignedIntegerValue];
    if (value.count > maxCount) {
        return; // Invalid value, ignore
    }
    _xui_value = xui_value;
}

- (void)setTheme:(XUITheme *)theme {
    _theme = theme;
    self.textLabel.textColor = theme.labelColor;
    self.detailTextLabel.textColor = theme.valueColor;
}

@end
