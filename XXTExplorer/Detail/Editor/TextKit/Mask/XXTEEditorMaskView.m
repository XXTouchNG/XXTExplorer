//
//  XXTEEditorMaskView.m
//  XXTExplorer
//
//  Created by Zheng on 2017/11/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEEditorMaskView.h"
#import "XXTETextPreprocessor.h"
#import "XXTEEditorLineMask.h"
#import "XXTEEditorTextView+TextRange.h"
#import "UIImage+ColoredImage.h"
#import <QuartzCore/QuartzCore.h>
#import "ICTextView.h"

static NSUInteger kXXTEEditorMaximumLineMaskCount = 100;


@interface XXTEEditorMaskView()
@property (nonatomic, strong) NSMutableArray <XXTEEditorLineMask *> *internalLineMasks;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, UIColor *> *internalLineMaskColors;

@end

@implementation XXTEEditorMaskView

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTextView:(XXTEEditorTextView *)textView {
    self = [super init];
    if (self) {
        _textView = textView;
        [self setup];
    }
    return self;
}

- (void)setup {
    _focusColor = XXTColorWarning();  // bright orange
    _flashColor = [UIColor colorWithRed:150.0f/255.0f green:200.0f/255.0f blue:1.0 alpha:1.0];  // light blue
    _internalLineMasks = [NSMutableArray array];
    _internalLineMaskColors = [NSMutableDictionary dictionary];
}

#pragma mark - Touch Events

- (ICTextHighlight *)textHighlightAtPoint:(CGPoint)targetPoint {
    // Search
    for (ICTextHighlight *textHighlight in self.textView.primaryHighlights) {
        UIView *hl = textHighlight.highlightView;
        CGRect hlRect = hl.frame;
        if (CGRectContainsPoint(hlRect, targetPoint)) {
            return textHighlight;
        }
    }
    for (ICTextHighlight *textHighlight in self.textView.secondaryHighlights) {
        UIView *hl = textHighlight.highlightView;
        CGRect hlRect = hl.frame;
        if (CGRectContainsPoint(hlRect, targetPoint)) {
            return textHighlight;
        }
    }
    return nil;
}  // O(c1 + c2), c1 ~ 10, c2 ~ 100, very fast

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL inside = NO;
    if (!inside) {
        inside = [self lineMaskAtPoint:point forComponentAtIndex:1] != nil;  // only in tagged area, O(c), c ~ 100
    }  // line mask at first
    if (!inside) {
        if (self.textView.searching) {
            CGPoint touchPoint = point;
            CGPoint targetPoint = [self convertPoint:touchPoint toView:self.textView];
            inside = [self textHighlightAtPoint:targetPoint] != nil;
        }
    }
    return inside;
}  // O(k * c), k ~ 4

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touches.count == 1) {
        UITouch *touch = [touches anyObject];
        BOOL handled = NO;
        if (!handled) {
            CGPoint targetPoint = [touch locationInView:self];
            XXTEEditorLineMask *mask = [self lineMaskAtPoint:targetPoint forComponentAtIndex:1];
            if (mask) {
                if (!mask.expanding) {
                    handled = YES;
                    if (mask.expanded) {
                        [self collapseLineMask:mask];
                    } else {
                        [self expandLineMask:mask];
                    }
                }
            }
        }
        if (!handled) {
            CGPoint targetPoint = [touch locationInView:self.textView];
            ICTextHighlight *textHighlight = [self textHighlightAtPoint:targetPoint];
            if (textHighlight) {
                handled = YES;
                [self.textView setSelectedTextRange:textHighlight.highlightRange];
                [self.textView select:self];
            }
        }
    }
}  // handle tap events

#pragma mark - Focus

