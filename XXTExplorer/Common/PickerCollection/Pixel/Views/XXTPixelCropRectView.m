//
//  XXTPixelCropRectView.m
//  XXTouchApp
//

#import "XXTPixelCropRectView.h"
#import "XXTPixelResizeControl.h"
#import "XXTPickerFactory.h"

@interface XXTPixelCropRectView () <XXTPixelResizeControlViewDelegate>

@property(nonatomic) XXTPixelResizeControl *topLeftCornerView;
@property(nonatomic) XXTPixelResizeControl *topRightCornerView;
@property(nonatomic) XXTPixelResizeControl *bottomLeftCornerView;
@property(nonatomic) XXTPixelResizeControl *bottomRightCornerView;

@property(nonatomic) CGRect initialRect;
@property(nonatomic) CGFloat fixedAspectRatio;

@end

@implementation XXTPixelCropRectView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;

        self.showsGridMajor = YES;
        self.showsGridMinor = NO;

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, -2.0f, -2.0f)];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.image = [[UIImage imageNamed:@"xxt-picker-border"] resizableImageWithCapInsets:UIEdgeInsetsMake(23.0f, 23.0f, 23.0f, 23.0f)];
        [self addSubview:imageView];

        self.topLeftCornerView = [[XXTPixelResizeControl alloc] init];
        self.topLeftCornerView.delegate = self;
        [self addSubview:self.topLeftCornerView];

        self.topRightCornerView = [[XXTPixelResizeControl alloc] init];
        self.topRightCornerView.delegate = self;
        [self addSubview:self.topRightCornerView];

        self.bottomLeftCornerView = [[XXTPixelResizeControl alloc] init];
        self.bottomLeftCornerView.delegate = self;
        [self addSubview:self.bottomLeftCornerView];

        self.bottomRightCornerView = [[XXTPixelResizeControl alloc] init];
        self.bottomRightCornerView.delegate = self;
        [self addSubview:self.bottomRightCornerView];
    }

    return self;
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSArray *subviews = self.subviews;
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[XXTPixelResizeControl class]]) {
            if (CGRectContainsPoint(subview.frame, point)) {
                return subview;
            }
        }
    }

    return nil;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);

    for (NSInteger i = 0; i < 3; i++) {
        CGFloat borderPadding = 2.0f;

        if (self.showsGridMinor) {
            for (NSInteger j = 1; j < 3; j++) {
                [[UIColor colorWithRed:1.0f green:1.0f blue:0.0f alpha:0.3f] set];

                UIRectFill(CGRectMake(roundf(width / 3 / 3 * j + width / 3 * i), borderPadding, 1.0f, roundf(height) - borderPadding * 2));
                UIRectFill(CGRectMake(borderPadding, roundf(height / 3 / 3 * j + height / 3 * i), roundf(width) - borderPadding * 2, 1.0f));
            }
        }

        if (self.showsGridMajor) {
            if (i > 0) {
                [[UIColor whiteColor] set];

                UIRectFill(CGRectMake(roundf(width / 3 * i), borderPadding, 1.0f, roundf(height) - borderPadding * 2));
                UIRectFill(CGRectMake(borderPadding, roundf(height / 3 * i), roundf(width) - borderPadding * 2, 1.0f));
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.topLeftCornerView.frame = (CGRect) {CGRectGetWidth(self.topLeftCornerView.bounds) / -2, CGRectGetHeight(self.topLeftCornerView.bounds) / -2, self.topLeftCornerView.bounds.size};
    self.topRightCornerView.frame = (CGRect) {CGRectGetWidth(self.bounds) - CGRectGetWidth(self.topRightCornerView.bounds) / 2, CGRectGetHeight(self.topRightCornerView.bounds) / -2, self.topLeftCornerView.bounds.size};
    self.bottomLeftCornerView.frame = (CGRect) {CGRectGetWidth(self.bottomLeftCornerView.bounds) / -2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.bottomLeftCornerView.bounds) / 2, self.bottomLeftCornerView.bounds.size};
    self.bottomRightCornerView.frame = (CGRect) {CGRectGetWidth(self.bounds) - CGRectGetWidth(self.bottomRightCornerView.bounds) / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.bottomRightCornerView.bounds) / 2, self.bottomRightCornerView.bounds.size};
}

#pragma mark -

- (void)setShowsGridMajor:(BOOL)showsGridMajor {
    _showsGridMajor = showsGridMajor;
    [self setNeedsDisplay];
}

- (void)setShowsGridMinor:(BOOL)showsGridMinor {
    _showsGridMinor = showsGridMinor;
    [self setNeedsDisplay];
}

- (void)setKeepingAspectRatio:(BOOL)keepingAspectRatio {
    _keepingAspectRatio = keepingAspectRatio;

    if (self.keepingAspectRatio) {
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat height = CGRectGetHeight(self.bounds);
        self.fixedAspectRatio = fminf(width / height, height / width);
    }
}

#pragma mark -

