//
//  RMCloudProjectCell.m
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudProjectCell.h"
#import <YYWebImage/YYWebImage.h>

@interface RMCloudProjectCell ()

@end

@implementation RMCloudProjectCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTE_COLOR colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
    
    self.titleTextLabel.text = NSLocalizedString(@"Untitled", nil);
    self.descriptionTextLabel.text = NSLocalizedString(@"No description.", nil);
    
    UIButton *downloadBtn = self.downloadButton;
    downloadBtn.layer.borderColor = XXTE_COLOR.CGColor;
    downloadBtn.layer.borderWidth = .5f;
    downloadBtn.layer.cornerRadius = 14.f;
    
    downloadBtn.showsTouchWhenHighlighted = YES;
    [downloadBtn setTitle:NSLocalizedString(@"Download", nil) forState:UIControlStateNormal];
    
    [downloadBtn addTarget:self action:@selector(downloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters

- (void)setProject:(RMProject *)project {
    _project = project;
    self.titleTextLabel.text = project.projectName;
    if (project.projectRemark.length > 0) {
        self.descriptionTextLabel.text = project.projectRemark;
    } else {
        self.descriptionTextLabel.text = NSLocalizedString(@"No description.", nil);
    }
    NSURL *imageURL = [NSURL URLWithString:project.projectLogo];
    if (imageURL) {
        [self.iconImageView yy_setImageWithURL:imageURL options:YYWebImageOptionProgressive | YYWebImageOptionShowNetworkActivity];
    }
}

#pragma mark - Actions

- (void)downloadButtonTapped:(UIButton *)sender {
    if ([_delegate respondsToSelector:@selector(projectCell:downloadButtonTapped:)]) {
        [_delegate projectCell:self downloadButtonTapped:sender];
    }
}

@end
