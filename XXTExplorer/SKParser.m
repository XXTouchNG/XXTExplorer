//
//  SKParser.m
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKParser.h"
#import "SKPattern.h"
#import "SKLanguage.h"
#import "SKResult.h"
#import "SKResultSet.h"
#import "SKCapture.h"
#import "SKCaptureCollection.h"

@interface SKParser ()

@property (nonatomic, strong, readonly) NSMutableDictionary <NSString *, NSRegularExpression *> *expressionCaches;

@end

@implementation SKParser

- (instancetype)initWithLanguage:(SKLanguage *)language {
    if (self = [super init]) {
        _language = language;
        _expressionCaches = [@{} mutableCopy];
    }
    return self;
}

#pragma mark - Parsing

- (void)parseString:(NSString *)string matchCallback:(SKCallback)callback {
    NSString *s = string;
    NSUInteger length = s.length;
    NSUInteger paragraphEnd = 0;
    while (paragraphEnd < length) {
        NSUInteger paragraphStart = 0;
        NSUInteger contentsEnd = 0;
        [s getParagraphStart:&paragraphStart end:&paragraphEnd contentsEnd:&contentsEnd forRange:NSMakeRange(paragraphEnd, 0)];
        NSRange paragraphRange = NSMakeRange(paragraphStart, contentsEnd - paragraphStart);
        NSUInteger limit = NSMaxRange(paragraphRange);
        NSRange range = paragraphRange;
        // Loop through the line until we reach the end
        while (range.length > 0 && range.location < limit) {
            NSUInteger location = [self parseString:string inRange:range callback:callback];
            range.location = location;
            range.length = MAX(0, range.length - paragraphRange.location - range.location);
        }
    }
}

/// Returns new location
- (NSUInteger)parseString:(NSString *)string inRange:(NSRange)bounds callback:(SKCallback)callback {
    for (SKPattern *pattern in self.language.patterns) {
        @autoreleasepool {
            // Single pattern
            NSString *match = pattern.match;
            if (match) {
                SKResultSet *resultSet = [self parseString:string inRange:bounds scope:pattern.name expression:match captures:pattern.captures];
                if (resultSet) {
                    return [self applyResults:resultSet callback:callback];
                } else {
                    continue;
                }
            }
            // Begin & End
            NSString *begin = pattern.patternBegin;
            NSString *end = pattern.patternEnd;
            SKResultSet *beginResults = [self parseString:string inRange:bounds scope:nil expression:begin captures:pattern.beginCaptures];
            NSRange beginRange;
            if (!beginResults) {
                continue;
            }
            beginRange = beginResults.range;
            NSUInteger location = NSMaxRange(beginRange);
            NSRange endBounds = NSMakeRange(location, NSMaxRange(bounds) - location);
            SKResultSet *endResults = [self parseString:string inRange:endBounds scope:nil expression:end captures:pattern.endCaptures];
            NSRange endRange;
            if (!endResults) {
                continue; /* TODO: Rewind? */
            }
            endRange = endResults.range;
            // Add whole scope before start and end
            SKResultSet *results = [[SKResultSet alloc] init];
            NSString *name = pattern.name;
            if (name) {
                [results addResult:[[SKResult alloc] initWithScope:name range:NSUnionRange(beginRange, endRange)]];
            }
            [results addResults:beginResults];
            [results addResults:endResults];
            return [self applyResults:results callback:callback];
        }
    }
    return NSMaxRange(bounds);
}

/// Parse an expression with captures
- (SKResultSet *)parseString:(NSString *)string inRange:(NSRange)bounds scope:(NSString *)scope expression:(NSString *)expressionString captures:(SKCaptureCollection *)captures {
    NSArray <NSTextCheckingResult *> *matches = nil;
    @try {
        NSRegularExpression *expression = nil;
        NSRegularExpression *cachedExpression = self.expressionCaches[expressionString];
        if (cachedExpression) {
            expression = cachedExpression;
        } else {
            expression = [[NSRegularExpression alloc] initWithPattern:expressionString options:NSRegularExpressionCaseInsensitive error:nil];
            if (expression) {
                self.expressionCaches[expressionString] = expression;
            } else {
                return nil;
            }
        }
        matches = [expression matchesInString:string options:0 range:bounds];
    } @catch (NSException *exception) {
        return nil;
    }
    NSTextCheckingResult *result = [matches firstObject];
    if (!result) return nil;
    SKResultSet *resultSet = [[SKResultSet alloc] init];
    if (scope && result.range.location != NSNotFound) {
        [resultSet addResult:[[SKResult alloc] initWithScope:scope range:result.range]];
    }
    if (captures) {
        for (NSNumber *index in captures.captureIndexes) {
            NSRange range = [result rangeAtIndex:[index unsignedIntegerValue]];
            if (range.location == NSNotFound) {
                continue;
            }
            NSString *scope = captures[index].name;
            if (scope) {
                [resultSet addResult:[[SKResult alloc] initWithScope:scope range:range]];
            }
        }
    }
    if (![resultSet isEmpty]) {
        return resultSet;
    }
    return nil;
}

- (NSUInteger)applyResults:(SKResultSet *)resultSet callback:(SKCallback)callback {
    NSUInteger i = 0;
    for (SKResult *result in resultSet.results) {
        callback(result.scope, result.range);
        i = MAX(NSMaxRange(result.range), i);
    }
    return i;
}

@end
