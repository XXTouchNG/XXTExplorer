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

+ (NSDateFormatter *)sharedFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
            [formatter setDateFormat:@"yyyy-MM-dd"];
        }
    });
    return formatter;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTColorDefault() colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
    
    self.titleTextLabel.text = NSLocalizedString(@"Untitled", nil);
    self.descriptionTextLabel.text = NSLocalizedString(@"No description.", nil);
    
    UIButton *downloadBtn = self.downloadButton;
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
    self.descriptionTextLabel.text = [NSString stringWithFormat:@"v%.2f | %@ | %@", project.projectVersion, [[[self class] sharedFormatter] stringFromDate:project.createdAtNSDate], project.authorName];
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
