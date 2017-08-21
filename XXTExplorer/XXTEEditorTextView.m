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

@interface XXTEEditorTextView ()

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
    self.bounces = YES;
    self.alwaysBounceVertical = YES;
    self.contentMode = UIViewContentModeRedraw;
    self.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.layoutManager.allowsNonContiguousLayout = NO;
    
    self.gutterBackgroundColor = [UIColor clearColor];
    self.gutterLineColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect {
    if (!self.lineNumberEnabled) {
        [super drawRect:rect];
        return;
    }
    
    XXTEEditorLayoutManager *manager = self.vLayoutManager;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    CGFloat height = MAX(CGRectGetHeight(bounds), self.contentSize.height) + 200;
    
    CGContextSetFillColorWithColor(context, self.gutterBackgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(bounds.origin.x, bounds.origin.y, manager.gutterWidth, height));
    
    CGContextSetFillColorWithColor(context, self.gutterLineColor.CGColor);
    CGContextFillRect(context, CGRectMake(manager.gutterWidth, bounds.origin.y, 0.5, height));
    
    [super drawRect:rect];
}

#pragma mark - Setters

- (void)setText:(NSString *)text
{
    UITextRange *textRange = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    [self replaceRange:textRange withText:text];
}

- (void)replaceRange:(UITextRange *)range
            withText:(NSString *)text {
    [super replaceRange:range withText:text];
}

- (void)setLineNumberEnabled:(BOOL)lineNumberEnabled {
    _lineNumberEnabled = lineNumberEnabled;
    UIEdgeInsets insets = lineNumberEnabled ?
    UIEdgeInsetsMake(8, (self.vLayoutManager).gutterWidth, 8, 0) :
    UIEdgeInsetsMake(8, 8, 8, 8);
    [self setTextContainerInset:insets];
    [self.vLayoutManager setLineNumberEnabled:lineNumberEnabled];
}

@end
