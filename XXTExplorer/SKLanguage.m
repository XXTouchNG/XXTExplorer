//
//  SKLanguage.m
//  XXTExplorer
//
//  Created by Zheng on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKLanguage.h"
#import "SKPattern.h"

@implementation SKLanguage

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        NSString *UUID = dictionary[@"uuid"];
        NSString *name = dictionary[@"name"];
        NSString *scopeName = dictionary[@"scopeName"];
        if (![UUID isKindOfClass:[NSString class]] || ![name isKindOfClass:[NSString class]] || ![scopeName isKindOfClass:[NSString class]]) {
            return nil;
        }
        _UUID = UUID;
        _name = name;
        _scopeName = scopeName;
        NSMutableDictionary <NSString *, SKPattern *> *repository = [@{} mutableCopy];
        NSDictionary <NSString *, NSDictionary *> *repo = dictionary[@"repository"];
        if ([repo isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in repo.allKeys) {
                NSDictionary *value = repo[key];
                SKPattern *pattern = [[SKPattern alloc] initWithDictionary:value parent:nil];
                repository[key] = pattern;
            }
        }
        NSMutableArray <SKPattern *> *patterns = [@[] mutableCopy];
        NSArray <NSDictionary *> *array = dictionary[@"patterns"];
        if ([array isKindOfClass:[NSArray class]]) {
            for (NSDictionary *value in array) {
                NSString *include = value[@"include"];
                if ([include isKindOfClass:[NSString class]]) {
                    NSRange range = [include rangeOfComposedCharacterSequenceAtIndex:0];
                    NSString *key = [include substringFromIndex:range.location + range.length]; // ?
                    SKPattern *pattern = repository[key];
                    if (pattern) {
                        [patterns addObject:pattern];
                        continue;
                    }
                }
                SKPattern *pattern = [[SKPattern alloc] initWithDictionary:value parent:nil];
                if (pattern) {
                    [patterns addObject:pattern];
                }
            }
        }
        _patterns = patterns;
    }
    return self;
}

@end
