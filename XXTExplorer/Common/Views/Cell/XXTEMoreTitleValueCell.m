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
    
    self.titleLabel.text = @"";
    self.valueLabel.text = @"";
    self.titleLabel.textColor = XXTColorPlainTitleText();
    self.valueLabel.textColor = XXTColorPlainSubtitleText();
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (UIColor *)detailTextColor {
    return [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0];
}

@end
