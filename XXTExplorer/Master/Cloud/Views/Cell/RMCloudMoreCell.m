//
//  RMCloudMoreCell.m
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudMoreCell.h"

@interface RMCloudMoreCell ()

@property (weak, nonatomic) IBOutlet UILabel *tapTitleLabel;

@end

@implementation RMCloudMoreCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.tapTitleLabel.textColor = XXTColorDefault();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
    
    self.tapTitleLabel.text = NSLocalizedString(@"Tap to load more...", nil);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
