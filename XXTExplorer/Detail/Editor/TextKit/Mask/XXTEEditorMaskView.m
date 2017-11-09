//
//  XXTEEditorMaskView.m
//  XXTExplorer
//
//  Created by Zheng on 2017/11/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEEditorMaskView.h"

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

- (void)highlightWithRange:(NSRange)range {
    [self highlightWithRange:range duration:2.0];
}

- (void)highlightWithRange:(NSRange)range duration:(NSTimeInterval)duration
{
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
    
    CGPoint textViewOrigin = textView.frame.origin;
    textRect.origin.x += (textViewOrigin.x / 2.0) + textView.textContainerInset.left;
    textRect.origin.y += (textViewOrigin.y / 2.0) + textView.textContainerInset.top;
    
    CALayer *highlightLayer = [CALayer layer];
    [highlightLayer setFrame:textRect];
    [highlightLayer setCornerRadius:6.0f];
    [highlightLayer setBackgroundColor:[self.maskColor CGColor]];
    [highlightLayer setOpacity:0.66f];
    [highlightLayer setShadowColor:[[UIColor blackColor] CGColor]];
    [highlightLayer setShadowOffset:CGSizeMake(6.0f, 6.0f)];
    [highlightLayer setShadowOpacity:0.44f];
    [highlightLayer setShadowRadius:12.0f];
    [[textView layer] addSublayer:highlightLayer];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [highlightLayer setHidden:YES];
        [highlightLayer removeAllAnimations];
        [highlightLayer removeFromSuperlayer];
    }];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = duration;
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.additive = NO;
    animation.autoreverses = NO;
    [highlightLayer addAnimation:animation forKey:@"opacityOUT"];
    [CATransaction commit];
    
    [textView scrollRectToVisible:centeredRect animated:YES];
}

@end
