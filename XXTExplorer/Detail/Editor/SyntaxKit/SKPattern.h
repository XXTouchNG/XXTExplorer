//
//  SKPattern.h
//  SyntaxKit
//
//  Represents a pattern from a TextMate grammar
//
//  The Include class represents a Pattern that is a reference to another part
//  in the same or another grammar. It is only usable as a pattern after it has
//  been resolved via the provided method (and has type .resolved).
//
//  A pattern may be one of three types:
//  *   A single pattern in match which should be matched
//  *   A begin and an end pattern containing an optional body of patterns
//      (subpatterns) which should be matched between the begin and the end
//  *   Only a body of patterns without the begin and end. Any pattern may be
//      matched successfully
//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKCaptureCollection;
@class SKRepository;
@class SKReferenceManager;
@class SKInclude;
@class SKLanguage;

typedef NSString NSRegularExpressionString;

@interface SKPattern : NSObject

// MARK: - Properties

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSRegularExpressionString *match;
@property (nonatomic, strong) SKCaptureCollection *captures;
@property (nonatomic, strong) NSRegularExpressionString *patternBegin;
@property (nonatomic, strong) SKCaptureCollection *beginCaptures;
@property (nonatomic, strong) NSRegularExpressionString *patternEnd;
@property (nonatomic, strong) SKCaptureCollection *endCaptures;
@property (nonatomic, assign) BOOL applyEndPatternLast;
@property (nonatomic, weak) SKPattern *parent;
@property (nonatomic, strong) NSMutableArray <SKPattern *> *subpatterns;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                            parent:(SKPattern *)parent
                        repository:(SKRepository *)repository
                           manager:(SKReferenceManager *)manager;

- (instancetype)initWithPattern:(SKPattern *)pattern parent:(SKPattern *)parent;

@end
