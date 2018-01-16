//
//  RMCloudProjectDetailCell.m
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudProjectDetailCell.h"
#import <YYWebImage/YYWebImage.h>

@interface RMCloudProjectDetailCell ()

@end

@implementation RMCloudProjectDetailCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.iconImageView.image = nil;
    self.titleTextLabel.text = @"";
    self.descriptionTextLabel.text = @"";
    
    UIImageView *iconImageView = self.iconImageView;
    iconImageView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.1].CGColor;
    iconImageView.layer.borderWidth = .5f;
    iconImageView.layer.cornerRadius = 18.f;
    
    UIButton *downloadBtn = self.downloadButton;
    downloadBtn.layer.borderColor = XXTE_COLOR.CGColor;
    downloadBtn.layer.borderWidth = .5f;
    downloadBtn.layer.cornerRadius = 14.f;
    
    downloadBtn.showsTouchWhenHighlighted = YES;
    [downloadBtn setTitle:NSLocalizedString(@"Download", nil) forState:UIControlStateNormal];
    [downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [downloadBtn setBackgroundColor:XXTE_COLOR];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters

- (void)setProject:(RMProject *)project {
    _project = project;
    self.titleTextLabel.text = project.projectName;
    NSMutableString *descriptionString = [[NSMutableString alloc] init];
    [descriptionString appendFormat:NSLocalizedString(@"Version: v%.2f", nil), project.projectVersion];
    [descriptionString appendString:@"\n"];
    self.descriptionTextLabel.text = [descriptionString copy];
    NSURL *imageURL = [NSURL URLWithString:project.projectLogo];
    if (imageURL) {
        [self.iconImageView yy_setImageWithURL:imageURL options:YYWebImageOptionProgressive | YYWebImageOptionShowNetworkActivity];
    }
}

@end
