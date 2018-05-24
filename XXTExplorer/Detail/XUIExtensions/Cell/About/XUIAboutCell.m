//
//  XUIAboutCell.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIAboutCell.h"

@interface XUIAboutCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation XUIAboutCell

@synthesize xui_value = _xui_value, xui_icon = _xui_icon, xui_iconRenderingMode = _xui_iconRenderingMode;

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
    return YES;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"value": [NSString class],
      };
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel.textColor = XXTColorDefault();
}

- (void)setXui_label:(NSString *)xui_label {
    [super setXui_label:xui_label];
    self.titleLabel.text = self.adapter ? [self.adapter localizedString:xui_label] : xui_label;
}

- (void)setXui_value:(id)xui_value {
    _xui_value = xui_value;
    self.subtitleLabel.text = xui_value;
}

#pragma mark - XUI Setters

- (void)setXui_icon:(NSString *)xui_icon {
    _xui_icon = xui_icon;
    if (xui_icon) {
        NSBundle *bundle = nil;
        if (self.adapter) {
            bundle = self.adapter.bundle;
        } else {
            bundle = [NSBundle mainBundle];
        }
        NSString *imagePath = [bundle pathForResource:xui_icon ofType:nil];
        self.iconImageView.image = [self imageWithCurrentRenderingMode:[UIImage imageWithContentsOfFile:imagePath]];
    } else {
        self.iconImageView.image = nil;
    }
}

- (void)setXui_iconRenderingMode:(NSString *)xui_iconRenderingMode {
    _xui_iconRenderingMode = xui_iconRenderingMode;
    UIImage *originalImage = self.iconImageView.image;
    if (originalImage)
    {
        self.iconImageView.image = [self imageWithCurrentRenderingMode:originalImage];
    }
}

- (UIImage *)imageWithCurrentRenderingMode:(UIImage *)image {
    NSString *renderingModeString = _xui_iconRenderingMode;
    UIImageRenderingMode renderingMode = UIImageRenderingModeAutomatic;
    if ([renderingModeString isEqualToString:@"AlwaysOriginal"]) {
        renderingMode = UIImageRenderingModeAlwaysOriginal;
    } else if ([renderingModeString isEqualToString:@"AlwaysTemplate"]) {
        renderingMode = UIImageRenderingModeAlwaysTemplate;
    }
    return [image imageWithRenderingMode:renderingMode];
}

- (UIImage *)centeredImage {
    return self.iconImageView.image;
}

- (void)setCenteredImage:(UIImage *)centeredImage {
    self.iconImageView.image = centeredImage;
}

- (void)setInternalTheme:(XUITheme *)theme {
    [super setInternalTheme:theme];
    self.iconImageView.tintColor = theme.foregroundColor;
    self.titleLabel.textColor = theme.foregroundColor;
    self.subtitleLabel.textColor = theme.labelColor;
}

@end
