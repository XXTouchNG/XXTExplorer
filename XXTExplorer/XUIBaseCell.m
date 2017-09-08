//
// Created by Zheng on 28/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XUIBaseCell.h"
#import "XUILogger.h"
#import "XUI.h"

@implementation XUIBaseCell {

}

+ (BOOL)xibBasedLayout {
    return NO;
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

+ (NSDictionary <NSString *, NSString *> *)entryValueTypes {
    return @{};
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    NSMutableDictionary *baseTypes =
    [@{
      @"cell": [NSString class],
      @"label": [NSString class],
      @"defaults": [NSString class],
      @"key": [NSString class],
      @"icon": [NSString class],
      @"enabled": [NSNumber class],
      @"height": [NSNumber class]
      } mutableCopy];
    [baseTypes addEntriesFromDictionary:[self.class entryValueTypes]];
    BOOL checkResult = YES;
    NSString *checkType = kXUICellFactoryErrorDomain;
    @try {
        for (NSString *pairKey in cellEntry.allKeys) {
            Class pairClass = baseTypes[pairKey];
            if (pairClass) {
                if (![cellEntry[pairKey] isKindOfClass:pairClass]) {
                    checkType = kXUICellFactoryErrorInvalidTypeDomain;
                    @throw [NSString stringWithFormat:NSLocalizedString(@"key \"%@\", should be \"%@\".", nil), pairKey, NSStringFromClass(pairClass)];
                }
            }
        }
    } @catch (NSString *exceptionReason) {
        checkResult = NO;
        NSError *exceptionError = [NSError errorWithDomain:checkType code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (error) {
            *error = exceptionError;
        }
    } @finally {
        
    }
    return checkResult;
}

- (NSString *)xui_cell {
    return NSStringFromClass([self class]);
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupCell];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupCell];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupCell];
}

- (void)setupCell {
    _xui_enabled = @YES;
    if ([self.class layoutRequiresDynamicRowHeight]) {
        _xui_height = @(-1);
    } else {
        _xui_height = @44.f; // standard cell height
    }
    if ([self.class layoutNeedsTextLabel]) {
        XUI_START_IGNORE_PARTIAL
        if (XUI_SYSTEM_9) {
            self.textLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightLight];
        } else {
            self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.f];
        }
        XUI_END_IGNORE_PARTIAL
        self.textLabel.text = nil;
    }
}

- (id)valueForUndefinedKey:(NSString *)key {
    return nil; // do nothing
}

- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key {
    // do nothing
}

- (void)setXui_icon:(NSString *)xui_icon {
    _xui_icon = xui_icon;
    if ([self.class layoutNeedsImageView]) {
        if (xui_icon) {
            XXTE_START_IGNORE_PARTIAL
            if (XXTE_SYSTEM_8) {
                self.imageView.image = [UIImage imageNamed:xui_icon inBundle:self.bundle compatibleWithTraitCollection:nil];
            } else {
                NSString *imagePath = [self.bundle pathForResource:xui_icon ofType:nil];
                self.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
            }
            XXTE_END_IGNORE_PARTIAL
        } else {
            self.imageView.image = nil;
        }
    }
}

- (void)setXui_label:(NSString *)xui_label {
    _xui_label = xui_label;
    if ([self.class layoutNeedsTextLabel]) {
        self.textLabel.text = xui_label;
    }
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
}

@end
