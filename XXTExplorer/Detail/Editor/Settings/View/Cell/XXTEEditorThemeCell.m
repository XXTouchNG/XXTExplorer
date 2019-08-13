//
//  XXTEEditorThemeCell.m
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorThemeCell.h"
#import "UIImage+ColoredImage.h"

@interface XXTEEditorThemeCell ()

@end

@implementation XXTEEditorThemeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.tintColor = XXTColorForeground();
    
    UIImageView *imageView = self.previewImageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [UIColor clearColor];
    self.selectedBackgroundView = selectionBackground;
    
    if (XXTE_IS_IPHONE_6_BELOW) {
        self.titleLabel.font = [UIFont systemFontOfSize:14.0];
    }
    else {
        self.titleLabel.font = [UIFont systemFontOfSize:20.0];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *backgroundColor = self.titleBaseView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    self.titleBaseView.backgroundColor = backgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.titleBaseView.backgroundColor;
    [super setSelected:selected animated:animated];
    self.titleBaseView.backgroundColor = backgroundColor;
}

@end
