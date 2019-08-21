//
//  XXTPixelPlaceholderView.m
//  XXTouchApp
//
//  Created by Zheng on 10/10/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTPixelPlaceholderView.h"
#import "XXTPickerFactory.h"

@interface XXTPixelPlaceholderView ()
@property (nonatomic, strong) UIView *holderContentView;
@property (nonatomic, strong) NSArray *holderConstraints;

@end

@implementation XXTPixelPlaceholderView

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

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)updateConstraints {
    [super updateConstraints];
    if (self.holderConstraints) {
        [self removeConstraints:self.holderConstraints];
    }
    self.holderConstraints = @[
            [NSLayoutConstraint constraintWithItem:self
                                         attribute:NSLayoutAttributeCenterX
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.holderContentView
                                         attribute:NSLayoutAttributeCenterX
                                        multiplier:1
                                          constant:0],
            [NSLayoutConstraint constraintWithItem:self
                                         attribute:NSLayoutAttributeCenterY
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.holderContentView
                                         attribute:NSLayoutAttributeCenterY
                                        multiplier:1
                                          constant:0],
            [NSLayoutConstraint constraintWithItem:self.holderContentView
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1
                                          constant:123.f],
            [NSLayoutConstraint constraintWithItem:self.holderContentView
                                         attribute:NSLayoutAttributeHeight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                         attribute:NSLayoutAttributeNotAnAttribute
                                        multiplier:1
                                          constant:180.f],
    ];
    [self addConstraints:self.holderConstraints];
}

- (void)setup {
    self.backgroundColor = XXTColorPlainBackground();

    UIImage *tintedImage = [UIImage imageNamed:@"xxt-marquee"];
    UIImageView *centerAddImage = [[UIImageView alloc] initWithImage:tintedImage];
    centerAddImage.frame = CGRectMake(0, 0, tintedImage.size.width, tintedImage.size.height);

    UILabel *centerAddLabel = [[UILabel alloc] init];
    centerAddLabel.textColor = [UIColor colorWithWhite:0.8f alpha:1.f];
    centerAddLabel.font = [UIFont systemFontOfSize:12.f];
    centerAddLabel.textAlignment = NSTextAlignmentCenter;
    centerAddLabel.numberOfLines = 2;
    centerAddLabel.lineBreakMode = NSLineBreakByWordWrapping;
    centerAddLabel.text = NSLocalizedString(@"No image\nTap here to add", nil);
    [centerAddLabel sizeToFit];

    centerAddLabel.center = CGPointMake(centerAddImage.bounds.size.width / 2, centerAddImage.bounds.size.height + 20.f + centerAddLabel.bounds.size.height / 2);

    UIView *holderContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tintedImage.size.width, tintedImage.size.height + 20.f + centerAddLabel.bounds.size.height)];

    [holderContentView addSubview:centerAddImage];
    [holderContentView addSubview:centerAddLabel];

    holderContentView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    holderContentView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:holderContentView];
    self.holderContentView = holderContentView;
}

@end
