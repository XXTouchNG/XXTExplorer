//
//  XXTEMoreTitleValueCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreTitleValueCell.h"

@implementation XXTEMoreTitleValueCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.valueLabel.preferredMaxLayoutWidth = self.valueLabel.bounds.size.width;
}

@end
