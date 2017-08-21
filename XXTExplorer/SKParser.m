//
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKParser.h"
#import "SKLanguage.h"
#import "SKScopedString.h"
#import "SKResultSet.h"
#import "SKCaptureCollection.h"
#import "SKResult.h"
#import "SKPattern.h"
#import "SKCapture.h"

@interface SKPatternMatch : NSObject

@property (nonatomic, strong, readonly) SKPattern *pattern;
@property (nonatomic, strong, readonly) SKResultSet *match;

- (instancetype)initWithPattern:(SKPattern *)pattern match:(SKResultSet *)match;

@end

@implementation SKPatternMatch

- (instancetype)initWithPattern:(SKPattern *)pattern match:(SKResultSet *)match {
    self = [super init];
    if (self)
    {
        if (!pattern || !match) return nil;
        _pattern = pattern;
        _match = match;
    }
    return self;
}

@end

@implementation SKParser {

}

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language {
    self = [super init];
    if (self)
    {
        _language = language;
    }
    return self;
}

// MARK: - Public

- (void)parseString:(NSString *)string matchCallback:(SKParserCallback)callback {
    if (_aborted) return;
    self.toParse = [[SKScopedString alloc] initWithString:string];
    [self parseInRange:NSMakeRange(0, string.length) matchCallback:callback];
}

- (void)parseString:(NSString *)string inRange:(NSRange)range matchCallback:(SKParserCallback)callback {
    if (_aborted) return;
    self.toParse = [[SKScopedString alloc] initWithString:string];
    [self parseInRange:range matchCallback:callback];
}

/// Parses the string in toParse. Supports incremental parsing.
///
/// - parameter range:  The range that should be re-parsed or nil if the
///                     entire string should be parsed. It may be exceeded
///                     if necessary to match a pattern entirely. For
///                     calculation of such a range take a look at
///                     outdatedRange(in: forChange:).
/// - parameter match:  The callback to call on every match of a pattern
///                     identifier of the language.
- (void)parseInRange:(NSRange)range matchCallback:(SKParserCallback)callback {
    if (!self.toParse) return;
    NSRange bounds = range;
    assert((self.toParse.string).length >= NSMaxRange(bounds));
    SKScope *endScope = [self.toParse topMostScopeAtIndex:bounds.location];
    NSUInteger startIndex = bounds.location;
    NSUInteger endIndex = NSMaxRange(bounds);
    SKResultSet *allResults = [[SKResultSet alloc] initWithStartingRange:bounds];
    while (startIndex < endIndex)
    {
        SKPattern *endPattern = endScope.attribute ? endScope.attribute : self.language.pattern;
        SKResultSet *results = [self matchSubpatternsOfPattern:endPattern inRange:NSMakeRange(startIndex, endIndex - startIndex)];
        if (!results) return;
        [allResults addResult:[[SKResult alloc] initWithIdentifier:endScope.patternIdentifier range:results.range attribute:nil]];

        if (results.range.length != 0)
        {
            [allResults addResultSet:results];
            startIndex = NSMaxRange(results.range);
            endScope = [self.toParse lowerScopeForScope:endScope atIndex:startIndex];
        } else {
            startIndex = endIndex;
        }

        if (startIndex > endIndex && [self.toParse isInStringAtIndex:startIndex + 1]) {
            SKScope *scopeAtIndex = [self.toParse topMostScopeAtIndex:startIndex + 1];
            if ([self.toParse levelForScope:scopeAtIndex] > [self.toParse levelForScope:endScope]) {
                endIndex = NSMaxRange(scopeAtIndex.range);
            }
        }
    }

    if (self.aborted) return;
    [self.toParse removeScopesInRange:allResults.range];
    [self applyResults:allResults callback:callback];
}

// MARK: - Private

// Algorithmic notes:
// A pattern expression can not match a substring spanning multiple lines
// so in the outer loop the string is decomposed into its lines.
// In the inner loop it tries to repeatedly match a pattern followed by the
// end pattern until either the line is consumed or it has found the end.
// This procedure is repeated with the subsequent lines until it has either
// matched the end pattern or the string is consumed entirely.
// If it can find neither in a line it moves to the next one.

// Implementation note:
// The matching of the middle part may return a match that goes beyond the
// given range. This is intentional.

