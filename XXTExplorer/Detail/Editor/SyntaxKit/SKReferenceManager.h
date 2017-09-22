//
//  SKReferenceManager.h
//  SyntaxKit
//
//  A utility class to facilitate the creation of pattern arrays.
//  It works it the following fashion: First all the pattern arrays should be
//  created with patterns:inRepository:caller:. Then
//  resolveReferencesWithRepository:inLanguage: has to be called to resolve all
//  the references in the passed out patterns. So first lots of calls to
//  patterns and then one call to resolveReferences to validate the
//  patterns by resolving all references.
//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKBundleManager;
@class SKPattern;
@class SKRepository;
@class SKLanguage;

@interface SKReferenceManager : NSObject

// MARK: - Initializers

- (instancetype)initWithBundleManager:(SKBundleManager *)bundleManager;
- (NSMutableArray <SKPattern *> *)patternsForPatterns:(NSArray <NSDictionary *> *)patterns
                                  inRepository:(SKRepository *)repository
                                        caller:(SKPattern *)caller;

// MARK: - Reference Resolution

- (void)resolveInternalReferencesWithRepository:(SKRepository *)repository
                                     inLanguage:(SKLanguage *)language;
+ (void)resolveExternalReferencesBetweenLanguages:(NSArray <SKLanguage *> *)languages
                                         basename:(NSString *)basename;

@end
