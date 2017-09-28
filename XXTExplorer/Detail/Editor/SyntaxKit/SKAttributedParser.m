//
// Created by Zheng on 19/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKAttributedParser.h"


@implementation SKAttributedParser {

}

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme {
    _theme = theme;
    if (self = [super initWithLanguage:language]) {

    }
    return self;
}

// MARK: - Parsing
- (void)attributedParseString:(NSString *)string matchCallback:(SKAttributedParserCallback)callback {
    [super parseString:string matchCallback:^(NSString *scopeName, NSRange localRange) {
        callback(scopeName, localRange, [self attributesForScope:scopeName]);
    }];
}

- (void)attributedParseString:(NSString *)string inRange:(NSRange)range matchCallback:(SKAttributedParserCallback)callback {
    [super parseString:string inRange:range matchCallback:^(NSString *scopeName, NSRange localRange) {
        callback(scopeName, localRange, [self attributesForScope:scopeName]);
    }];
}

- (void)attributedParseStringInRange:(NSRange)range matchCallback:(SKAttributedParserCallback)callback {
    [super parseInRange:range matchCallback:^(NSString *scopeName, NSRange localRange) {
        callback(scopeName, localRange, [self attributesForScope:scopeName]);
    }];
}

- (NSAttributedString *)attributedStringForString:(NSString *)string baseAttributes:(NSDictionary *)baseAttributes {
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:string attributes:baseAttributes];
    [output beginEditing];
    [self attributedParseString:string matchCallback:^(NSString *scope, NSRange range, SKAttributes attributes) {
        if (attributes) {
            [output addAttributes:attributes range:range];
        }
    }];
    [output endEditing];
    return output;
}

// MARK: - Private

- (SKAttributes)attributesForScope:(NSString *)scope {
    NSArray <NSString *> *components = [scope componentsSeparatedByString:@"."];
    NSUInteger count = components.count;
    if (count == 0) {
        return nil;
    }
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    for (NSUInteger i = 0; i < count; i++) {
        NSString *key = ([[components subarrayWithRange:NSMakeRange(0, i)] componentsJoinedByString:@"."]);
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
