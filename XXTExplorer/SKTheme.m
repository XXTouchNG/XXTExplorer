//
//  SKTheme.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKTheme.h"

@implementation SKTheme

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        NSString *UUID = dictionary[@"uuid"];
        NSString *name = dictionary[@"name"];
        NSArray <NSDictionary *> *rawStrings = dictionary[@"settings"];
        if (![UUID isKindOfClass:[NSString class]] || ![name isKindOfClass:[NSString class]] || ![rawStrings isKindOfClass:[NSArray class]]) {
            return nil;
        }
        _UUID = UUID;
        _name = name;
        NSMutableDictionary <NSString *, SKAttributes> *attributes = [@{} mutableCopy];
        for (NSDictionary *raw in rawStrings) {
            @autoreleasepool {
                NSString *scopes = raw[@"scope"];
                NSDictionary *settings = raw[@"settings"];
                if (![scopes isKindOfClass:[NSString class]] || ![settings isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                NSMutableDictionary *newSettings = [[NSMutableDictionary alloc] initWithCapacity:settings.count];
                NSString *foregroundValue = settings[@"foreground"];
                if ([foregroundValue isKindOfClass:[NSString class]]) {
                    newSettings[NSForegroundColorAttributeName] = [self colorFromHexString:foregroundValue];
                }
                NSString *backgroundValue = settings[@"background"];
                if ([backgroundValue isKindOfClass:[NSString class]]) {
                    newSettings[NSBackgroundColorAttributeName] = [self colorFromHexString:backgroundValue];
                }
                // TODO: caret, invisibles, lightHighlight, selection, font style
                for (NSString *scope in [scopes componentsSeparatedByString:@","]) {
                    NSString *key = [scope stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    attributes[key] = settings;
                }
            }
        }
        _attributes = attributes;
    }
    return self;
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    if ([hexString hasPrefix:@"#"]) {
        unsigned rgbValue = 0;
        NSScanner *colorScanner = [NSScanner scannerWithString:hexString];
        colorScanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"#"];
        [colorScanner scanHexInt:&rgbValue];
        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.f green:((rgbValue & 0xFF00) >> 8) / 255.f blue:(rgbValue & 0xFF) / 255.f alpha:1.f];
    }
    return [UIColor blackColor];
}

@end
