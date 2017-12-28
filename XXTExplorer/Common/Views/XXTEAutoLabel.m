//
//  XXTEAutoLabel.m
//  XXTExplorer
//
//  Created by Zheng on 27/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEAutoLabel.h"

@implementation XXTEAutoLabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    if (self.numberOfLines == 0) {
        CGFloat boundsWidth = CGRectGetWidth(bounds);
        if (self.preferredMaxLayoutWidth != boundsWidth) {
            self.preferredMaxLayoutWidth = boundsWidth;
            [self setNeedsUpdateConstraints];
        }
    }
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    if (self.numberOfLines == 0) {
        // There's a bug where intrinsic content size may be 1 point too short
        size.height += 1;
    }
    
    return size;
}

@end
