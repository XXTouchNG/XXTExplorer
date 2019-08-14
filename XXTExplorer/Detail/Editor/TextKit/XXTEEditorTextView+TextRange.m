//
//  XXTEEditorTextView+TextRange.m
//  XXTExplorer
//
//  Created by MMM on 8/14/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorTextView+TextRange.h"
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

@implementation XXTEEditorTextView (TextRange)

- (NSRange)fixedSelectedTextRange {
    NSRange selectedRange = [self selectedRange];
    NSString *stringRef = self.text;
    NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
    [stringRef getLineStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:selectedRange];
    return NSMakeRange(lineStart, contentsEnd - lineStart);
}

- (UITextRange *)textRangeFromNSRange:(NSRange)range {
    UITextPosition *startPosition = [self positionFromPosition:self.beginningOfDocument offset:(NSInteger)range.location];
    UITextPosition *endPosition = [self positionFromPosition:startPosition offset:(NSInteger)range.length];
    UITextRange *textRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    return textRange;
}

- (CGRect)lineRectForRange:(NSRange)range {
    CGRect rect = [self.layoutManager lineFragmentsRectForRange:range];
    CGRect rect1 = CGRectMake(0, rect.origin.y, self.textContainer.size.width, rect.size.height);
    rect1 = CGRectInset(rect1, self.textContainer.lineFragmentPadding, 0);
    rect1 = CGRectOffset(rect1, self.textContainerInset.left, self.textContainerInset.top);
    return CGRectIntegral(rect1);
}

@end
