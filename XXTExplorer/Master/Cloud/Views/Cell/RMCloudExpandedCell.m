//
//  RMCloudExpandedCell.m
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudExpandedCell.h"

@interface RMCloudExpandedCell ()

@end

@implementation RMCloudExpandedCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.titleTextLabel.text = @"";
    self.titleTextLabel.textColor = XXTColorPlainSubtitleText();
    self.valueTextLabel.text = @"";
    self.valueTextLabel.textColor = XXTColorPlainTitleText();
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