- (void)resizeControlViewDidBeginResizing:(XXTPixelResizeControl *)resizeControlView {
    self.initialRect = self.frame;

    if (resizeControlView == self.topLeftCornerView) {
        _resizeControlPosition = kXXTResizeControlPositionTopLeft;
    } else if (resizeControlView == self.topRightCornerView) {
        _resizeControlPosition = kXXTResizeControlPositionTopRight;
    } else if (resizeControlView == self.bottomLeftCornerView) {
        _resizeControlPosition = kXXTResizeControlPositionBottomLeft;
    } else if (resizeControlView == self.bottomRightCornerView) {
        _resizeControlPosition = kXXTResizeControlPositionBottomRight;
    }

    if ([self.delegate respondsToSelector:@selector(cropRectViewDidBeginEditing:)]) {
        [self.delegate cropRectViewDidBeginEditing:self];
    }
}

- (void)resizeControlViewDidResize:(XXTPixelResizeControl *)resizeControlView {
    self.frame = [self cropRectMakeWithResizeControlView:resizeControlView];

    if ([self.delegate respondsToSelector:@selector(cropRectViewEditingChanged:)]) {
        [self.delegate cropRectViewEditingChanged:self];
    }
}

- (void)resizeControlViewDidEndResizing:(XXTPixelResizeControl *)resizeControlView {
    if ([self.delegate respondsToSelector:@selector(cropRectViewDidEndEditing:)]) {
        [self.delegate cropRectViewDidEndEditing:self];
    }
}

- (CGRect)cropRectMakeWithResizeControlView:(XXTPixelResizeControl *)resizeControlView {
    CGRect rect = self.frame;

    if (resizeControlView == self.topLeftCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);

        if (self.keepingAspectRatio) {
            CGRect constrainedRect;
            if (fabs(resizeControlView.translation.x) < fabs(resizeControlView.translation.y)) {
                constrainedRect = [self constrainedRectWithRectBasisOfHeight:rect aspectRatio:self.fixedAspectRatio];
            } else {
                constrainedRect = [self constrainedRectWithRectBasisOfWidth:rect aspectRatio:self.fixedAspectRatio];
            }
            constrainedRect.origin.x -= CGRectGetWidth(constrainedRect) - CGRectGetWidth(rect);
            constrainedRect.origin.y -= CGRectGetHeight(constrainedRect) - CGRectGetHeight(rect);
            rect = constrainedRect;
        }
    } else if (resizeControlView == self.topRightCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                CGRectGetMinY(self.initialRect) + resizeControlView.translation.y,
                CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                CGRectGetHeight(self.initialRect) - resizeControlView.translation.y);

        if (self.keepingAspectRatio) {
            if (fabs(resizeControlView.translation.x) < fabs(resizeControlView.translation.y)) {
                rect = [self constrainedRectWithRectBasisOfHeight:rect aspectRatio:self.fixedAspectRatio];
            } else {
                rect = [self constrainedRectWithRectBasisOfWidth:rect aspectRatio:self.fixedAspectRatio];
            }
        }
    } else if (resizeControlView == self.bottomLeftCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                CGRectGetMinY(self.initialRect),
                CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);

        if (self.keepingAspectRatio) {
            CGRect constrainedRect;
            if (fabs(resizeControlView.translation.x) < fabs(resizeControlView.translation.y)) {
                constrainedRect = [self constrainedRectWithRectBasisOfHeight:rect aspectRatio:self.fixedAspectRatio];
            } else {
                constrainedRect = [self constrainedRectWithRectBasisOfWidth:rect aspectRatio:self.fixedAspectRatio];
            }
            constrainedRect.origin.x -= CGRectGetWidth(constrainedRect) - CGRectGetWidth(rect);
            rect = constrainedRect;
        }
    } else if (resizeControlView == self.bottomRightCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                CGRectGetMinY(self.initialRect),
                CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                CGRectGetHeight(self.initialRect) + resizeControlView.translation.y);

        if (self.keepingAspectRatio) {
            if (fabs(resizeControlView.translation.x) < fabs(resizeControlView.translation.y)) {
                rect = [self constrainedRectWithRectBasisOfHeight:rect aspectRatio:self.fixedAspectRatio];
            } else {
                rect = [self constrainedRectWithRectBasisOfWidth:rect aspectRatio:self.fixedAspectRatio];
            }
        }
    }
    return rect;
}

- (CGRect)constrainedRectWithRectBasisOfWidth:(CGRect)rect aspectRatio:(CGFloat)aspectRatio {
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width < height) {
        height = width / self.fixedAspectRatio;
    } else {
        height = width * self.fixedAspectRatio;
    }
    rect.size = CGSizeMake(width, height);

    return rect;
}

- (CGRect)constrainedRectWithRectBasisOfHeight:(CGRect)rect aspectRatio:(CGFloat)aspectRatio {
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width < height) {
        width = height * self.fixedAspectRatio;
    } else {
        width = height / self.fixedAspectRatio;
    }
    rect.size = CGSizeMake(width, height);

    return rect;
}

@end
