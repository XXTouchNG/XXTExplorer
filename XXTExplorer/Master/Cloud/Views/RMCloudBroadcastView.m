//
//  RMCloudBroadcastView.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/11.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "RMCloudBroadcastView.h"
#import <MarqueeLabel/MarqueeLabel.h>

@interface RMCloudBroadcastView ()
@property (nonatomic, strong) MarqueeLabel *scrollView;

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
    self.backgroundColor = XXTE_COLOR_SUCCESS;
    [self addSubview:self.scrollView];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidTapped:)];
    [self addGestureRecognizer:gesture];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _scrollView.frame = CGRectMake(8.0, 0.0, CGRectGetWidth(self.bounds) - 16.0, CGRectGetHeight(self.bounds));
}

- (void)reloadScrollViewWithText:(NSString *)text {
    self.scrollView.text = text;
}

- (void)scrollViewDidTapped:(UITapGestureRecognizer *)sender {
    if ([_delegate respondsToSelector:@selector(broadcastViewDidTapped:)]) {
        [_delegate broadcastViewDidTapped:self];
    }
}

- (MarqueeLabel *)scrollView {
    if (!_scrollView) {
        MarqueeLabel *scrollView = [[MarqueeLabel alloc] init];
        [scrollView setRate:20.0];
        [scrollView setFadeLength:16.0];
        [scrollView setBackgroundColor:[UIColor clearColor]];
        [scrollView setFont:[UIFont systemFontOfSize:12.0]];
        [scrollView setTextColor:[UIColor whiteColor]];
        [scrollView setTextAlignment:NSTextAlignmentLeft];
        _scrollView = scrollView;
    }
    return _scrollView;
}

@end
