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
    self.titleTextLabel.textColor = XXTColorPlainTitleText();
    self.descriptionTextLabel.text = @"";
    self.descriptionTextLabel.textColor = XXTColorPlainSubtitleText();
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    UIImageView *iconImageView = self.iconImageView;
    iconImageView.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.1].CGColor;
    iconImageView.layer.borderWidth = .5f;
    iconImageView.layer.cornerRadius = 18.f;
    iconImageView.layer.masksToBounds = YES;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.clipsToBounds = YES;
    
    UIButton *downloadBtn = self.downloadButton;
    downloadBtn.layer.masksToBounds = YES;
    downloadBtn.layer.cornerRadius = 14.f;
    
    downloadBtn.showsTouchWhenHighlighted = YES;
    [downloadBtn setTitle:NSLocalizedString(@"Download", nil) forState:UIControlStateNormal];
    [downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [downloadBtn setBackgroundColor:XXTColorBarTint()];
    
    if (XXTE_IS_IPHONE_6_BELOW || XXTE_IS_IPAD) {
        self.additionalArea.hidden = YES;
    } else {
        self.additionalArea.hidden = NO;
    }
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
    [descriptionString appendString:project.authorName];
    [descriptionString appendString:@"\n"];
    self.descriptionTextLabel.text = [descriptionString copy];
    NSURL *imageURL = [NSURL URLWithString:project.projectLogo];
    if (imageURL) {
        [self.iconImageView yy_setImageWithURL:imageURL options:YYWebImageOptionProgressive | YYWebImageOptionShowNetworkActivity];
    }
}

@end
