//
//  XXTEEditorController+NSLayoutManagerDelegate.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+NSLayoutManagerDelegate.h"
#import "XXTEEditorTheme.h"

@implementation XXTEEditorController (NSLayoutManagerDelegate)

#pragma mark - NSLayoutManagerDelegate

- (NSControlCharacterAction)layoutManager:(NSLayoutManager *)layoutManager shouldUseAction:(NSControlCharacterAction)action forControlCharacterAtIndex:(NSUInteger)charIndex {
    if ([layoutManager.textStorage.string characterAtIndex:charIndex] == '\t') {
        return NSControlCharacterActionWhitespace;
    }
    return action;
}

- (CGRect)layoutManager:(NSLayoutManager *)layoutManager boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)proposedRect glyphPosition:(CGPoint)glyphPosition characterIndex:(NSUInteger)charIndex {
    CGRect rect = CGRectMake(glyphPosition.x, glyphPosition.y, self.tabWidthValue, proposedRect.size.height);
    return rect;
}

@end