- (void)focusRange:(NSRange)range {
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
    // We do not need to consider its origin because our maskView has the same bound with textView.
    textRect.origin.x += textView.textContainerInset.left - textInsets.left;
    textRect.origin.y += textView.textContainerInset.top - textInsets.top;
    textRect.size.width += textInsets.left + textInsets.right;
    textRect.size.height += textInsets.top + textInsets.bottom;
    
    CALayer *highlightLayer = [CALayer layer];
    [highlightLayer setFrame:textRect];
    [highlightLayer setCornerRadius:(textRect.size.height * 0.2f)];
    [highlightLayer setBackgroundColor:[self.focusColor CGColor]];
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

#pragma mark - Flash

- (void)flashRange:(NSRange)range {
    UITextView *textView = self.textView;
    if (!textView || ![textView isFirstResponder]) return;
    
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    if (!start) return;
    
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    if (!end) return;
    
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    if (!textRange) return;
    
    NSLayoutManager *manager = textView.layoutManager;
    NSRange glyphRange = [manager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    CGRect textRect = [manager boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
    
    UIEdgeInsets textInsets = UIEdgeInsetsMake(1.8, 4.0, 2.0, 4.0);
    // We do not need to consider its origin because our maskView has the same bound with textView.
    textRect.origin.x += textView.textContainerInset.left - textInsets.left;
    textRect.origin.y += textView.textContainerInset.top - textInsets.top;
    textRect.size.width += textInsets.left + textInsets.right;
    textRect.size.height += textInsets.top + textInsets.bottom;
    
    CALayer *highlightLayer = [CALayer layer];
    [highlightLayer setFrame:textRect];
    [highlightLayer setCornerRadius:(textRect.size.height * 0.2f)];
    [highlightLayer setBackgroundColor:[self.flashColor CGColor]];
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
    
    // opacity out
    CABasicAnimation *opacityOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityOutAnimation.beginTime = CACurrentMediaTime();
    opacityOutAnimation.duration = 0.4f;
    opacityOutAnimation.repeatCount = 1;
    opacityOutAnimation.fromValue = [NSNumber numberWithFloat:0.66f];
    opacityOutAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    opacityOutAnimation.removedOnCompletion = NO;
    opacityOutAnimation.fillMode = kCAFillModeBoth;
    opacityOutAnimation.additive = NO;
    opacityOutAnimation.autoreverses = NO;
    [highlightLayer addAnimation:opacityOutAnimation forKey:@"opacityOut"];
    
    [CATransaction commit];
}


#pragma mask - Line Masks

- (UIImage *)lineMaskImageForType:(XXTEEditorLineMaskType)type {
    switch (type) {
        case XXTEEditorLineMaskInfo:
        case XXTEEditorLineMaskWarning:
            return [[UIImage imageNamed:@"XXTEEditorLineMaskWarning"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        case XXTEEditorLineMaskError:
            return [[UIImage imageNamed:@"XXTEEditorLineMaskError"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        case XXTEEditorLineMaskSuccess:
            return [[UIImage imageNamed:@"XXTEEditorLineMaskSuccess"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        default:
            break;
    }
    return nil;
}

- (CGRect)lineFragmentsRectForLineIndex:(NSUInteger)idx {
    NSRange lineRange = [XXTETextPreprocessor lineRangeForString:self.textView.text AtIndex:idx];
    if (lineRange.location == NSNotFound) {
        return CGRectNull;
    }
    return [self.textView lineRectForRange:lineRange];
}

- (UIColor *)lineMaskColorForType:(XXTEEditorLineMaskType)type {
    return self.internalLineMaskColors[@(type)];
}

- (void)setLineMaskColor:(UIColor *)color forType:(XXTEEditorLineMaskType)type {
    [self.internalLineMaskColors setObject:color forKey:@(type)];
}

- (NSArray <XXTEEditorLineMask *> *)allLineMasks {
    return [self.internalLineMasks copy];
}

- (NSArray <XXTEEditorLineMask *> *)lineMasksForType:(XXTEEditorLineMaskType)type {
    NSMutableArray <XXTEEditorLineMask *> *arr = [NSMutableArray array];
    [self.internalLineMasks enumerateObjectsUsingBlock:^(XXTEEditorLineMask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.maskType == type) {
            [arr addObject:obj];
        }
    }];
    return [arr copy];
}

- (XXTEEditorLineMask *)lineMaskAtIndex:(NSUInteger)idx {
    return [self.internalLineMasks objectAtIndex:idx];
}

- (NSArray <XXTEEditorLineMask *> *)lineMasksInSet:(NSIndexSet *)maskSet {
    NSMutableArray <XXTEEditorLineMask *> *arr = [NSMutableArray array];
    [maskSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [arr addObject:[self.internalLineMasks objectAtIndex:idx]];
    }];
    return [arr copy];
}

- (BOOL)addLineMask:(XXTEEditorLineMask *)mask {
    if (self.internalLineMasks.count < kXXTEEditorMaximumLineMaskCount) {
        [self.internalLineMasks addObject:mask];
        [self fillAllLineMasks];
        return YES;
    }
    return NO;
}

- (BOOL)addLineMasks:(NSArray <XXTEEditorLineMask *> *)masks {
    if (self.internalLineMasks.count + masks.count < kXXTEEditorMaximumLineMaskCount) {
        [self.internalLineMasks addObjectsFromArray:masks];
        [self fillAllLineMasks];
        return YES;
    }
    return NO;
}

- (void)removeLineMask:(XXTEEditorLineMask *)mask {
    [self eraseLineMask:mask];
    [self.internalLineMasks removeObject:mask];
}

- (void)removeLineMasks:(NSArray <XXTEEditorLineMask *> *)masks {
    [self eraseLineMasks:masks];
    [self.internalLineMasks removeObjectsInArray:masks];
}

- (void)removeLineMaskAtIndex:(NSUInteger)idx {
    [self eraseLineMask:[self lineMaskAtIndex:idx]];
    [self.internalLineMasks removeObjectAtIndex:idx];
}

- (void)removeLineMasksInSet:(NSIndexSet *)maskSet {
    [self eraseLineMasks:[self lineMasksInSet:maskSet]];
    [self.internalLineMasks removeObjectsAtIndexes:maskSet];
}

- (void)removeLineMasksForType:(XXTEEditorLineMaskType)type {
    [self eraseLineMasks:[self lineMasksForType:type]];
    [self.internalLineMasks removeObjectsInArray:[self lineMasksForType:type]];
}

- (void)removeAllLineMasks {
    [self eraseLineMasks:[self allLineMasks]];
    [self.internalLineMasks removeAllObjects];
}

- (void)clearAllLineMasks {
    if (self.internalLineMasks.count) {
        [self removeAllLineMasks];
    }
}

#pragma mark - Line Mask Render

- (void)scrollToLineMask:(XXTEEditorLineMask *)mask animated:(BOOL)animated {
    XXTEEditorTextView *textView = self.textView;
    NSArray <CALayer *> *relatedLayers = (NSArray <CALayer *> *)mask.relatedObject;
    if (!relatedLayers) {
        return;
    }
    if (relatedLayers) {
        assert(relatedLayers.count == 2);
    }
    
    CALayer *highlightLayer = relatedLayers[0];
    CGRect toFrame = highlightLayer.frame;
    [textView scrollRectToVisible:toFrame animated:animated consideringInsets:YES];
}

- (void)fillAllLineMasks {
    for (XXTEEditorLineMask *mask in self.internalLineMasks) {
        if (!mask.relatedObject) {
            [self fillLineMask:mask];
        }
    }
}

- (void)fillLineMask:(XXTEEditorLineMask *)mask {
    XXTEEditorTextView *textView = self.textView;
    CGRect lineRect = [self lineFragmentsRectForLineIndex:mask.lineIndex];
    if (CGRectIsNull(lineRect)) {
        return;
    }
    UIColor *bgColor = [self lineMaskColorForType:mask.maskType];
    
    CALayer *highlightLayer = [CALayer layer];
    [highlightLayer setFrame:lineRect];
    [highlightLayer setBackgroundColor:[bgColor CGColor]];
    [highlightLayer setOpacity:0.20f];
    [[textView layer] addSublayer:highlightLayer];
    
    CGFloat cornerRadius = 6.0;
    CGRect fromRect = CGRectMake(CGRectGetMaxX(textView.frame), CGRectGetMinY(lineRect), 40.0, CGRectGetHeight(highlightLayer.bounds));
    CGRect toRect = CGRectOffset(fromRect, -CGRectGetWidth(fromRect) + cornerRadius, 0.0);
    CALayer *taggedLayer = [CALayer layer];
    [taggedLayer setContentsScale:[[UIScreen mainScreen] scale]];
    [taggedLayer setCornerRadius:cornerRadius];
    [taggedLayer setFrame:fromRect];
    [taggedLayer setBackgroundColor:[bgColor CGColor]];
    [taggedLayer setOpacity:.90f];
    [[textView layer] addSublayer:taggedLayer];
    
    if (CGRectGetHeight(taggedLayer.bounds) > 16.0) {
        CALayer *flagLayer = [CALayer layer];
        [flagLayer setFrame:CGRectMake(10.0, CGRectGetHeight(toRect) / 2.0 - 7.0, 14.0, 14.0)];
        [flagLayer setContents:(id)[self lineMaskImageForType:mask.maskType].CGImage];
        [taggedLayer addSublayer:flagLayer];
    }
    
    BOOL shouldAnimate = NO;
    CGRect containerRect = CGRectMake(textView.contentOffset.x, textView.contentOffset.y, textView.frame.size.width, textView.frame.size.height);
    if (CGRectIntersectsRect(lineRect, containerRect)) {
        shouldAnimate = YES;
    }
    
    if (shouldAnimate) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [taggedLayer setFrame:toRect];
            [highlightLayer removeAllAnimations];
            [taggedLayer removeAllAnimations];
        }];
        
        // opacity in
        CABasicAnimation *opacityInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityInAnimation.beginTime = CACurrentMediaTime();
        opacityInAnimation.duration = 0.2f;
        opacityInAnimation.repeatCount = 1;
        opacityInAnimation.fromValue = [NSNumber numberWithFloat:0.0];
        opacityInAnimation.toValue = [NSNumber numberWithFloat:0.166f];
        opacityInAnimation.removedOnCompletion = NO;
        opacityInAnimation.fillMode = kCAFillModeBoth; 
        opacityInAnimation.additive = NO;
        opacityInAnimation.autoreverses = NO;
        [highlightLayer addAnimation:opacityInAnimation forKey:@"opacityIn"];
        
        // tagged move in
        CGPoint fromPos = CGPointMake(CGRectGetMidX(fromRect), CGRectGetMidY(fromRect));
        CGPoint toPos = CGPointMake(fromPos.x - CGRectGetWidth(fromRect) + cornerRadius, fromPos.y);
        CABasicAnimation *moveInAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        moveInAnimation.beginTime = CACurrentMediaTime();
        moveInAnimation.duration = 0.2f;
        moveInAnimation.repeatCount = 1;
        moveInAnimation.fromValue = [NSValue valueWithCGPoint:fromPos];
        moveInAnimation.toValue = [NSValue valueWithCGPoint:toPos];
        moveInAnimation.removedOnCompletion = NO;
        moveInAnimation.fillMode = kCAFillModeBoth;
        moveInAnimation.additive = NO;
        moveInAnimation.autoreverses = NO;
        [taggedLayer addAnimation:moveInAnimation forKey:@"moveIn"];
        
        [CATransaction commit];
    } else {
        [taggedLayer setFrame:toRect];
    }
    
    mask.relatedObject = @[ highlightLayer, taggedLayer ];
    mask.expanded = NO;
}

- (void)eraseAllLineMasks {
    for (XXTEEditorLineMask *mask in self.internalLineMasks) {
        [self eraseLineMask:mask];
    }
}

- (void)eraseLineMasks:(NSArray <XXTEEditorLineMask *> *)masks {
    for (XXTEEditorLineMask *mask in masks) {
        [self eraseLineMask:mask];
    }
}

- (void)eraseLineMask:(XXTEEditorLineMask *)mask {
    XXTEEditorTextView *textView = self.textView;
    NSArray <CALayer *> *relatedLayers = (NSArray <CALayer *> *)mask.relatedObject;
    if (relatedLayers) {
        assert(relatedLayers.count == 2);
    }
    
    CALayer *highlightLayer = relatedLayers[0];
    CALayer *taggedLayer = relatedLayers[1];
    
    CGFloat cornerRadius = 6.0;
    CGRect lineRect = highlightLayer.frame;
    CGRect fromRect = taggedLayer.frame;
    
    BOOL shouldAnimate = NO;
    CGRect containerRect = CGRectMake(textView.contentOffset.x, textView.contentOffset.y, textView.frame.size.width, textView.frame.size.height);
    if (CGRectIntersectsRect(lineRect, containerRect)) {
        shouldAnimate = YES;
    }
    
    if (shouldAnimate) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            for (CALayer *layer in relatedLayers) {
                [layer removeFromSuperlayer];
            }
        }];
        
        // opacity out
        CABasicAnimation *opacityOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityOutAnimation.beginTime = CACurrentMediaTime();
        opacityOutAnimation.duration = 0.2f;
        opacityOutAnimation.repeatCount = 1;
        opacityOutAnimation.fromValue = [NSNumber numberWithFloat:0.166f];
        opacityOutAnimation.toValue = [NSNumber numberWithFloat:0.f];
        opacityOutAnimation.removedOnCompletion = NO;
        opacityOutAnimation.fillMode = kCAFillModeBoth;
        opacityOutAnimation.additive = NO;
        opacityOutAnimation.autoreverses = NO;
        [highlightLayer addAnimation:opacityOutAnimation forKey:@"opacityOut"];
        
        // tagged move out
        CGPoint fromPos = CGPointMake(CGRectGetMidX(fromRect), CGRectGetMidY(fromRect));
        CGPoint toPos = CGPointMake(fromPos.x + CGRectGetWidth(fromRect) - cornerRadius, fromPos.y);
        CABasicAnimation *moveOutAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        moveOutAnimation.beginTime = CACurrentMediaTime();
        moveOutAnimation.duration = 0.2f;
        moveOutAnimation.repeatCount = 1;
        moveOutAnimation.fromValue = [NSValue valueWithCGPoint:fromPos];
        moveOutAnimation.toValue = [NSValue valueWithCGPoint:toPos];
        moveOutAnimation.removedOnCompletion = NO;
        moveOutAnimation.fillMode = kCAFillModeBoth;
        moveOutAnimation.additive = NO;
        moveOutAnimation.autoreverses = NO;
        [taggedLayer addAnimation:moveOutAnimation forKey:@"moveOut"];
        
        [CATransaction commit];
    } else {
        for (CALayer *layer in relatedLayers) {
            [layer removeFromSuperlayer];
        }
    }
    
    mask.relatedObject = nil;
    mask.expanded = NO;
}

#pragma mark - Line Mask (Private)

- (CGRect)rectForLineMask:(XXTEEditorLineMask *)mask componentAtIndex:(NSUInteger)idx
{
    XXTEEditorTextView *textView = self.textView;
    NSArray <CALayer *> *relatedLayers = (NSArray <CALayer *> *)mask.relatedObject;
    if (relatedLayers) {
        assert(relatedLayers.count == 2);
        assert(idx < 2);
        CALayer *layer = relatedLayers[idx];
        return [self convertRect:layer.frame fromView:textView];
    }
    return CGRectNull;
}

- (XXTEEditorLineMask *)lineMaskAtPoint:(CGPoint)point forComponentAtIndex:(NSUInteger)idx
{
    for (XXTEEditorLineMask *mask in self.allLineMasks)
    {
        CGRect maskRect = [self rectForLineMask:mask componentAtIndex:idx];
        if (CGRectIsNull(maskRect)) {
            continue;
        }
        if (CGRectContainsPoint(maskRect, point)) {
            return mask;
        }
    }
    return nil;
}

- (void)expandLineMask:(XXTEEditorLineMask *)mask {
    // do not expand again
    if (mask.expanded || mask.expanding) {
        return;
    }
    
    // expand without mask description is not allowed
    if (!mask.maskDescription || !mask.relatedObject) {
        return;
    }
    
    // get tagged layer
    NSArray <CALayer *> *relatedLayers = (NSArray <CALayer *> *)mask.relatedObject;
    assert(relatedLayers.count == 2);
    CALayer *highlightLayer = relatedLayers[0];
    CALayer *taggedLayer = relatedLayers[1];
    
    // do not expand small mask
    if (CGRectGetHeight(taggedLayer.bounds) <= 16.0) {
        return;
    }
    
    mask.expanding = YES;
    
    // format description
    NSString *maskDescription = [NSString stringWithFormat:@"%@", mask.maskDescription];
    
    // calculate size for description label
    UIFont *labelFont = [UIFont boldSystemFontOfSize:12.0];
    UIColor *labelColor = [UIColor colorWithWhite:0.0 alpha:.75];
    NSDictionary *maskAttr = @{ NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelColor };
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:maskDescription attributes:maskAttr];
    CGSize strSize = attrStr.size;
    
    // set maximum size
    UIEdgeInsets tageedExtraInset = UIEdgeInsetsMake(0.0, 34.0, 0.0, 10.0);
    CGRect highlightRect = highlightLayer.frame;
    CGFloat maximumTaggedWidth = CGRectGetWidth(highlightRect) - (tageedExtraInset.left + tageedExtraInset.right) * 2.0;
    if (strSize.width > maximumTaggedWidth)
    {
        strSize.width = maximumTaggedWidth;
    }
    
    // expand tagged layer's width
    CGRect taggedFrame = taggedLayer.frame;
    taggedFrame = CGRectMake(taggedFrame.origin.x, taggedFrame.origin.y, taggedFrame.size.width + strSize.width + tageedExtraInset.right, taggedFrame.size.height);
    taggedLayer.frame = taggedFrame;
    
    // draw attriubued string
    CATextLayer *labelLayer = [CATextLayer layer];
    labelLayer.opacity = 0.0;
    labelLayer.contentsScale = [[UIScreen mainScreen] scale];
    labelLayer.font = (__bridge CFTypeRef _Nullable)(labelFont);
    labelLayer.fontSize = labelFont.pointSize;
    labelLayer.foregroundColor = labelColor.CGColor;
    labelLayer.alignmentMode = kCAAlignmentRight;
    labelLayer.truncationMode = kCATruncationStart;
    labelLayer.frame = CGRectMake(tageedExtraInset.left, CGRectGetHeight(taggedFrame) / 2.0 - strSize.height / 2.0, strSize.width, strSize.height);
    labelLayer.string = maskDescription;
    [taggedLayer addSublayer:labelLayer];
    
    // calculate start - end position
    CGFloat expandOffsetX = - strSize.width - tageedExtraInset.right;
    CGPoint fromPos = CGPointMake(CGRectGetMidX(taggedFrame), CGRectGetMidY(taggedFrame));
    CGPoint toPos = CGPointMake(fromPos.x + expandOffsetX, fromPos.y);
    
    // give UIKit some time to handle touch & scroll events in main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // animations
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            labelLayer.opacity = 1.0;
            [labelLayer removeAllAnimations];
            taggedLayer.frame = CGRectOffset(taggedFrame, expandOffsetX, 0.0);
            [taggedLayer removeAllAnimations];
            
            mask.expanded = YES;
            mask.expanding = NO;
        }];
        
        // opacity in animation
        CABasicAnimation *opacityInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityInAnimation.beginTime = CACurrentMediaTime() + .2f;
        opacityInAnimation.duration = 0.3;
        opacityInAnimation.repeatCount = 1;
        opacityInAnimation.fromValue = [NSNumber numberWithFloat:0.0];
        opacityInAnimation.toValue = [NSNumber numberWithFloat:1.0];
        opacityInAnimation.removedOnCompletion = NO;
        opacityInAnimation.fillMode = kCAFillModeForwards;
        opacityInAnimation.additive = NO;
        opacityInAnimation.autoreverses = NO;
        [labelLayer addAnimation:opacityInAnimation forKey:@"labelOpacityIn"];
        
        // expand animation
        CABasicAnimation *expandAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        expandAnimation.beginTime = CACurrentMediaTime() + .2f;
        expandAnimation.duration = 0.2;
        expandAnimation.repeatCount = 1;
        expandAnimation.fromValue = [NSValue valueWithCGPoint:fromPos];
        expandAnimation.toValue = [NSValue valueWithCGPoint:toPos];
        expandAnimation.removedOnCompletion = NO;
        expandAnimation.fillMode = kCAFillModeForwards;
        expandAnimation.additive = NO;
        expandAnimation.autoreverses = NO;
        [taggedLayer addAnimation:expandAnimation forKey:@"expand"];
        
        [CATransaction commit];
    });
}

