//
//  XXTEEditorTextView.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextView.h"

#import "XXTEEditorTextStorage.h"
#import "XXTEEditorLayoutManager.h"
#import "XXTEEditorTextView+TextRange.h"


static CGFloat kXXTEEditorTextViewGutterExtraHeight = 150.0;

@interface XXTEEditorTextView ()

@property (nonatomic, assign) BOOL shouldReloadContainerInsets;

@end

@implementation XXTEEditorTextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _showLineHighlight = NO;
    _lineHighlightRange = NSMakeRange(NSNotFound, 0);
    _needsUpdateLineHighlight = NO;
    _lineHighlightRect = CGRectNull;
    
    self.bounces = YES;
    self.alwaysBounceVertical = YES;
    self.contentMode = UIViewContentModeRedraw;
    self.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.layoutManager.allowsNonContiguousLayout = NO;
    
    self.gutterBackgroundColor = [UIColor clearColor];
    self.gutterLineColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect {
    [self reloadContainerInsetsIfNeeded];
    
    if (!self.showLineNumbers) {
        [super drawRect:rect];
        return;
    }
    
    XXTEEditorLayoutManager *manager = self.vLayoutManager;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect frame = self.frame;
    
    CGFloat height = MAX(CGRectGetHeight(frame), self.contentSize.height) + kXXTEEditorTextViewGutterExtraHeight * 2.0;
    
    CGContextSetFillColorWithColor(context, self.gutterBackgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(frame.origin.x, frame.origin.y - (kXXTEEditorTextViewGutterExtraHeight), manager.gutterWidth, height));
    
    CGContextSetFillColorWithColor(context, self.gutterLineColor.CGColor);
    CGContextFillRect(context, CGRectMake(manager.gutterWidth, frame.origin.y - (kXXTEEditorTextViewGutterExtraHeight), 1.0, height));
    
    // [self drawLineHighlight];
    [super drawRect:rect];
}

- (void)drawLineHighlight {
    if (!self.showLineHighlight || self.lineHighlightRange.location == NSNotFound) {
        return;
    }
    if ([self needsUpdateLineHighlight]) {
        self.lineHighlightRect = [self lineRectForRange:self.lineHighlightRange];
        _needsUpdateLineHighlight = NO;
    }
    if (CGRectIsNull(self.lineHighlightRect)) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // CGContextSaveGState(context);
    // [[UIColor whiteColor] setFill];
    CGContextFillRect(context, self.lineHighlightRect);
    // CGContextRestoreGState(context);
}

#pragma mark - Setters

- (void)setShowLineHighlight:(BOOL)highlight lineRange:(NSRange)range {
    _showLineHighlight = highlight;
    if (highlight) {
        _lineHighlightRange = range;
        [self setNeedsUpdateLineHighlight];
        [self setNeedsDisplay];
    } else {
        _lineHighlightRange = NSMakeRange(NSNotFound, 0);
        _needsUpdateLineHighlight = NO;
        _lineHighlightRect = CGRectNull;
        [self setNeedsDisplay];
    }
}

- (void)setNeedsUpdateLineHighlight {
    _needsUpdateLineHighlight = YES;
}

- (void)setText:(NSString *)text {
    UITextRange *textRange = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    [self replaceRange:textRange withText:text];
}

- (void)setGutterLineColor:(UIColor *)gutterLineColor {
    _gutterLineColor = gutterLineColor;
    [self setNeedsDisplay];
}

- (void)setGutterBackgroundColor:(UIColor *)gutterBackgroundColor {
    _gutterBackgroundColor = gutterBackgroundColor;
    [self setNeedsDisplay];
}

- (void)replaceRange:(UITextRange *)range
            withText:(NSString *)text {
    [super replaceRange:range withText:text];
}

- (void)setShowLineNumbers:(BOOL)showLineNumbers {
    _showLineNumbers = showLineNumbers;
    [self.vLayoutManager setShowLineNumbers:showLineNumbers];
    [self setShouldReloadContainerInsets:YES];
    [self setNeedsDisplay];
}

- (void)setNeedsReloadContainerInsets {
    self.shouldReloadContainerInsets = YES;
}

- (void)reloadContainerInsetsIfNeeded {
    if (self.shouldReloadContainerInsets) {
        [self setTextContainerInset:[self xxteTextContainerInset]];
        self.shouldReloadContainerInsets = NO;
    }
}

- (UIEdgeInsets)xxteTextContainerInset {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (self.showLineNumbers) {
        insets = UIEdgeInsetsMake(8.0, (self.vLayoutManager).gutterWidth + 2.0, 8.0, 8.0);
    } else {
        insets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
    }
    return insets;
}

@end
