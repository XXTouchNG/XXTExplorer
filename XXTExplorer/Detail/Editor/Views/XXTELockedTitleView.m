//
//  XXTELockedTitleView.m
//  XXTExplorer
//
//  Created by Darwin on 7/31/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTELockedTitleView.h"

@interface XXTELockedTitleView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lockImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lockWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subtitleLabelHeight;

@end

@implementation XXTELockedTitleView

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = subtitle;
    self.subtitleLabel.text = subtitle;
}

- (void)setLocked:(BOOL)locked {
    _locked = locked;
    if (locked) {
        self.lockWidth.constant = 15.0;
    } else {
        self.lockWidth.constant = 0.0;
    }
}

- (void)setSimple:(BOOL)simple {
    _simple = simple;
    if (simple) {
        self.subtitleLabelHeight.constant = 0.0;
        self.subtitleLabel.text = @"";
    } else {
        self.subtitleLabelHeight.constant = 10.0;
        self.subtitleLabel.text = self.subtitle;
    }
    [self updateConstraintsIfNeeded];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    self.titleLabel.textColor = tintColor;
    self.subtitleLabel.textColor = tintColor;
}

@end
