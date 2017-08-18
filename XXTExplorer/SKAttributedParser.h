//
//  SKAttributedParser.h
//  SyntaxKit
//
//  A subclass of Parser that knows about themes. Using the theme it maps
//  between recognized TextMate scope descriptions and NSAttributedString
//  attributes.
//
// Created by Zheng on 19/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKParser.h"
#import "SKTheme.h"

// MARK: - Types

typedef void (^SKAttributedParserCallback)(NSString *scopeName, NSRange range, SKAttributes attributes);

@interface SKAttributedParser : SKParser

// MARK: - Properties

@property (nonatomic, strong, readonly) SKTheme *theme;

// MARK: - Initializers

- (instancetype)initWithLanguage:(SKLanguage *)language theme:(SKTheme *)theme;

// MARK: - Parsing

- (void)attributedParseString:(NSString *)string matchCallback:(SKAttributedParserCallback)callback;
- (void)attributedParseStringInRange:(NSRange)range matchCallback:(SKAttributedParserCallback)callback;
- (NSAttributedString *)attributedStringForString:(NSString *)string baseAttributes:(NSDictionary *)baseAttributes;

@end