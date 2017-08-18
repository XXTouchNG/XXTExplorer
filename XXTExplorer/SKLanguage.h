//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKBundleManager;
@class SKLanguage;
@class SKPattern;
@class SKReferenceManager;
@class SKRepository;

static NSString * const SKLanguageGlobalScope = @"GLOBAL";

@interface SKLanguage : NSObject

// MARK: - Properties

@property (nonatomic, strong, readonly) NSUUID *uuid;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *scopeName;
@property (nonatomic, strong, readonly) SKPattern *pattern;
@property (nonatomic, strong, readonly) SKReferenceManager *referenceManager;
@property (nonatomic, strong, readonly) SKRepository *repository;

// MARK: - Initializers

- (instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dictionary manager:(SKBundleManager *)manager;

/// Resolves all external reference the language has to the given languages.
/// Only after a call to this method the Language is fit for general use.
///
/// - parameter helperLanguages: The languages that the language has
///     references to resolve against. This should at least contain the
///     language itself.
- (void)validateWithHelperLanguages:(NSArray <SKLanguage *> *)helperLanguages;

@end