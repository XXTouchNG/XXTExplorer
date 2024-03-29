//
//  UITextView+TextRange.m
//  XXTExplorer
//
//  Created by MMM on 8/14/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "UITextView+TextRange.h"
#import "SKRange.h"

@interface NSLayoutManager (LineRect)

- (CGRect)lineFragmentsRectForRange:(NSRange)range;

@end

@implementation NSLayoutManager (LineRect)

- (CGRect)lineFragmentsRectForRange:(NSRange)range {
    if (@available(iOS 9.0, *)) {
        NSRange glyphRange = [self glyphRangeForCharacterRange:range actualCharacterRange:nil];
        if (glyphRange.location < self.numberOfGlyphs || self.extraLineFragmentTextContainer == nil) {
            NSRange effectiveRange = NSMakeRange(NSNotFound, 0);
            CGRect lowerRect = [self lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:&effectiveRange withoutAdditionalLayout:YES];
            if (!NSRangeContainsIndex(effectiveRange, glyphRange.location + glyphRange.length)) {
                NSUInteger upperBound = MIN(glyphRange.location + glyphRange.length, self.numberOfGlyphs - 1);
                CGRect upperRect = [self lineFragmentRectForGlyphAtIndex:upperBound effectiveRange:nil withoutAdditionalLayout:YES];
                return CGRectUnion(lowerRect, upperRect);
            } else {
                return lowerRect;
            }
        } else {
            return self.extraLineFragmentRect;
        }
    }
    return CGRectNull;
}

@end

@implementation UITextView (TextRange)

- (NSRange)fixedSelectedTextRange {
    NSRange selectedRange = [self selectedRange];
    NSString *stringRef = self.text;
    NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
    [stringRef getLineStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:selectedRange];
    return NSMakeRange(lineStart, contentsEnd - lineStart);
}

- (UITextRange *)textRangeFromNSRange:(NSRange)range {
    UITextPosition *startPosition = [self positionFromPosition:self.beginningOfDocument offset:(NSInteger)range.location];
    NSAssert(startPosition, @"Invalid startPosition.");
    UITextPosition *endPosition = [self positionFromPosition:startPosition offset:(NSInteger)range.length];
    NSAssert(endPosition, @"Invalid endPosition.");
    UITextRange *textRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    NSAssert(textRange, @"Invalid textRange.");
    return textRange;
}

- (CGRect)lineRectForRange:(NSRange)range {  // full-width
    CGRect rect = [self.layoutManager lineFragmentsRectForRange:range];
    CGRect rect1 = CGRectMake(0, rect.origin.y + self.textContainerInset.top, self.textContainer.size.width + (self.textContainerInset.left + self.textContainerInset.right), rect.size.height);
    return CGRectIntegral(rect1);
}

@end
