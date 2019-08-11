//
//  XXTEMoreLinkCell.m
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreLinkCell.h"

@interface XXTEMoreLinkCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end

@implementation XXTEMoreLinkCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.titleLabel.text = @"";
    self.iconImage = nil;
    
    if (@available(iOS 13.0, *)) {
        self.iconImageView.tintColor = [UIColor labelColor];
    } else {
        self.iconImageView.tintColor = [UIColor blackColor];
    }
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    self.iconImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (iconImage) {
        self.leftConstraint.constant = 16.0;
        self.iconWidthConstraint.constant = 32.0;
    } else {
        self.leftConstraint.constant = 0.0;
        self.iconWidthConstraint.constant = 0.0;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
