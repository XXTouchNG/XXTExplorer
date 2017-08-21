//
//  XXTETextEditorTheme.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextEditorTheme.h"
#import "UIColor+SKColor.h"

@implementation XXTETextEditorTheme

- (instancetype)initWithIdentifier:(NSString *)identifier font:(UIFont *)font {
    if (self = [super init]) {
        _font = font;
        _identifier = identifier;
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
    _backgroundColor = [UIColor colorWithHex:dictionary[@"background"]];
    _foregroundColor = [UIColor colorWithHex:dictionary[@"foreground"]];
    _caretColor = [UIColor colorWithHex:dictionary[@"caret"]];
    _selectionColor = [UIColor colorWithHex:dictionary[@"selection"]];
}

- (NSDictionary *)defaultAttributes {
    return @{ NSForegroundColorAttributeName: self.foregroundColor, NSBackgroundColorAttributeName: self.backgroundColor, NSFontAttributeName: self.font };
}

@end
