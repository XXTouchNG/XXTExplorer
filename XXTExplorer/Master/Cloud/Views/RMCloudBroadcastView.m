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
@property (nonatomic, strong) UIButton *closeButton;

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
    [self addSubview:self.closeButton];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidTapped:)];
    [self addGestureRecognizer:gesture];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _scrollView.frame = CGRectMake(8.0, 0.0, CGRectGetWidth(self.bounds) - 34.0, CGRectGetHeight(self.bounds));
    _closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 24.0, 4.0, 18.0, 18.0);
}

- (void)reloadScrollViewWithText:(NSString *)text {
    self.scrollView.text = text;
}

- (void)scrollViewDidTapped:(UITapGestureRecognizer *)sender {
    if ([_delegate respondsToSelector:@selector(broadcastViewDidTapped:)]) {
        [_delegate broadcastViewDidTapped:self];
    }
}

- (void)closeButtonTapped:(UIButton *)sender {
    if ([_delegate respondsToSelector:@selector(broadcastViewDidClosed:)]) {
        [_delegate broadcastViewDidClosed:self];
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

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton setImage:[UIImage imageNamed:@"RMCloudRSSClose"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
