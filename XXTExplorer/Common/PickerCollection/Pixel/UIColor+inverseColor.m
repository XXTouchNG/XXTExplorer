//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "UIColor+inverseColor.h"


@implementation UIColor (inverseColor)

- (UIColor *)inverseColor {

    CGFloat r, g, b, alpha;
    [self getRed:&r green:&g blue:&b alpha:&alpha];

    // Counting the perceptive luminance - human eye favors green color...
    double a = 1 - ( 0.299 * r + 0.587 * g + 0.114 * b);

    if (a < 0.5)
        return [UIColor blackColor];
    else
        return [UIColor clearColor];

}

@end