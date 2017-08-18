//
//  SKAttributedParsingOperation.m
//  XXTExplorer
//
//  Created by Zheng on 19/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKAttributedParsingOperation.h"
#import "SKLanguage.h"
#import "SKScopedString.h"
#import "SKAttributedParser.h"
#import "SKResult.h"

/// Represents one change (insertion or deletion) between two strings
@interface SKDiff : NSObject

// MARK: - Properties

/// - Insertion: The inserted sting
/// - Deletion:  The empty string
@property (nonatomic, strong) NSString *change;
/// The range of the change in the old string
///
/// - Insertion: The location of the insertion and length 0
/// - Deletion:  The range of deleted characters
@property (nonatomic, assign) NSRange range;

- (instancetype)initWithChange:(NSString *)change range:(NSRange)range;

// MARK: - Methods

/// - returns:  true if the diff represents the changes between oldString to
///             newString
- (BOOL)representsChangesFrom:(NSString *)oldString to:(NSString *)newString;

/// - returns: the range of the change in the new string
- (NSRange)rangeInNewString;

/// - returns: true if the change is an insertion
- (BOOL)isInsertion;

@end

@implementation SKDiff

- (instancetype)initWithChange:(NSString *)change range:(NSRange)range {
    self = [super init];
    if (self)
    {
        _change = change;
        _range = range;
    }
    return self;
}

- (BOOL)representsChangesFrom:(NSString *)oldString to:(NSString *)newString {
    return [newString isEqualToString:[oldString stringByReplacingCharactersInRange:self.range withString:self.change]] && [self.change isEqualToString:[newString substringWithRange:self.rangeInNewString]];
}

- (NSRange)rangeInNewString {
    return NSMakeRange(self.range.location, self.isInsertion ? self.change.length : 0);
}

- (BOOL)isInsertion {
    return self.range.length == 0;
}

@end

@interface SKAttributedParsingOperation ()

// MARK: - Properties

@property (nonatomic, strong, readonly) SKAttributedParser *parser;
@property (nonatomic, copy, readonly) SKAttributedParsingOperationCallback operationCallback;
@property (nonatomic, assign) NSRange parsedRange;

@end

@implementation SKAttributedParsingOperation

// MARK: - Initializers

- (instancetype)initWithString:(NSString *)string language:(SKLanguage *)language theme:(SKTheme *)theme callback:(SKAttributedParsingOperationCallback)callback {
    self = [super init];
    if (self)
    {
        _parser = [[SKAttributedParser alloc] initWithLanguage:language theme:theme];
        _parser.toParse = [[SKScopedString alloc] initWithString:string];
        _operationCallback = callback;
    }
    return self;
}

- (instancetype)initWithString:(NSString *)string previousOperation:(SKAttributedParsingOperation *)previousOperation changeIsInsertion:(BOOL)insertion changedRange:(NSRange)range newCallback:(SKAttributedParsingOperationCallback)callback {
    self = [super init];
    if (self)
    {
        _parser = previousOperation.parser;
        _operationCallback = callback ? callback : previousOperation.operationCallback;
        SKDiff *diff = nil;
        if (insertion) {
            diff = [[SKDiff alloc] initWithChange:[string substringWithRange:range] range:NSMakeRange(range.location, 0)];
        } else {
            diff = [[SKDiff alloc] initWithChange:@"" range:range];
        }
        if ([diff representsChangesFrom:_parser.toParse.string to:string]) {
            self.parsedRange = [SKAttributedParsingOperation outdatedRangeIn:string forChange:diff updatingPreviousResult:&self.parser.toParse];
        } else {
            self.parser.toParse = [[SKScopedString alloc] initWithString:string];
        }
    }
    return self;
}

// MARK: - NSOperation Implementation

- (void)main {
    NSMutableArray <NSValue *> *rangeArray = [[NSMutableArray alloc] init];
    NSMutableArray <SKAttributes> *attributesArray = [[NSMutableArray alloc] init];
    SKAttributedParserCallback callback = ^(NSString *scopeName, NSRange range, SKAttributes attributes) {
        if (attributes) {
            [rangeArray addObject:[NSValue valueWithRange:range]];
            [attributesArray addObject:attributes];
        }
    };
    [self.parser attributedParseStringInRange:self.parsedRange matchCallback:callback];
    if (!self.parser.aborted) {
        self.operationCallback(rangeArray, attributesArray, self);
    }
}

- (void)cancel {
    self.parser.aborted = YES;
    [super cancel];
}

+ (NSRange)outdatedRangeIn:(NSString *)newString forChange:(SKDiff *)diff updatingPreviousResult:(SKScopedString **)previous {
    NSRange linesRange;
    NSRange range;
    if ([diff isInsertion]) {
        range = [diff rangeInNewString];
        [(*previous) insertString:diff.change atIndex:range.location];
        linesRange = [newString lineRangeForRange:range];
    } else {
        range = diff.range;
        [(*previous) deleteCharactersInRange:range];
        linesRange = [newString lineRangeForRange:NSMakeRange(range.location, 0)];
    }
    SKScope *scopeAtIndex = [(*previous) topMostScopeAtIndex:NSMaxRange(linesRange) - 1];
    if ([scopeAtIndex isEqual:(*previous).baseScope]) {
        return linesRange;
    } else {
        NSUInteger endOfCurrentScope = NSMaxRange(scopeAtIndex.range);
        return NSUnionRange(linesRange, NSMakeRange(range.location, endOfCurrentScope - range.location));
    }
    return linesRange;
}

@end
