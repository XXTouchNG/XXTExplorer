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
    self.backgroundColor = [[UIColor alloc] initWithHex:dictionary[@"background"]];
    self.foregroundColor = [[UIColor alloc] initWithHex:dictionary[@"foreground"]];
    self.caretColor = [[UIColor alloc] initWithHex:dictionary[@"caret"]];
    self.selectionColor = [[UIColor alloc] initWithHex:dictionary[@"selection"]];
}

@end
