//
// Created by Zheng on 01/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "UIColor+hexValue.h"


@implementation UIColor (hexValue)

- (CGFloat)alpha {
    return CGColorGetAlpha(self.CGColor);
}

- (NSString *)hexStringWithAlpha:(BOOL)withAlpha {
    CGColorRef color = self.CGColor;
    size_t count = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    static NSString *stringFormat = @"%02x%02x%02x";
    NSString *hex = nil;
    if (count == 2) {
        NSUInteger white = (NSUInteger)(components[0] * 255.0f);
        hex = [NSString stringWithFormat:stringFormat, white, white, white];
    } else if (count == 4) {
        hex = [NSString stringWithFormat:stringFormat,
                                         (NSUInteger)(components[0] * 255.0f),
                                         (NSUInteger)(components[1] * 255.0f),
                                         (NSUInteger)(components[2] * 255.0f)];
    }

    if (hex && withAlpha) {
        hex = [hex stringByAppendingFormat:@"%02lx",
                                           (unsigned long)(self.alpha * 255.0 + 0.5)];
    }
    return hex;
}

- (NSNumber *)RGBANumberValue {
    CGFloat red, green, blue, alpha;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha])
    {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }
    red = roundf(red * 255.f);
    green = roundf(green * 255.f);
    blue = roundf(blue * 255.f);
    alpha = roundf(alpha * 255.f);
    return @(((uint)red << 24) | ((uint)green << 16) | ((uint)blue << 8) | ((uint)alpha));
}

@end
