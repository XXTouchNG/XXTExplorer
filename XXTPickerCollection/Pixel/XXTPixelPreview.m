//
//  XXTPixelPreview.m
//  XXTouchApp
//
//  Created by Zheng on 13/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTPixelPreview.h"
#import "XXTPixelImage.h"
#import "XXTPixelPreviewRootViewController.h"

@interface XXTPixelPreview ()
@property (strong, nonatomic) XXTPixelImage *pixelImage;
@property (assign, nonatomic) CGSize pixelSize;
@property (assign, nonatomic) int hPixelNum;
@property (assign, nonatomic) int vPixelNum;
@property (strong, nonatomic) UIView *maskCenterView;
@property (nonatomic, assign, readonly) BOOL animating;

@end

@implementation XXTPixelPreview

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.pixelSize = CGSizeMake(10, 10);
    self.hPixelNum = (int)(frame.size.width / self.pixelSize.width);
    self.vPixelNum = (int)(frame.size.height / self.pixelSize.height);
    self.maskCenterView.frame = CGRectMake(self.hPixelNum / 2 * self.pixelSize.width, self.vPixelNum / 2 * self.pixelSize.height, self.pixelSize.width, self.pixelSize.height);
}

- (void)setup {
    self.frame = CGRectZero;
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [[UIColor blackColor] CGColor];
    self.windowLevel = UIWindowLevelAlert;
    self.rootViewController = [XXTPixelPreviewRootViewController new];
    
    self.frame = self.frame;
    _animating = NO;
    [self addSubview:self.maskCenterView];
}

- (void)makeKeyAndVisible {
    [super makeKeyAndVisible];
    _animating = YES;
    [self shakeAnimation];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    _animating = NO;
}

- (void)shakeAnimation {
    if (_animating) {
        [UIView animateWithDuration:.6f animations:^{
            self.maskCenterView.alpha = 1.f;
        }];
        [UIView animateWithDuration:.6f animations:^{
            self.maskCenterView.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self shakeAnimation];
        }];
    }
}

- (UIView *)maskCenterView {
    if (!_maskCenterView) {
        _maskCenterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.pixelSize.width, self.pixelSize.height)];
        _maskCenterView.backgroundColor = [UIColor colorWithWhite:1.f alpha:.95f];
        _maskCenterView.alpha = 0.f;
    }
    return _maskCenterView;
}

- (void)setImageToMagnify:(UIImage *)imageToMagnify {
    _imageToMagnify = imageToMagnify;
    if (!imageToMagnify) {
        _pixelImage = nil;
        return;
    }
    _pixelImage = [[XXTPixelImage alloc] initWithUIImage:imageToMagnify];
}

- (void)setPointToMagnify:(CGPoint)pointToMagnify {
    _pointToMagnify = pointToMagnify;
    _colorOfLastPoint = [self getColorOfPoint:pointToMagnify];
    [self setNeedsDisplay];
}

- (UIColor *)getColorOfPoint:(CGPoint)p {
    XXTPixelColor *c = [_pixelImage getColorOfPoint:p];
    return [c getUIColor];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(ctx, kCGLineCapSquare);
    
    CGContextSetLineWidth(ctx, 1);
    
    int hNum = (int)(_hPixelNum / 2);
    int vNum = (int)(_vPixelNum / 2);
    CGPoint p = _pointToMagnify;
    CGSize s = _pixelSize;
    CGSize m = self.imageToMagnify.size;
    for (int i = 0; i < hNum * 2; i++) {
        for (int j = 0; j < vNum * 2; j++) {
            CGPoint t = CGPointMake(p.x - hNum + i, p.y - vNum + j);
            if (t.x < 0 || t.y < 0 || t.x > m.width || t.y > m.height) {
                CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
            } else {
                XXTPixelColor *c = [_pixelImage getColorOfPoint:t];
                if (!c) {
                    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
                } else {
                    CGContextSetFillColorWithColor(ctx, [c getUIColor].CGColor);
                }
            }
            if (CGPointEqualToPoint(t, p)) {
                CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 1.0);
            } else {
                CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
            }
            
            CGContextAddRect(ctx, CGRectMake(i * s.width, j * s.height, s.width, s.height));
            CGContextDrawPath(ctx, kCGPathFillStroke);
        }
    }
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    ((XXTPixelPreviewRootViewController *)self.rootViewController).statusBarHidden = statusBarHidden;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTPixelPreview dealloc]");
#endif
}

@end
