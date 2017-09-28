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
    if ([layoutManager.textStorage.string characterAtIndex:charIndex] == '\t') {
        return NSControlCharacterActionWhitespace;
    }
    return action;
}

- (CGRect)layoutManager:(NSLayoutManager *)layoutManager boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)proposedRect glyphPosition:(CGPoint)glyphPosition characterIndex:(NSUInteger)charIndex {
    CGRect rect = CGRectMake(glyphPosition.x, glyphPosition.y, self.tabWidth, proposedRect.size.height);
    return rect;
}

@end
