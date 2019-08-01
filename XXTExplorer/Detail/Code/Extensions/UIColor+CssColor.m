//
//  UIColor+CssColor.m
//  XXTExplorer
//
//  Created by Darwin on 8/1/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "UIColor+CssColor.h"

@implementation UIColor (CssColor)

+ (UIColor *)colorWithCssName:(NSString *)name {
    static NSDictionary *cssColorScheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"References.bundle/CssColorSchemes" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        cssColorScheme = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil] : nil;
    });
    if (!name) {
        return nil;
    }
    NSArray <NSNumber *> *colorPair = cssColorScheme[name];
    if (colorPair) {
        return [UIColor colorWithRed:([colorPair[0] doubleValue] / 255.0) green:([colorPair[1] doubleValue] / 255.0) blue:([colorPair[2] doubleValue] / 255.0) alpha:1.0];
    }
    return nil;
}

@end
