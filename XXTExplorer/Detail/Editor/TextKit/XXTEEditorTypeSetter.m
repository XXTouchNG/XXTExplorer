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

- (CGRect)layoutManager:(NSLayoutManager *)layoutManager boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)proposedRect glyphPosition:(CGPoint)glyphPosition characterIndex:(NSUInteger)charIndex {
    unichar character = [layoutManager.textStorage.string characterAtIndex:charIndex];
    if (character == '\t') {
        CGRect rect = CGRectMake(glyphPosition.x, glyphPosition.y, self.tabWidth, proposedRect.size.height);
        return rect;
    }
    return CGRectZero;
}

- (CGFloat)layoutManager:(XXTEEditorLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    // Line height is a multiple of the complete line, here we need only the extra space
    return (MAX(layoutManager.lineHeightScale, 1) - 1) * rect.size.height;
}

//- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldSetLineFragmentRect:(inout CGRect *)lineFragmentRect lineFragmentUsedRect:(inout CGRect *)lineFragmentUsedRect baselineOffset:(inout CGFloat *)baselineOffset inTextContainer:(NSTextContainer *)textContainer forGlyphRange:(NSRange)glyphRange
//{
//    return YES;
//}

//- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
//{
//
//}

@end
