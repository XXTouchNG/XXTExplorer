//
//  XXTEMoreValueViewCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreValueViewCell.h"

@interface XXTEMoreValueViewCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *valueViewWidthConstraint;

@end

@implementation XXTEMoreValueViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat)valueViewWidth {
    return self.valueViewWidthConstraint.constant;
}

- (void)setValueViewWidth:(CGFloat)valueViewWidth {
    self.valueViewWidthConstraint.constant = valueViewWidth;
}

@end
