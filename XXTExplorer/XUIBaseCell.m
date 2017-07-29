//
// Created by Zheng on 28/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XUIBaseCell.h"


@implementation XUIBaseCell {

}

+ (BOOL)xibBasedLayout {
    return NO;
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

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    return YES;
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
        _xui_height = @(UITableViewAutomaticDimension);
    } else {
        _xui_height = @44.f; // standard cell height
    }
    if ([self.class layoutNeedsTextLabel]) {
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
            self.imageView.image = [UIImage imageNamed:xui_icon inBundle:self.bundle compatibleWithTraitCollection:nil];
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
