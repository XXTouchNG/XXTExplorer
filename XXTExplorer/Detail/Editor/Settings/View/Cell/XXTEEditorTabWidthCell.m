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
    
    if (@available(iOS 13.0, *)) {
        self.titleLabel.textColor = [UIColor labelColor];
    } else {
        self.titleLabel.textColor = [UIColor blackColor];
    }
    self.segmentedControl.tintColor = XXTColorForeground();
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
