//
//  RMCloudExpandableCell.m
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudExpandableCell.h"

@interface RMCloudExpandableCell ()

@end

@implementation RMCloudExpandableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.titleTextLabel.text = @"";
    self.titleTextLabel.textColor = XXTColorPlainTitleText();
    self.valueTextLabel.text = @"";
    self.valueTextLabel.textColor = XXTColorPlainSubtitleText();
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

@end
