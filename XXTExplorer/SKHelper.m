//
//  SKHelper.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKHelper.h"
#import "SKLanguage.h"
#import "SKTheme.h"
#import "SKParser.h"
#import "SKAttributedParser.h"

@implementation SKHelper

- (instancetype)initWithBundle:(NSBundle *)bundle {
    if (self = [super init]) {
        _bundle = bundle;
        if (!bundle) {
            _bundle = [NSBundle mainBundle];
        }
    }
    return self;
}

- (NSString *)fixtureWithName:(NSString *)name type:(NSString *)type {
    NSString *path = [self.bundle pathForResource:name ofType:type];
    assert(path);
    return [[NSString alloc] initWithData:[[NSData alloc] initWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
}

- (SKLanguage *)languageWithName:(NSString *)name {
    NSString *path = [self.bundle pathForResource:name ofType:@"tmLanguage"];
    assert(path);
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    if (plist) {
        return [[SKLanguage alloc] initWithDictionary:plist];
    }
    return nil;
}

- (SKTheme *)themeWithName:(NSString *)name {
    NSString *path = [self.bundle pathForResource:name ofType:@"tmTheme"];
    assert(path);
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    if (plist) {
        return [[SKTheme alloc] initWithDictionary:plist];
    }
    return nil;
}

+ (NSAttributedString *)test:(NSString *)path {
    SKHelper *helper = [[SKHelper alloc] initWithBundle:nil];
    SKLanguage *luaLanguage = [helper languageWithName:@"Lua"];
    SKTheme *theme = [helper themeWithName:@"Mac Classic"];
    assert(luaLanguage);
    assert(theme);
//    SKParser *parser = [[SKParser alloc] initWithLanguage:luaLanguage];
    SKAttributedParser *parser = [[SKAttributedParser alloc] initWithLanguage:luaLanguage theme:theme];
    assert(parser);
//    NSString *input = [helper fixtureWithName:@"test" type:@"lua"];
    NSString *input = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
    assert(input);
    [parser parseString:input matchCallback:^(NSString *scope, NSRange range, SKAttributes attributes) {
        NSLog(@"content: %@, scope: %@, location: %lu, length: %lu, = %@", [input substringWithRange:range], scope, range.location, range.length, attributes);
    }];
    NSDictionary *baseAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"CourierNewPSMT" size:14.f] };
    return [parser parseString:input baseAttributes:baseAttributes];
}

@end
