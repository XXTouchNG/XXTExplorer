//
//  XXTPixelToolbar.m
//  XXTExplorer
//
//  Created by MMM on 8/21/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTPixelToolbar.h"

@implementation XXTPixelToolbar

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if (@available(iOS 13.0, *)) {
        CGContextSetStrokeColorWithColor(ctx, [UIColor separatorColor].CGColor);
    } else {
        CGContextSetRGBStrokeColor(ctx, 0.85, 0.85, 0.85, 1.0);
    }
    CGContextSetLineWidth(ctx, 1.0f);
    CGPoint aPoint[2] = {
        CGPointMake(0.0, CGRectGetHeight(self.frame)),
        CGPointMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))
    };
    CGContextAddLines(ctx, aPoint, 2);
    CGContextStrokePath(ctx);
}

@end
