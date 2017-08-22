//
//  XXTPixelColor.m
//  XXTPixelImage
//
//  Created by 苏泽 on 16/8/2.
//  Copyright © 2016年 苏泽. All rights reserved.
//

#import "XXTPixelColor.h"

typedef union SZ_COLOR SZ_COLOR;

/* Color Struct */
union SZ_COLOR {
    uint32_t the_color; /* the_color is name of color value */
    struct { /* RGB struct */
        uint8_t blue;
        uint8_t green;
        uint8_t red;
        uint8_t alpha;
    };
};

@implementation XXTPixelColor

+ (XXTPixelColor *)colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(uint8_t)alpha
{
    return [[[XXTPixelColor alloc] autorelease] initWithRed:red green:green blue:blue alpha:alpha];
}

+ (XXTPixelColor *)colorWithUIColor:(UIColor *)uicolor
{
    return [[[XXTPixelColor alloc] autorelease] initWithUIColor:uicolor];
}

+ (XXTPixelColor *)colorWithColor:(uint32_t)color
{
    return [[[XXTPixelColor alloc] autorelease] initWithColor:color];
}

+ (XXTPixelColor *)colorWithXXTColor:(XXTPixelColor *)xxtcolor
{
    return [[[XXTPixelColor alloc] autorelease] initWithXXTColor:xxtcolor];
}

- (uint32_t)getColorAlpha
{
    SZ_COLOR color;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    color.alpha = _alpha;
    return color.the_color;
}

- (uint32_t)color {
    return [self getColorAlpha];
}

- (uint32_t)getColor
{
    SZ_COLOR color;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    color.alpha = 0;
    return color.the_color;
}

- (NSString *)getColorHexAlpha
{
    SZ_COLOR color;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    color.alpha = _alpha;
    return [NSString stringWithFormat:@"0x%08x", color.the_color];
}

- (NSString *)getColorHex
{
    SZ_COLOR color;
    color.red = _red;
    color.green = _green;
    color.blue = _blue;
    color.alpha = 0;
    return [NSString stringWithFormat:@"0x%06x", color.the_color];
}

- (UIColor *)getUIColor
{
    return [UIColor colorWithRed:((CGFloat)_red)/255.0f green:((CGFloat)_green)/255.0f blue:((CGFloat)_blue)/255.0f alpha:((CGFloat)_alpha)/255.0f];
}

- (NSDictionary *)getRGBDictionaryByColor:(UIColor *)originColor
{
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [originColor getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(originColor.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @{@"R":@(r),
             @"G":@(g),
             @"B":@(b),
             @"A":@(a)};
}

- (XXTPixelColor *)init
{
    if (self = [super init]) {
        _red = 0;
        _green = 0;
        _blue = 0;
        _alpha = 0;
    }
    return self;
}

- (XXTPixelColor *)initWithUIColor:(UIColor *)uicolor
{
    self = [self init];
    [self setColorWithUIColor:uicolor];
    return self;
}

- (XXTPixelColor *)initWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(uint8_t)alpha
{
    self = [self init];
    [self setRed:red green:green blue:blue alpha:alpha];
    return self;
}

- (XXTPixelColor *)initWithColor:(uint32_t)color
{
    SZ_COLOR c;
    c.the_color = color;
    return [self initWithRed:c.red green:c.green blue:c.blue alpha:c.alpha];
}

- (XXTPixelColor *)initWithXXTColor:(XXTPixelColor *)xxtcolor
{
    return [self initWithRed:xxtcolor.red green:xxtcolor.green blue:xxtcolor.blue alpha:xxtcolor.alpha];
}

- (void)setRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(uint8_t)alpha
{
    _red = red;
    _green = green;
    _blue = blue;
    _alpha = alpha;
}

- (void)setColor:(uint32_t)color
{
    SZ_COLOR c;
    c.the_color = color;
    [self setRed:c.red green:c.green blue:c.blue alpha:c.alpha];
}

- (void)setColorWithUIColor:(UIColor *)uicolor
{
    @autoreleasepool {
        NSDictionary *colorDic = [self getRGBDictionaryByColor:uicolor];
        _red = (uint8_t)([colorDic[@"R"] floatValue] * 255);
        _green = (uint8_t)([colorDic[@"G"] floatValue] * 255);
        _blue = (uint8_t)([colorDic[@"B"] floatValue] * 255);
        _alpha = (uint8_t)([colorDic[@"A"] floatValue] * 255);
    }
}

- (uint8_t)red
{
    return _red;
}

- (void)setRed:(uint8_t)red
{
    _red = red;
}

- (uint8_t)green
{
    return _green;
}

- (void)setGreen:(uint8_t)green
{
    _green = green;
}

- (uint8_t)blue
{
    return _blue;
}

- (void)setBlue:(uint8_t)blue
{
    _blue = blue;
}

- (uint8_t)alpha
{
    return _alpha;
}

- (void)setAlpha:(uint8_t)alpha
{
    _alpha = alpha;
}

@end
