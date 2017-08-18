//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKLanguage.h"
#import "SKBundleManager.h"
#import "SKReferenceManager.h"
#import "SKPattern.h"
#import "SKRepository.h"

@interface SKLanguage ()

@end

@implementation SKLanguage {

}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, id> *)dictionary manager:(SKBundleManager *)manager {
    self = [super init];
    if (self)
    {
        NSString *uuidString = dictionary[@"uuid"];
        if ([uuidString isKindOfClass:[NSString class]])
        {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
            NSString *name = dictionary[@"name"];
            NSString *scopeName = dictionary[@"scopeName"];
            NSArray <NSDictionary <NSString *, id> *> *array = dictionary[@"patterns"];
            if (!uuid || ![name isKindOfClass:[NSString class]] || ![scopeName isKindOfClass:[NSString class]] || ![array isKindOfClass:[NSArray class]])
            {
                return nil;
            }
            NSDictionary <NSString *, NSDictionary *> *repository = dictionary[@"repository"];
            if (![repository isKindOfClass:[NSDictionary class]]) {
                repository = @{};
            }
            _uuid = uuid;
            _name = name;
            _scopeName = scopeName;
            SKReferenceManager *referenceManager1 = [[SKReferenceManager alloc] initWithBundleManager:manager];
            _referenceManager = referenceManager1;
            SKPattern *pattern1 = [[SKPattern alloc] init];
            NSArray *subpatterns1 = [referenceManager1 patternsForPatterns:array inRepository:nil caller:nil];
            pattern1.subpatterns = [[NSMutableArray alloc] initWithArray:subpatterns1];
            SKRepository *repository1 = [[SKRepository alloc] initWithRepo:repository inParent:nil withManager:referenceManager1];
            _repository = repository1;
            [referenceManager1 resolveInternalReferencesWithRepository:repository1 inLanguage:self];
        }
    }
    return self;
}

- (void)validateWithHelperLanguages:(NSArray <SKLanguage *> *)helperLanguages {
    [SKReferenceManager resolveExternalReferencesBetweenLanguages:helperLanguages basename:self.scopeName];
}

@end