//
//  SKInclude.h
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
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKPattern.h"

@class SKBundleManager;

@interface SKInclude : SKPattern

// MARK: - Initializers

- (instancetype)initWithReference:(NSString *)reference
                     inRepository:(SKRepository *)repository
                           parent:(SKPattern *)parent
                          manager:(SKBundleManager *)manager;

- (instancetype)initWithInclude:(SKInclude *)include parent:(SKPattern *)parent;

// MARK: - Reference Resolution

- (void)resolveInternalReferencesWithRepository:(SKRepository *)repository inLanguage:(SKLanguage *)language;
- (void)resolveExternalReferencesFromLanguage:(SKLanguage *)language inLanguages:(NSDictionary <NSString *, SKLanguage *> *)languages baseName:(NSString *)baseName;

@end