/// Matches subpatterns of the given pattern in the input.
///
/// - parameter pattern:    The patterns whose subpatterns should be matched
/// - parameter range:      The range in which the matching should occur.
///
/// - returns:  The result set containing the lexical scope names with range
///             information or nil if aborted. May exceed range.
- (SKResultSet *)matchSubpatternsOfPattern:(SKPattern *)pattern inRange:(NSRange)range {
    NSUInteger stop = range.location + range.length;
    NSUInteger lineStart = range.location;
    NSUInteger lineEnd = range.location;
    SKResultSet *result = [[SKResultSet alloc] initWithStartingRange:NSMakeRange(range.location, 0)];
    while (lineEnd < stop) {
        [self.toParse.string getLineStart:nil end:&lineEnd contentsEnd:nil forRange:NSMakeRange(lineEnd, 0)];
        NSRange range1 = NSMakeRange(lineStart, lineEnd - lineStart);
        while (range1.length > 0) {
            if (self.aborted) return nil;
            SKPatternMatch *bestMatchForMiddle = [self matchPatterns:pattern.subpatterns inRange:range1];
            NSRegularExpression *patternEnd = pattern.patternEnd;
            if (patternEnd) {
                SKResultSet *endMatchResult = [self matchExpression:patternEnd inRange:range1 captures:pattern.endCaptures baseSelector:nil];
                if (endMatchResult) {
                    SKPatternMatch *middleMatch = bestMatchForMiddle;
                    if (middleMatch) {
                        if ((!pattern.applyEndPatternLast && endMatchResult.range.location <= middleMatch.match.range.location) || endMatchResult.range.location < middleMatch.match.range.location) {
                            [result addResultSet:endMatchResult];
                            return result;
                        }
                    } else {
                        [result addResultSet:endMatchResult];
                        return result;
                    }
                }
            }
            SKPatternMatch *middleMatch = bestMatchForMiddle;
            if (!middleMatch) {
                break;
            }
            SKResultSet *middleResult = middleMatch.pattern.match != nil ? middleMatch.match : [self matchAfterBeginOfPattern:middleMatch.pattern beginResults:middleMatch.match];
            if (!middleResult) {
                break;
            }
            if (middleResult.range.length == 0) {
                break;
            }
            [result addResultSet:middleResult];
            NSUInteger newStart = NSMaxRange(middleResult.range);
            range1 = NSMakeRange(newStart, MAX(0, (NSInteger)(range1.length - (newStart - range1.location))));
            lineEnd = MAX((NSInteger)lineEnd, (NSInteger)newStart);
        }
        lineStart = lineEnd;
    }
    [result extendWithRange:range];
    return result;
}

/// Helper method that iterates over the given patterns and tries to match
/// them. Returns the matched pattern with the highest priority
/// (first criterion: matched sooner, second: higher up the list).
///
/// - parameter patterns:   The patterns that can be matched
/// - parameter range:      The range in which the matching should happen.
///
/// - returns:  The matched pattern and the matching result. Nil on failure.
///             The results range may exceed the passed in range.
- (SKPatternMatch *)matchPatterns:(NSArray <SKPattern *> *)patterns inRange:(NSRange)range {
    NSRange interestingBounds = range;
    SKPatternMatch *bestResult = nil;
    for (SKPattern *pattern in patterns) {
        SKPatternMatch *currentMatch = [self firstMatchOfPattern:pattern inRange:range];
        if (currentMatch && currentMatch.match.range.location == range.location) {
            return currentMatch;
        } else {
            SKPatternMatch *currMatch = currentMatch;
            if (currMatch) {
                SKPatternMatch *best = bestResult;
                if (best) {
                    if (currMatch.match.range.location < best.match.range.location) {
                        bestResult = currentMatch;
                        interestingBounds.length = currMatch.match.range.location - interestingBounds.location;
                    }
                } else {
                    bestResult = currentMatch;
                    interestingBounds.length = currMatch.match.range.location - interestingBounds.location;
                }
            }
        }
    }
    return bestResult;
}

/// Matches a single pattern in the string in the given range
///
/// - parameter pattern:    The Pattern to match in the string
/// - parameter range:      The range in which to match the pattern
///
/// - returns: The matched pattern and the matching result. Nil on failure.
- (SKPatternMatch *)firstMatchOfPattern:(SKPattern *)pattern inRange:(NSRange)range {
    NSRegularExpression *expression = pattern.match;
    if (expression) {
        SKResultSet *resultSet = [self matchExpression:expression inRange:range captures:pattern.captures baseSelector:pattern.name];
        if (resultSet.range.length != 0) {
            return [[SKPatternMatch alloc] initWithPattern:pattern match:resultSet];
        }
    } else {
        NSRegularExpression *begin = pattern.patternBegin;
        if (begin) {
            SKResultSet *beginResults = [self matchExpression:begin inRange:range captures:pattern.beginCaptures baseSelector:nil];
            return [[SKPatternMatch alloc] initWithPattern:pattern match:beginResults];
        } else if (pattern.subpatterns.count >= 1) {
            return [self matchPatterns:pattern.subpatterns inRange:range];
        }
    }
    return nil;
}

