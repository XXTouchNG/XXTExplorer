//
//  XUIListHeaderView.m
//  XXTExplorer
//
//  Created by Zheng on 2017/7/21.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XUIListHeaderView.h"
#import <Masonry/Masonry.h>

@interface XUIListHeaderView ()

@end

@implementation XUIListHeaderView

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {
    [super updateConstraints];
}

- (void)makeConstraints {
    [self.headerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(20);
        make.trailing.equalTo(self).offset(-20);
        make.top.equalTo(self).offset(40);
    }];
    [self.subheaderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headerLabel);
        make.trailing.equalTo(self.headerLabel);
        make.top.equalTo(self.headerLabel.mas_bottom).offset(12);
    }];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.leading.trailing.top.equalTo(self.superview);
        make.bottom.equalTo(self.subheaderLabel.mas_bottom).offset(20);
    }];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self addSubview:self.headerLabel];
    [self addSubview:self.subheaderLabel];
    [self makeConstraints];
}

#pragma mark - UIView Getters

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20.f, self.bounds.size.width, 80.f)];
        headerLabel.backgroundColor = UIColor.clearColor;
        headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45.f];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.numberOfLines = 1;
        headerLabel.lineBreakMode = NSLineBreakByClipping;
        _headerLabel = headerLabel;
    }
    return _headerLabel;
}

- (UILabel *)subheaderLabel {
    if (!_subheaderLabel) {
        UILabel *subheaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20.f + 80.f + 12.f, self.bounds.size.width, 24.f)];
        subheaderLabel.backgroundColor = UIColor.clearColor;
        subheaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:18.f];
        subheaderLabel.textAlignment = NSTextAlignmentCenter;
        subheaderLabel.numberOfLines = 0;
        subheaderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _subheaderLabel = subheaderLabel;
    }
    return _subheaderLabel;
}

@end
