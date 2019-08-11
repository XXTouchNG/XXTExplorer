//
//  XXTEMoreRemoteSwitchCell.m
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreRemoteSwitchCell.h"

@interface XXTEMoreRemoteSwitchCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstraint;

@end

@implementation XXTEMoreRemoteSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    if (@available(iOS 13.0, *)) {
        self.iconImageView.tintColor = [UIColor labelColor];
    } else {
        self.iconImageView.tintColor = [UIColor blackColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
