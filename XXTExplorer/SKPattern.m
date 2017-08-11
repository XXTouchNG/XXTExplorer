//
//  SKPattern.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/11.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKPattern.h"
#import "SKCaptureCollection.h"

@interface SKPattern ()

@property (nonatomic, weak, readonly) SKPattern *parent;
@property (nonatomic, strong, readonly) NSMutableArray <SKPattern *> *patterns;

@end

@implementation SKPattern

- (SKPattern *)superPattern {
    return self.parent;
}

- (NSArray <SKPattern *> *)subPatterns {
    return self.patterns;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                            parent:(SKPattern *)superPattern {
    if (self = [super init]) {
        _parent = superPattern;
        _name = dictionary[@"name"];
        _match = dictionary[@"match"];
        _patternBegin = dictionary[@"begin"];
        _patternEnd = dictionary[@"end"];
        NSDictionary *dictionary1 = nil;
        dictionary1 = dictionary[@"beginCaptures"];
        if ([dictionary1 isKindOfClass:[NSDictionary class]]) {
            _beginCaptures = [[SKCaptureCollection alloc] initWithDictionary:dictionary1];
        } else {
            _beginCaptures = nil;
        }
        dictionary1 = dictionary[@"captures"];
        if ([dictionary1 isKindOfClass:[NSDictionary class]]) {
            _captures = [[SKCaptureCollection alloc] initWithDictionary:dictionary1];
        } else {
            _captures = nil;
        }
        dictionary1 = dictionary[@"endCaptures"];
        if ([dictionary1 isKindOfClass:[NSDictionary class]]) {
            _endCaptures = [[SKCaptureCollection alloc] initWithDictionary:dictionary1];
        } else {
            _endCaptures = nil;
        }
        NSMutableArray <SKPattern *> *patterns = [@[] mutableCopy];
        NSArray <NSDictionary *> *array = dictionary[@"patterns"];
        if ([array isKindOfClass:[NSArray class]]) {
            for (NSDictionary *value in array) {
                SKPattern *pattern = [[SKPattern alloc] initWithDictionary:value parent:superPattern];
                if (pattern)
                    [patterns addObject:pattern];
            }
        }
        _patterns = patterns;
    }
    return self;
}

@end
