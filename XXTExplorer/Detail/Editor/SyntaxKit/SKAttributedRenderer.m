//
//  SKAttributedRenderer.m
//  XXTExplorer
//
//  Created by Zheng on 13/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKAttributedRenderer.h"

@implementation SKAttributedRenderer {
    
}

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme {
    _theme = theme;
    if (self = [super initWithLanguage:language]) {
        
    }
    return self;
}

// MARK: - Render

- (void)attributedRenderString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    [attributedString beginEditing];
    [super parseString:attributedString.string inRange:range matchCallback:^(NSString *scopeName, NSRange localRange) {
        NSDictionary *attributes = [self attributesForScope:scopeName];
        if (attributes) {
            [attributedString addAttributes:attributes range:localRange];
        }
    }];
    [attributedString endEditing];
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