- (void)collapseLineMask:(XXTEEditorLineMask *)mask {
    // do not collapse again
    if (!mask.expanded || mask.expanding) {
        return;
    }
    
    // expand without mask description is not allowed
    if (!mask.maskDescription || !mask.relatedObject) {
        return;
    }
    
    mask.expanding = YES;
    
    // get tagged layer
    NSArray <CALayer *> *relatedLayers = (NSArray <CALayer *> *)mask.relatedObject;
    assert(relatedLayers.count == 2);
    CALayer *taggedLayer = relatedLayers[1];
    CGRect taggedFrame = taggedLayer.frame;
    
    // calculate start - end position
    CGFloat collapseOffsetX = CGRectGetWidth(taggedFrame) - 40.0;
    CGPoint fromPos = CGPointMake(CGRectGetMidX(taggedFrame), CGRectGetMidY(taggedFrame));
    CGPoint toPos = CGPointMake(fromPos.x + collapseOffsetX, fromPos.y);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // collapse animation
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            // remove text layer
            CALayer *layerToRemove = nil;
            for (CALayer *layer in taggedLayer.sublayers) {
                if ([layer isKindOfClass:[CATextLayer class]]) {
                    layerToRemove = layer;
                }
            }
            [layerToRemove removeFromSuperlayer];
            
            // calculate collapsed frame
            CGRect newTaggedFrame = CGRectOffset(taggedFrame, collapseOffsetX, 0.0);
            newTaggedFrame.size.width = 40.0;
            
            // collapse frame set
            taggedLayer.frame = newTaggedFrame;
            [taggedLayer removeAllAnimations];
            
            mask.expanded = NO;
            mask.expanding = NO;
        }];
        
        CABasicAnimation *collapseAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        collapseAnimation.beginTime = CACurrentMediaTime() + .2f;
        collapseAnimation.duration = 0.2f;
        collapseAnimation.repeatCount = 1;
        collapseAnimation.fromValue = [NSValue valueWithCGPoint:fromPos];
        collapseAnimation.toValue = [NSValue valueWithCGPoint:toPos];
        collapseAnimation.removedOnCompletion = NO;
        collapseAnimation.fillMode = kCAFillModeForwards;
        collapseAnimation.additive = NO;
        collapseAnimation.autoreverses = NO;
        [taggedLayer addAnimation:collapseAnimation forKey:@"collapse"];
        
        [CATransaction commit];
    });
}

@end
