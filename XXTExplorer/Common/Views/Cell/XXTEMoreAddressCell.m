//
//  XXTEMoreAddressCell.m
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreAddressCell.h"

@interface XXTEMoreAddressCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *guideWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightConstraint;

@end

@implementation XXTEMoreAddressCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTE_COLOR colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
    
    if (XXTE_IS_IPHONE_6_BELOW) {
        self.guideWidthConstraint.constant = 0.0;
        self.rightConstraint.constant = 0.0;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    XXTEAutoLabel *label = self.addressLabel;
    CGFloat boundsWidth = CGRectGetWidth(label.bounds);
    if (label.preferredMaxLayoutWidth != boundsWidth) {
        label.preferredMaxLayoutWidth = boundsWidth;
        [label setNeedsUpdateConstraints];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
