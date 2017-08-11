//
//  XXTETextEditorTheme.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextEditorTheme.h"
#import "XXTExplorer-Swift.h"

@implementation XXTETextEditorTheme

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        _backgroundColor = UIColor.whiteColor;
        _foregroundColor = UIColor.blackColor;
        _caretColor = XXTE_COLOR;
        _selectionColor = XXTE_COLOR;
        NSString *themePath = [[NSBundle mainBundle] pathForResource:identifier ofType:@"tmTheme"];
        if (themePath) {
            NSDictionary *themeDictionary = [[NSDictionary alloc] initWithContentsOfFile:themePath];
            if (themeDictionary) {
                NSArray <NSDictionary *> *themeSettings = themeDictionary[@"settings"];
                NSDictionary *globalTheme = nil;
                for (NSDictionary *themeSetting in themeSettings) {
                    if (!themeSetting[@"scope"]) {
                        globalTheme = themeSetting[@"settings"];
                        break;
                    }
                }
                if (globalTheme) {
                    [self setupWithDictionary:globalTheme];
                }
            }
        }
    }
    return self;
}

- (void)setupWithDictionary:(NSDictionary *)dictionary {
    self.backgroundColor = [self colorFromHexString:dictionary[@"background"]];
    self.foregroundColor = [self colorFromHexString:dictionary[@"foreground"]];
    self.caretColor = [self colorFromHexString:dictionary[@"caret"]];
    self.selectionColor = [self colorFromHexString:dictionary[@"selection"]];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    if ([hexString hasPrefix:@"#"]) {
        unsigned rgbValue = 0;
        NSScanner *colorScanner = [NSScanner scannerWithString:hexString];
        colorScanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"#"];
        [colorScanner scanHexInt:&rgbValue];
        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.f green:((rgbValue & 0xFF00) >> 8) / 255.f blue:(rgbValue & 0xFF) / 255.f alpha:1.f];
    } else if ([hexString hasPrefix:@"rgb"]) {
        NSScanner *colorScanner = [NSScanner scannerWithString:[hexString substringFromIndex:3]];
        colorScanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"(,)"];
        int r = 0, g = 0, b = 0;
        [colorScanner scanInt:&r]; [colorScanner scanInt:&g]; [colorScanner scanInt:&b];
        return [UIColor colorWithRed:((r) >> 16) / 255.f green:((g) >> 8) / 255.f blue:(b) / 255.f alpha:1.f];
    }
    return [UIColor blackColor];
}

@end
