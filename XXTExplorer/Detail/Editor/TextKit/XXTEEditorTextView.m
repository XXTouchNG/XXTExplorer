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
        UIEdgeInsets insets = UIEdgeInsetsZero;
        if (self.showLineNumbers) {
            insets = UIEdgeInsetsMake(8, (self.vLayoutManager).gutterWidth + 2, 8, 8);
        } else {
            insets = UIEdgeInsetsMake(8, 8, 8, 8);
        }
        [self setTextContainerInset:insets];
        self.shouldReloadContainerInsets = NO;
    }
}

@end