// Implementation note:
// The order in which the beginning middle and end are added to the final
// result matters.

/// Matches the middle and end of the given pattern
///
/// - parameter pattern:    The pattern whose subpatterns and end pattern
///                         has to be matched
/// - parameter begin:      The match result of the beginning
/// - returns:  The result of matching the given pattern or nil on abortion.
- (SKResultSet *)matchAfterBeginOfPattern:(SKPattern *)pattern beginResults:(SKResultSet *)begin {
    NSUInteger newLocation = NSMaxRange(begin.range);
    SKResultSet *endResults = [self matchSubpatternsOfPattern:pattern inRange:NSMakeRange(newLocation, self.toParse.string.length - newLocation)];
    if (!endResults) return nil;
    SKResultSet *result = [[SKResultSet alloc] initWithStartingRange:endResults.range];
    NSString *patternName = pattern.name;
    if (patternName) {
        [result addResult:[[SKResult alloc] initWithIdentifier:patternName range:NSUnionRange(begin.range, endResults.range) attribute:nil]];
    }
    [result addResult:[[SKScope alloc] initWithIdentifier:(patternName ? patternName : @"")
                                                    range:NSMakeRange(begin.range.location + begin.range.length,
                                                            NSUnionRange(begin.range, endResults.range).length - begin.range.length)
                                                attribute:pattern]];
    [result addResultSet:begin];
    [result addResultSet:endResults];
    return result;
}

/// Matches a given regular expression in the String and returns range
/// information for the captures
///
/// - parameter expression:     The regular expression to match
/// - parameter range:          The range to which to restrict the match
/// - parameter captures:       A collection of captures that can be used to
///                             add extra information to parts of the match.
/// - parameter baseSelector:   String to associate with the entire range of
///                             the match
///
/// - returns:  The set containing the results. May be nil if the expression
///             could not match any part of the string. It may also be empty
///             and only contain range information to show what it matched.
- (SKResultSet *)matchExpression:(NSRegularExpression *)expression
                         inRange:(NSRange)range
                        captures:(SKCaptureCollection *)captures
                    baseSelector:(NSString *)baseSelector
{
    NSTextCheckingResult *result = [expression firstMatchInString:self.toParse.string options:NSMatchingWithTransparentBounds range:range];
    if (!result) return nil;
    SKResultSet *resultSet = [[SKResultSet alloc] initWithStartingRange:result.range];
    NSString *base = baseSelector;
    if (base) {
        [resultSet addResult:[[SKResult alloc] initWithIdentifier:base range:result.range attribute:nil]];
    }
    if (captures) {
        for (NSNumber *index in captures.captureIndexes) {
            if (result.numberOfRanges <= [index unsignedIntegerValue]) {
                NSLog(@"Attention unexpected capture (%@ to %lu): %@", index, (unsigned long) result.numberOfRanges, expression.pattern);
                continue;
            }
            NSRange range1 = [result rangeAtIndex:[index unsignedIntegerValue]];
            if (range1.location == NSNotFound) {
                continue;
            }
            NSString *scope = captures[index].name;
            if (scope) {
                [resultSet addResult:[[SKResult alloc] initWithIdentifier:scope range:range1 attribute:nil]];
            }
        }
    }
    return resultSet;
}

/// Uses the callback to communicate the results of the parsing pass back to
/// the caller of parse. The scopes are stored in toParse.
///
/// - parameter results:    The results of the parsing pass
/// - parameter callback:   The method to call on every successful match
- (void)applyResults:(SKResultSet *)results callback:(SKParserCallback)callback {
    callback(SKLanguageGlobalScope, results.range);
    for (SKResult *result in results.results) {
        if (result.range.length <= 0) continue;
        if (result.attribute) {
            [self.toParse appendScopeAtTop:result];
        } else if (![result.patternIdentifier isEqualToString:@""]) {
            callback(result.patternIdentifier, result.range);
        }
    }
}

@end
