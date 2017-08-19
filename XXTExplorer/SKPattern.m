//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKPattern.h"
#import "SKRepository.h"
#import "SKReferenceManager.h"
#import "SKCaptureCollection.h"

@interface SKPattern ()

@end

@implementation SKPattern {

}

// MARK: - Initializers

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                            parent:(SKPattern *)parent
                        repository:(SKRepository *)repository
                           manager:(SKReferenceManager *)manager
{
    self = [super init];
    if (self)
    {
        _subpatterns = [[NSMutableArray alloc] init];
        _applyEndPatternLast = NO;
        _parent = parent;
        _name = dictionary[@"name"];
        NSString *matchExpr = dictionary[@"match"];
        if ([matchExpr isKindOfClass:[NSString class]]) {
            _match = [[NSRegularExpression alloc] initWithPattern:matchExpr
                                                          options:NSRegularExpressionAllowCommentsAndWhitespace |
                                                                  NSRegularExpressionAnchorsMatchLines |
                                                                  NSRegularExpressionUseUnixLineSeparators
                                                            error:nil];
        }
        NSString *beginExpr = dictionary[@"begin"];
        if ([beginExpr isKindOfClass:[NSString class]]) {
            _patternBegin = [[NSRegularExpression alloc] initWithPattern:beginExpr
                                                                 options:NSRegularExpressionAllowCommentsAndWhitespace |
                                                                         NSRegularExpressionAnchorsMatchLines |
                                                                         NSRegularExpressionUseUnixLineSeparators
                                                                   error:nil];
        }
        NSString *endExpr = dictionary[@"end"];
        if ([endExpr isKindOfClass:[NSString class]]) {
            _patternEnd = [[NSRegularExpression alloc] initWithPattern:endExpr
                                                               options:NSRegularExpressionAllowCommentsAndWhitespace |
                                                                       NSRegularExpressionAnchorsMatchLines |
                                                                       NSRegularExpressionUseUnixLineSeparators
                                                                 error:nil];
        }
        _applyEndPatternLast = [dictionary[@"applyEndPatternLast"] boolValue];
        NSDictionary *dictionary1 = dictionary[@"beginCaptures"];
        if ([dictionary1 isKindOfClass:[NSDictionary class]]) {
            _beginCaptures = [[SKCaptureCollection alloc] initWithDictionary:dictionary1];
        }
        NSDictionary *dictionary2 = dictionary[@"captures"];
        if ([dictionary2 isKindOfClass:[NSDictionary class]]) {
            if (_match != nil) {
                _captures = [[SKCaptureCollection alloc] initWithDictionary:dictionary2];
            } else if (_patternBegin != nil && _patternEnd != nil) {
                _beginCaptures = [[SKCaptureCollection alloc] initWithDictionary:dictionary2];
                _endCaptures = _beginCaptures;
            }
        }
        NSDictionary *dictionary3 = dictionary[@"endCaptures"];
        if ([dictionary3 isKindOfClass:[NSDictionary class]]) {
            _endCaptures = [[SKCaptureCollection alloc] initWithDictionary:dictionary3];
        }
        if (
                (dictionary[@"match"] != nil && _match == nil) ||
                        (dictionary[@"begin"] != nil && (_patternBegin == nil || _patternEnd == nil)) ||
                        (_match == nil && _patternBegin == nil && _patternEnd == nil && (dictionary[@"patterns"] == nil || [dictionary[@"patterns"] count] == 0)))
        {
            return nil;
        }
        NSArray <NSDictionary *> *array = dictionary[@"patterns"];
        if ([array isKindOfClass:[NSArray class]]) {
            _subpatterns = [manager patternsForPatterns:array inRepository:repository caller:self];
        }
    }
    return self;
}

- (instancetype)initWithPattern:(SKPattern *)pattern parent:(SKPattern *)parent {
    self = [super init];
    if (self)
    {
        _subpatterns = [[NSMutableArray alloc] init];
        _applyEndPatternLast = NO;
        _name = [pattern name];
        _match = [pattern match];
        _captures = [pattern captures];
        _patternBegin = [pattern patternBegin];
        _beginCaptures = [pattern beginCaptures];
        _patternEnd = [pattern patternEnd];
        _endCaptures = [pattern endCaptures];
        _parent = [pattern parent];
    }
    return self;
}

@end
