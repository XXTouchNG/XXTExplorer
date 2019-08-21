//
//  XXTEEditorTabWidthCell.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTabWidthCell.h"

@implementation XXTEEditorTabWidthCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.textColor = XXTColorPlainTitleText();
    self.segmentedControl.tintColor = XXTColorForeground();
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
