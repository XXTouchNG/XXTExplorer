//
//  RMCloudBroadcastView.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/11.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "RMCloudBroadcastView.h"
#import <TXScrollLabelView/TXScrollLabelView.h>

@interface RMCloudBroadcastView () <UIScrollViewDelegate>
@property (nonatomic, strong) TXScrollLabelView *scrollView;

@end

@implementation RMCloudBroadcastView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.scrollView];
    [self.scrollView beginScrolling];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
}

#pragma mark - UIView Getters

- (TXScrollLabelView *)scrollView {
    if (!_scrollView) {
        
    }
    return _scrollView;
}

@end
