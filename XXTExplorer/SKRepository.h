//
//  SKRepository.h
//  SyntaxKit
//
//  Represents a repository dictionary from a TextMate grammar. This class
//  supports nested repositories as found in some grammars.
//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKReferenceManager;
@class SKPattern;

@interface SKRepository : NSObject

// MARK: - Initializers

- (instancetype)initWithRepo:(NSDictionary <NSString *, NSDictionary *> *)repo
                    inParent:(SKRepository *)parent
                 withManager:(SKReferenceManager *)manager;

// MARK: - Accessing Patterns

- (SKPattern *)objectForKeyedSubscript:(NSString *)index;

@end