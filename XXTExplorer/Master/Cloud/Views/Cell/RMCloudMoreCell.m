//
//  RMCloudMoreCell.m
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudMoreCell.h"

@interface RMCloudMoreCell ()

@property (weak, nonatomic) IBOutlet UIButton *tapTitleButton;

@end

@implementation RMCloudMoreCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
    
    UIButton *btn = self.tapTitleButton;
    [btn setTitle:NSLocalizedString(@"More...", nil) forState:UIControlStateNormal];
    [btn setTitleColor:XXTColorForeground() forState:UIControlStateNormal];
    
    [btn.layer setCornerRadius:(CGRectGetHeight(btn.bounds) / 2.0)];
    [btn.layer setBorderWidth:0.6];
    [btn.layer setBorderColor:XXTColorForeground().CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
