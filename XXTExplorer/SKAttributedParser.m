//
//  SKAttributedParser.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKAttributedParser.h"

@implementation SKAttributedParser

- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme {
    _theme = theme;
    if (self = [super initWithLanguage:language]) {
        
    }
    return self;
}

- (void)parseString:(NSString *)string matchCallback:(SKAttributedCallback)callback {
    [super parseString:string matchCallback:^(NSString *scope, NSRange range) {
        callback(scope, range, [self attributesForScope:scope]);
    }];
}

- (NSAttributedString *)parseString:(NSString *)string baseAttributes:(SKAttributes)baseAttributes {
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:string attributes:baseAttributes];
    [self parseString:string matchCallback:^(NSString *scope, NSRange range, SKAttributes attributes) {
        if (attributes) {
            [output addAttributes:attributes range:range];
        }
    }];
    return [[NSAttributedString alloc] initWithAttributedString:output];
}

- (SKAttributes)attributesForScope:(NSString *)scope {
    NSArray <NSString *> *components = [scope componentsSeparatedByString:@"."];
    NSUInteger count = components.count;
    if (count == 0) {
        return nil;
    }
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *key = ([[components subarrayWithRange:NSMakeRange(0, count - 1 - i)] componentsJoinedByString:@"."]);
        NSDictionary *attrs = self.theme.attributes[key];
        if (attrs) {
            for (NSString *k in attrs.allKeys) {
                id v = attrs[k];
                attributes[k] = v;
            }
        }
    }
    if (attributes.count == 0) {
        return nil;
    }
    return attributes;
}

@end
