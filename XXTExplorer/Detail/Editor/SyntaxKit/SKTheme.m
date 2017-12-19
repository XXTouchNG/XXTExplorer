//
//  SKTheme.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKTheme.h"
#import "SKLanguage.h"
#import "UIColor+SKColor.h"

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

- (NSDictionary <NSString *, id> *)globalAttributes {
    return self.attributes[SKLanguageGlobalScope];
}

#pragma mark - Initializer

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary baseFonts:(NSArray <UIFont *> *)baseFonts {
    self = [super init];
    if (self)
    {
        NSString *uuidString = dictionary[@"uuid"];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
        NSString *name = dictionary[@"name"];
        NSArray <NSDictionary <NSString *, id> *> *rawSettings = dictionary[@"settings"];
        if (
            ![uuid isKindOfClass:[NSUUID class]] ||
            ![name isKindOfClass:[NSString class]] ||
            ![rawSettings isKindOfClass:[NSArray class]] ||
            ![baseFonts isKindOfClass:[NSArray class]] ||
            baseFonts.count != 4
            )
        {
            return nil;
        }
        UIFont *regularFont = baseFonts[0];
        UIFont *boldFont = baseFonts[1];
        UIFont *italicFont = baseFonts[2];
        UIFont *boldItalicFont = baseFonts[3];
        _uuid = uuid;
        _name = name;
        NSMutableDictionary <NSString *, SKAttributes> *attributes = [[NSMutableDictionary alloc] init];
        for (NSDictionary <NSString *, id> *raw in rawSettings) {
            NSMutableDictionary <NSString *, id> *setting = [raw[@"settings"] mutableCopy];
            if (![setting isKindOfClass:[NSDictionary class]])
                continue;
            NSString *value = nil;
            value = [setting removeValueForKey:@"foreground"];
            if (value) setting[NSForegroundColorAttributeName] = [UIColor colorWithHex:value];
            value = [setting removeValueForKey:@"background"];
            if (value) setting[NSBackgroundColorAttributeName] = [UIColor colorWithHex:value];
            value = [setting removeValueForKey:@"fontStyle"];
            if ([value isKindOfClass:[NSString class]]) {
                NSArray <NSString *> *valueStyles = [value componentsSeparatedByString:@" "];
                for (NSString *valueStyle in valueStyles) {
                    if ([valueStyle isEqualToString:SKThemeFontStyleBold]) {
                        setting[NSFontAttributeName] = boldFont;
                    }
                    else if ([valueStyle isEqualToString:SKThemeFontStyleItalic]) {
                        setting[NSFontAttributeName] = italicFont;
                    }
                    else if ([valueStyle isEqualToString:SKThemeFontStyleBoldItalic]) {
                        setting[NSFontAttributeName] = boldItalicFont;
                    }
                    else if ([valueStyle isEqualToString:SKThemeFontStyleUnderline]) {
                        setting[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                    }
                    else if ([valueStyle isEqualToString:SKThemeFontStyleStrikeThrough]) {
                        setting[NSBaselineOffsetAttributeName] = @(0);
                        setting[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                    }
                    else if ([valueStyle isEqualToString:SKThemeFontStyleRegular]) {
                        setting[NSFontAttributeName] = regularFont;
                    }
                }
            }
            NSString *patternIdentifiers = raw[@"scope"];
            if ([patternIdentifiers isKindOfClass:[NSString class]]) {
                for (NSString *patternIdentifier in [patternIdentifiers componentsSeparatedByString:@","]) {
                    NSString *key = [patternIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    attributes[key]= setting;
                }
            } else if (setting.count > 0) {
                attributes[SKLanguageGlobalScope] = [self parseGlobalScopeAttributes:raw[@"settings"]];
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
