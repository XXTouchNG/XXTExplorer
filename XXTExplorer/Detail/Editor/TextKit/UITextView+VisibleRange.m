//
//  UITextView+VisibleRange.m
//  XXTExplorer
//
//  Created by Darwin on 8/7/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "UITextView+VisibleRange.h"

@implementation UITextView (VisibleRange)

- (NSRange)visibleRange {
    CGRect textRect = self.bounds;
    UIEdgeInsets inset = self.textContainerInset;
    textRect = CGRectOffset(textRect, inset.left, inset.top);
    return [self rangeForRect:textRect withoutAdditionalLayout:YES];
}

- (NSRange)rangeForRect:(CGRect)textRect withoutAdditionalLayout:(BOOL)additional {
    if (!self.layoutManager || !self.textContainer) {
        return NSMakeRange(0, 0);
    }
    NSRange glyphRange;
    if (additional) {
        glyphRange = [self.layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:textRect inTextContainer:[self textContainer]];
    } else {
        glyphRange = [self.layoutManager glyphRangeForBoundingRect:textRect inTextContainer:[self textContainer]];
    }
    return [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
}

@end
