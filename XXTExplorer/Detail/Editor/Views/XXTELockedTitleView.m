//
//  XXTELockedTitleView.m
//  XXTExplorer
//
//  Created by Darwin on 7/31/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTELockedTitleView.h"

@interface XXTELockedTitleView ()


@end

@implementation XXTELockedTitleView

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setLocked:(BOOL)locked {
    _locked = locked;
    if (locked) {
        self.lockWidth.constant = 15.0;
    } else {
        self.lockWidth.constant = 0.0;
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    self.titleLabel.textColor = tintColor;
}

@end
