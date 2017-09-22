//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKRepository.h"
#import "SKReferenceManager.h"
#import "SKPattern.h"

@interface SKRepository ()

// MARK: - Properties

@property (nonatomic, strong, readonly) NSMutableDictionary <NSString *, SKPattern *> *entries;
@property (nonatomic, weak, readonly) SKRepository *parentRepository;

@end

@implementation SKRepository {

}

// MARK: - Initializers

- (instancetype)initWithRepo:(NSDictionary <NSString *, NSDictionary *> *)repo
                    inParent:(SKRepository *)parent
                 withManager:(SKReferenceManager *)manager
{
    self = [super init];
    if (self)
    {
        _entries = [[NSMutableDictionary alloc] init];
        _parentRepository = parent;
        for (NSString *key in repo)
        {
            NSDictionary *value = repo[key];
            if (![value isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            SKRepository *subRepo = nil;
            NSDictionary <NSString *, NSDictionary *> *containedRepo = value[@"repository"];
            if ([containedRepo isKindOfClass:[NSDictionary class]]) {
                subRepo = [[SKRepository alloc] initWithRepo:containedRepo inParent:self withManager:manager];
            }
            SKPattern *pattern = [[SKPattern alloc] initWithDictionary:value parent:nil repository:subRepo manager:manager];
            if (pattern) {
                self.entries[key] = pattern;
            }
        }
    }
    return self;
}

// MARK: - Accessing Patterns

- (SKPattern *)objectForKeyedSubscript:(NSString *)index {
    SKPattern *resultAtLevel = self.entries[index];
    if (resultAtLevel) {
        return resultAtLevel;
    }
    if (self.parentRepository) {
        return self.parentRepository[index];
    }
    return nil;
}

@end