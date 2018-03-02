//
//  XXTExplorerItemNameCell.m
//  XXTExplorer
//
//  Created by Zheng on 10/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerItemNameCell.h"

@interface XXTExplorerItemNameCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *guideWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightConstraint;

@end

@implementation XXTExplorerItemNameCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    if (XXTE_IS_IPHONE_6_BELOW) {
        self.guideWidthConstraint.constant = 0.0;
        self.rightConstraint.constant = 0.0;
    }
    
    self.nameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
