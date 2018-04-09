//
//  XXTEMoreTextFieldCell.m
//  XXTExplorer
//
//  Created by Zheng on 03/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreTextFieldCell.h"

@implementation XXTEMoreTextFieldCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.textColor = [UIColor blackColor];
    self.valueField.textColor = [UIColor blackColor];
    self.valueField.tintColor = XXTColorDefault();
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
