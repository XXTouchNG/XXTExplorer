//
//  XXTExplorerHeaderView.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerHeaderView.h"
#import "XXTEInsetsLabel.h"

@implementation XXTExplorerHeaderView

@synthesize headerLabel = _headerLabel, activityIndicator = _activityIndicator;

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup {
//    self.backgroundColor = [UIColor clearColor];
    UIView *containerView = [[UIView alloc] initWithFrame:self.bounds];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    containerView.backgroundColor = XXTColorPlainSectionHeader();
    
    [containerView addSubview:self.headerLabel];
    [containerView addSubview:self.activityIndicator];
    [self addSubview:containerView];
    
    {
        self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addConstraints:
  @[
    [NSLayoutConstraint constraintWithItem:self.headerLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.headerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.headerLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.headerLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:3.0],
    [NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-12.0],
    [NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:18.0],
    [NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:18.0],
    ]];
    }
}

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        XXTEInsetsLabel *textLabel = [[XXTEInsetsLabel alloc] initWithFrame:self.contentView.bounds];
        textLabel.textColor = XXTColorPlainSectionHeaderText();
        textLabel.font = [UIFont italicSystemFontOfSize:14.f];
        textLabel.edgeInsets = UIEdgeInsetsMake(0, 12.f, 0, 12.f);
        textLabel.numberOfLines = 1;
        textLabel.lineBreakMode = NSLineBreakByTruncatingHead;
        _headerLabel = textLabel;
    }
    return _headerLabel;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - 30.0, 3.0, 18.0, 18.0)];
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        activityIndicator.color = XXTColorForeground();
        activityIndicator.tintColor = XXTColorForeground();
        activityIndicator.hidesWhenStopped = YES;
        _activityIndicator = activityIndicator;
    }
    return _activityIndicator;
}

@end
