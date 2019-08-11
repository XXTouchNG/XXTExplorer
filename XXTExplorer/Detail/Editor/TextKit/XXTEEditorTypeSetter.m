//
//  XXTEEditorTypeSetter.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTypeSetter.h"
#import "XXTEEditorLayoutManager.h"


@implementation XXTEEditorTypeSetter

#pragma mark - NSLayoutManagerDelegate

/// customize behavior by control glyph
- (NSControlCharacterAction)layoutManager:(NSLayoutManager *)layoutManager shouldUseAction:(NSControlCharacterAction)action forControlCharacterAtIndex:(NSUInteger)charIndex {
    unichar character = [layoutManager.textStorage.string characterAtIndex:charIndex];
    if (character == '\t') {
        return NSControlCharacterActionWhitespace;
    }
    /*
     else if (character == '\r') {
        return NSControlCharacterActionZeroAdvancement;
    }
     */
    return action;
}

/// return bounding box for control glyph
- (CGRect)layoutManager:(NSLayoutManager *)layoutManager boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)proposedRect glyphPosition:(CGPoint)glyphPosition characterIndex:(NSUInteger)charIndex {
    unichar character = [layoutManager.textStorage.string characterAtIndex:charIndex];
    if (character == '\t') {
        CGRect rect = CGRectMake(glyphPosition.x, glyphPosition.y, self.tabWidth, proposedRect.size.height);
        return rect;
    }
    return CGRectZero;
}

/// keep line height
- (CGFloat)layoutManager:(XXTEEditorLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    // Line height is a multiple of the complete line, here we need only the extra space
    return (MAX(layoutManager.lineHeightScale, 1) - 1) * rect.size.height;
}

/// adjust vertical position to keep line height even with composed font
- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldSetLineFragmentRect:(inout CGRect *)lineFragmentRect lineFragmentUsedRect:(inout CGRect *)lineFragmentUsedRect baselineOffset:(inout CGFloat *)baselineOffset inTextContainer:(NSTextContainer *)textContainer forGlyphRange:(NSRange)glyphRange
{
    if ([layoutManager isKindOfClass:[XXTEEditorLayoutManager class]]) {
        XXTEEditorLayoutManager *manager = (XXTEEditorLayoutManager *)layoutManager;
        (*lineFragmentRect).size.height = manager.fontLineHeight;
        (*lineFragmentUsedRect).size.height = manager.fontLineHeight;
        // (*baselineOffset) += manager.baseLineOffset;
        return YES;
    }
    return NO;
}

/// avoid soft warpping just after an indent
- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
{
    // -> Getting index fails when the code point is a part of surrogate pair.
    NSString *string = layoutManager.textStorage.string;
    if (!string) {
        return YES;
    }
    
    // check if the character is the first non-whitespace character after indent
    for (NSUInteger idx = charIndex; idx >= 0; idx--) {
        unichar character = [string characterAtIndex:idx];
        switch (character) {
            case ' ':
            case '\t':
                continue;
            case '\n':  // the line ended before hitting to any indent characters
                return NO;
            default:  // hit to non-indent character
                return YES;
        }
    }
    
    return NO;  // didn't hit any line-break (= first line)
}

@end
