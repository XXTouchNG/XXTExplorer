//
//  XXTPickerPreviewBar.m
//  XXTPickerCollection
//
//  Created by Zheng on 29/04/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerPreviewBar.h"
#import "XXTPickerFactory.h"
#import "XXTPickerDefine.h"

@interface XXTPickerPreviewBar ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation XXTPickerPreviewBar

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

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, self.frame.size.width, 18)];
        titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 1;
        titleLabel.text = NSLocalizedString(@"N/A", nil);
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, self.frame.size.width, 18)];
        subtitleLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:12.f];
        subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.numberOfLines = 1;
        subtitleLabel.text = NSLocalizedString(@"N/A", nil);
        _subtitleLabel = subtitleLabel;
    }
    return _subtitleLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 2.f, self.frame.size.width, 1.f)];
        progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        progressView.progressTintColor = XXTColorDefault();
        progressView.progressViewStyle = UIProgressViewStyleBar;
        _progressView = progressView;
    }
    return _progressView;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    [self setBackgroundColor:[UIColor colorWithWhite:1.f alpha:.75f]];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subtitleLabel];
    [self addSubview:self.progressView];
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}

- (void)setAttributedSubtitle:(NSAttributedString *)subtitle {
    self.subtitleLabel.attributedText = subtitle;
}

- (void)setProgress:(float)progress {
    self.progressView.progress = progress;
}

@end
