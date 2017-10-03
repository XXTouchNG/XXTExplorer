//
//  XXTEEditorTypeSetter.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTypeSetter.h"

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

@end
