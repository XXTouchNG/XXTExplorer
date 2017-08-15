//
//  SKTheme.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKTheme.h"

// SKThemeFontStyle
static NSString * const SKThemeFontStyleRegular = @"regular";
static NSString * const SKThemeFontStyleUnderline = @"underline";
static NSString * const SKThemeFontStyleBold = @"bold";
static NSString * const SKThemeFontStyleItalic = @"italic";
static NSString * const SKThemeFontStyleBoldItalic = @"bolditalic";
static NSString * const SKThemeFontStyleStrikeThrough = @"strikethrough";

// NSMutableDictionary - Category
@interface NSMutableDictionary (RemoveValue)

- (id)removeValueForKey:(id)key;

@end

@implementation NSMutableDictionary (RemoveValue)

- (id)removeValueForKey:(id)key {
    id value = [self objectForKey:key];
    if (value) [self removeObjectForKey:key];
    return value;
}

@end

// UIColor - Category

@interface UIColor (Hex)

+ (UIColor *)colorWithHex:(NSString *)hex;

@end

@implementation UIColor (Hex)

+ (UIColor *)colorWithHex:(NSString *)representation {
    NSString *hex = representation;
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    } else if ([hex hasPrefix:@"0x"]) {
        hex = [hex substringFromIndex:2];
    }
    NSUInteger length = hex.length;
    if (length != 3 && length != 6 && length != 8)
        return nil;
    if (length == 3) {
        NSString *r = [hex substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [hex substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [hex substringWithRange:NSMakeRange(2, 1)];
        hex = [NSString stringWithFormat:@"%@%@%@%@%@%@ff", r, r, g, g, b, b];
    } else if (length == 6) {
        hex = [NSString stringWithFormat:@"%@ff", hex];
    }
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    unsigned int rgbaValue = 0;
    [scanner scanHexInt:&rgbaValue];
    return [self colorWithRed:((rgbaValue & 0xFF000000) >> 24) / 255.f
                        green:((rgbaValue & 0xFF0000) >> 16) / 255.f
                         blue:((rgbaValue & 0xFF00) >> 8) / 255.f
                        alpha:((rgbaValue & 0xFF)) / 255.f];
}

@end

@interface SKTheme ()

@property (nonatomic, strong, readonly) NSDictionary <NSString *, id> *globalAttributes;

@end

@implementation SKTheme

#pragma mark - Global Scope Properties

- (UIColor *)getBackgroundColor {
    return self.globalAttributes[@"background"];
}

- (UIColor *)getForegroundColor {
    return self.globalAttributes[@"foreground"];
}

- (UIColor *)getCaretColor {
    return self.globalAttributes[@"caret"];
}

- (UIColor *)getSelectionColor {
    return self.globalAttributes[@"selection"];
}

#pragma mark - Initializer

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary font:(UIFont *)font {
    self = [super init];
    if (self)
    {
        NSString *uuidString = dictionary[@"uuid"];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
        NSString *name = dictionary[@"name"];
        NSArray <NSDictionary <NSString *, id> *> *rawSettings = dictionary[@"settings"];
        if (![uuid isKindOfClass:[NSUUID class]] ||
            ![name isKindOfClass:[NSString class]] ||
            ![rawSettings isKindOfClass:[NSArray class]] ||
            ![font isKindOfClass:[UIFont class]])
        {
            return nil;
        }
        UIFont *boldFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0];
        UIFont *italicFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:0];
        UIFont *boldItalicFont = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic] size:0];
        if (!boldFont || !italicFont || !boldItalicFont) {
            return nil;
        }
        _uuid = uuid;
        _name = name;
        NSMutableDictionary <NSString *, SKAttributes> *attributes = [[NSMutableDictionary alloc] init];
        for (NSDictionary <NSString *, id> *raw in rawSettings) {
            NSMutableDictionary <NSString *, id> *setting = [raw[@"settings"] mutableCopy];
            if (![setting isKindOfClass:[NSMutableDictionary class]])
                continue;
            NSString *value = nil;
            value = [setting removeValueForKey:@"foreground"];
            if (value) setting[NSForegroundColorAttributeName] = [UIColor colorWithHex:value];
            value = [setting removeValueForKey:@"background"];
            if (value) setting[NSBackgroundColorAttributeName] = [UIColor colorWithHex:value];
            value = [setting removeValueForKey:@"fontStyle"];
            if (value) {
                if ([value isEqualToString:SKThemeFontStyleBold]) {
                    setting[NSFontAttributeName] = boldFont;
                }
                else if ([value isEqualToString:SKThemeFontStyleItalic]) {
                    setting[NSFontAttributeName] = italicFont;
                }
                else if ([value isEqualToString:SKThemeFontStyleBoldItalic]) {
                    setting[NSFontAttributeName] = boldItalicFont;
                }
                else if ([value isEqualToString:SKThemeFontStyleUnderline]) {
                    setting[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                }
                else if ([value isEqualToString:SKThemeFontStyleStrikeThrough]) {
                    setting[NSBaselineOffsetAttributeName] = @(0);
                    setting[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                }
                else if ([value isEqualToString:SKThemeFontStyleRegular]) {
                    setting[NSFontAttributeName] = font;
                }
            }
            NSString *patternIdentifiers = raw[@"scope"];
            if ([patternIdentifiers isKindOfClass:[NSString class]]) {
                for (NSString *patternIdentifier in [patternIdentifiers componentsSeparatedByString:@"."]) {
                    NSString *key = [patternIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    attributes[key]= setting;
                }
            } else if (setting.count > 0) {
                _globalAttributes = [self parseGlobalScopeAttributes:raw[@"settings"]];
            }
        }
        _attributes = attributes;
    }
    return self;
}

- (NSDictionary <NSString *, id> *)parseGlobalScopeAttributes:(NSDictionary *)raw {
    NSMutableDictionary <NSString *, id> *setting = [raw mutableCopy];
    NSString *value = nil;
    value = [setting removeValueForKey:@"foreground"];
    if (value) setting[@"foreground"] = [UIColor colorWithHex:value];
    value = [setting removeValueForKey:@"background"];
    if (value) setting[@"background"] = [UIColor colorWithHex:value];
    value = [setting removeValueForKey:@"caret"];
    if (value) setting[@"caret"] = [UIColor colorWithHex:value];
    value = [setting removeValueForKey:@"selection"];
    if (value) setting[@"selection"] = [UIColor colorWithHex:value];
    return [[NSDictionary alloc] initWithDictionary:setting];
}

@end
