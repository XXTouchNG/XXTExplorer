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

@synthesize xui_value = _xui_value;

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
      @"imagePath": [NSString class],
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

- (void)setXui_imagePath:(NSString *)xui_imagePath {
    _xui_imagePath = xui_imagePath;
    NSString *imagePath = [self.adapter.bundle pathForResource:xui_imagePath ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    self.iconImageView.image = image;
}

- (UIImage *)centeredImage {
    return self.iconImageView.image;
}

- (void)setCenteredImage:(UIImage *)centeredImage {
    self.iconImageView.image = centeredImage;
}

@end
