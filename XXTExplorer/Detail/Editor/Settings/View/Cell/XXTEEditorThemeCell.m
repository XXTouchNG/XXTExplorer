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
    // Initialization code
    
    UIImageView *imageView = self.previewImageView;
    imageView.layer.masksToBounds = YES;
    imageView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    imageView.layer.borderWidth = 1.f;
    imageView.layer.cornerRadius = 8.f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
