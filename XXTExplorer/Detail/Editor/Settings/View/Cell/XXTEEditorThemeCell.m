//
//  XXTEEditorThemeCell.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorThemeCell.h"

@implementation XXTEEditorThemeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.tintColor = XXTColorDefault();
    
    UIImageView *imageView = self.previewImageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTColorDefault() colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
