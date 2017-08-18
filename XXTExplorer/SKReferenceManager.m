//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKReferenceManager.h"
#import "SKBundleManager.h"
#import "SKPattern.h"
#import "SKInclude.h"
#import "SKRepository.h"
#import "SKLanguage.h"

@interface SKReferenceManager ()

@property (nonatomic, strong, readonly) NSMutableArray <SKInclude *> *includes;
@property (nonatomic, weak, readonly) SKBundleManager *bundleManager;

@end

@implementation SKReferenceManager {

}

- (instancetype)initWithBundleManager:(SKBundleManager *)bundleManager {
    self = [super init];
    if (self)
    {
        _includes = [[NSMutableArray alloc] init];
        _bundleManager = bundleManager;
    }
    return self;
}

- (NSArray <SKPattern *> *)patternsForPatterns:(NSArray <NSDictionary *> *)patterns inRepository:(SKRepository *)repository caller:(SKPattern *)caller {
    SKBundleManager *manager = self.bundleManager;
    if (!manager) return @[];
    NSMutableArray <SKPattern *> *results = [[NSMutableArray alloc] init];
    for (NSDictionary *rawPattern in patterns) {
        NSString *include = rawPattern[@"include"];
        if ([include isKindOfClass:[NSString class]])
        {
            SKInclude *reference = [[SKInclude alloc] initWithReference:include inRepository:repository parent:caller manager:manager];
            [self.includes addObject:reference];
            [results addObject:reference];
        }
        else {
            SKPattern *pattern = [[SKPattern alloc] initWithDictionary:rawPattern parent:caller repository:repository manager:self];
            if (pattern) {
                [results addObject:pattern];
            }
        }
    }
    return results;
}

- (void)resolveInternalReferencesWithRepository:(SKRepository *)repository inLanguage:(SKLanguage *)language {
    for (SKInclude *include in self.includes) {
        [include resolveInternalReferencesWithRepository:repository inLanguage:language];
    }
}

+ (void)resolveExternalReferencesBetweenLanguages:(NSArray <SKLanguage *> *)languages basename:(NSString *)basename {
    NSMutableDictionary <NSString *, SKLanguage *> *otherLanguages = [[NSMutableDictionary alloc] init];
    for (SKLanguage *language in languages) {
        otherLanguages[language.scopeName] = language;
    }
    for (SKLanguage *language in languages) {
        NSArray <SKInclude *> *includes = language.referenceManager.includes;
        if (includes) {
            for (SKInclude *include in includes) {
                [include resolveExternalReferencesFromLanguage:language inLanguages:otherLanguages baseName:basename];
            }
        }
    }
}

@end