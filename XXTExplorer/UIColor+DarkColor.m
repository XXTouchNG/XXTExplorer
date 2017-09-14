//
//  UIColor+DarkColor.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIColor+DarkColor.h"

@implementation UIColor (DarkColor)

- (BOOL)isDarkColor
{
    CGFloat components[4] = {0.0, 0.0, 0.0, 0.0};
    if (NO == [self getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]])
    {
        if ([self getWhite:&components[0] alpha:&components[3]])
        {
            components[1] = components[0];
            components[2] = components[0];
        }
    }
    CGFloat colorBrightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000.f;
    return (colorBrightness < 0.5);
}

@end
