//
//  SKParser.h
//  SyntaxKit
//
//  This class is in charge of the painful task of recognizing the syntax
//  patterns. It tries to match parsing behavior of TextMate as closely as
//  possible.
//
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKLanguage;
@class SKScopedString;

// MARK: - Types

typedef void (^SKParserCallback)(NSString *scopeName, NSRange range);

@interface SKParser : NSObject

// MARK: - Properties

/// The Language that the parser recognizes
@property (nonatomic, strong, readonly) SKLanguage *language;

/// String that is used in parse(in:). May already contain lexical
/// information from previous calls to parse for incremental parsing.
/// Stores the recognized lexical scopes after a successful call to parse.
@property (nonatomic, strong) SKScopedString *toParse;
/// Set to true to abort the parsing pass
@property (nonatomic, assign) BOOL aborted;

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language;

// MARK: - Public

- (void)parseString:(NSString *)string matchCallback:(SKParserCallback)callback;
- (void)parseString:(NSString *)string inRange:(NSRange)range matchCallback:(SKParserCallback)callback;
- (void)parseInRange:(NSRange)range matchCallback:(SKParserCallback)callback;

// MARK: - Helper

+ (NSString *)escapedExpressionStringForString:(NSString *)string;
+ (BOOL)expressionStringHasBackReferences:(NSString *)expressionString;
+ (NSString *)expandExpressionStringBackReferences:(NSString *)expressionString
                                         withMatch:(NSTextCheckingResult *)rawResult
                                        withString:(NSString *)toParse;


@end
