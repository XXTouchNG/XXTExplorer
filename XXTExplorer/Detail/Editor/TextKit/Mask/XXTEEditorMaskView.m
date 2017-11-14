//
//  XXTEEditorMaskView.m
//  XXTExplorer
//
//  Created by Zheng on 2017/11/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEEditorMaskView.h"
#import <QuartzCore/QuartzCore.h>

@implementation XXTEEditorMaskView

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTextView:(UITextView *)textView {
    self = [super initWithFrame:textView.frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _maskColor = [UIColor blueColor];
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#pragma mark - Touch Events

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO; // do not respond to any touch event
}

- (void)flashWithRange:(NSRange)range {
    UITextView *textView = self.textView;
    if (!textView || [textView isFirstResponder]) return;
    
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    if (!start) return;
    
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    if (!end) return;
    
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    if (!textRange) return;
    
    CGRect rect = [textView firstRectForRange:textRange];
    CGRect visibleRect = [textView convertRect:rect fromView:textView.textInputView];
    CGFloat centeredX = MAX(0, visibleRect.origin.x + visibleRect.size.width / 2.0 - CGRectGetWidth(textView.bounds) / 2.0);
    CGFloat centeredY = MAX(0, visibleRect.origin.y + visibleRect.size.height / 2.0 - CGRectGetHeight(textView.bounds) / 2.0);
    CGRect centeredRect = CGRectMake(centeredX, centeredY, CGRectGetWidth(textView.bounds), CGRectGetHeight(textView.bounds));
    
    NSLayoutManager *manager = textView.layoutManager;
    NSRange glyphRange = [manager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    CGRect textRect = [manager boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
    
    UIEdgeInsets textInsets = UIEdgeInsetsMake(1.8, 4.0, 2.0, 4.0);
    CGPoint textViewOrigin = textView.frame.origin;
    textRect.origin.x += (textViewOrigin.x / 2.0) + textView.textContainerInset.left - textInsets.left;
    textRect.origin.y += (textViewOrigin.y / 2.0) + textView.textContainerInset.top - textInsets.top;
    textRect.size.width += textInsets.left + textInsets.right;
    textRect.size.height += textInsets.top + textInsets.bottom;
    
    CALayer *highlightLayer = [CALayer layer];
    [highlightLayer setFrame:textRect];
    [highlightLayer setCornerRadius:8.0f];
    [highlightLayer setBackgroundColor:[self.maskColor CGColor]];
    [highlightLayer setOpacity:0.66f];
    [highlightLayer setBorderWidth:1.f];
    [highlightLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [highlightLayer setShadowColor:[[UIColor blackColor] CGColor]];
    [highlightLayer setShadowOffset:CGSizeZero];
    [highlightLayer setShadowOpacity:0.25f];
    [highlightLayer setShadowRadius:8.0f];
    [[textView layer] addSublayer:highlightLayer];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [highlightLayer setHidden:YES];
        [highlightLayer removeAllAnimations];
        [highlightLayer removeFromSuperlayer];
    }];
    
    // scale
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.beginTime = CACurrentMediaTime() + 0.4;
    scaleAnimation.duration = 0.2;
    scaleAnimation.repeatCount = 1;
    scaleAnimation.fromValue = [NSNumber numberWithFloat:2.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeBoth;
    scaleAnimation.additive = NO;
    scaleAnimation.autoreverses = NO;
    [highlightLayer addAnimation:scaleAnimation forKey:@"scaleOut"];
    
    // opacity out
    CABasicAnimation *opacityOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityOutAnimation.beginTime = CACurrentMediaTime() + 1.6;
    opacityOutAnimation.duration = 0.4;
    opacityOutAnimation.repeatCount = 1;
    opacityOutAnimation.fromValue = [NSNumber numberWithFloat:0.66f];
    opacityOutAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    opacityOutAnimation.removedOnCompletion = NO;
    opacityOutAnimation.fillMode = kCAFillModeBoth;
    opacityOutAnimation.additive = NO;
    opacityOutAnimation.autoreverses = NO;
    [highlightLayer addAnimation:opacityOutAnimation forKey:@"opacityOut"];
    
    [CATransaction commit];
    
    [textView scrollRectToVisible:centeredRect animated:YES];
}

@end
