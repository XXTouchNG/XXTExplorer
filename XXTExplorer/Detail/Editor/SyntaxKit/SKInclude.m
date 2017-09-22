//
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKInclude.h"
#import "SKBundleManager.h"
#import "SKRepository.h"
#import "SKLanguage.h"

typedef enum : NSUInteger {
    SKIncludeReferenceTypeToRepository = 0,
    SKIncludeReferenceTypeToSelf,
    SKIncludeReferenceTypeToBase,
    SKIncludeReferenceTypeToForeign,
    SKIncludeReferenceTypeToForeignRepository,
    SKIncludeReferenceTypeResolved
} SKIncludeReferenceType;

@interface SKInclude ()

// MARK: - Properties

@property (nonatomic, assign, readonly) SKIncludeReferenceType type;
@property (nonatomic, strong, readonly) NSString *repositoryRef;
@property (nonatomic, strong, readonly) NSString *languageRef;
@property (nonatomic, strong, readonly) SKRepository *associatedRepository;

@end

@implementation SKInclude {

}

// MARK: - Initializers

- (instancetype)initWithReference:(NSString *)reference inRepository:(SKRepository *)repository parent:(SKPattern *)parent manager:(SKBundleManager *)manager {
    self = [super init];
    if (self)
    {
        _associatedRepository = repository;
        if ([reference hasPrefix:@"#"])
        {
            _type = SKIncludeReferenceTypeToRepository;
            _repositoryRef = [reference substringFromIndex:1];
        }
        else if ([reference isEqualToString:@"$self"])
        {
            _type = SKIncludeReferenceTypeToSelf;
        }
        else if ([reference isEqualToString:@"$base"])
        {
            _type = SKIncludeReferenceTypeToBase;
        }
        else if ([reference rangeOfString:@"#"].location != NSNotFound)
        {
            NSRange hashRange = [reference rangeOfString:@"#"];
            if (hashRange.location != NSNotFound) {
                NSString *languagePart = [reference substringToIndex:hashRange.location];
                _type = SKIncludeReferenceTypeToForeignRepository;
                _repositoryRef = [reference substringFromIndex:hashRange.location + hashRange.length];
                _languageRef = languagePart;
                [manager loadRawLanguageWithIdentifier:reference];
            } else {
                _type = SKIncludeReferenceTypeToSelf;
            }
        }
        else
        {
            _type = SKIncludeReferenceTypeToForeign;
            _languageRef = reference;
            [manager loadRawLanguageWithIdentifier:reference];
        }
        self.parent = parent;
    }
    return self;
}

- (instancetype)initWithInclude:(SKInclude *)include parent:(SKPattern *)parent {
    self = [super initWithPattern:include parent:parent];
    if (self)
    {
        _type = [include type];
        _associatedRepository = [include associatedRepository];
    }
    return self;
}

// MARK: - Reference Resolution

- (void)resolveInternalReferencesWithRepository:(SKRepository *)repository inLanguage:(SKLanguage *)language {
    SKPattern *pattern = nil;
    if (_type == SKIncludeReferenceTypeToRepository) {
        if (self.associatedRepository)
        {
            pattern = self.associatedRepository[self.repositoryRef];
        }
        else if (repository)
        {
            pattern = repository[self.repositoryRef];
        }
    } else if (_type == SKIncludeReferenceTypeToSelf) {
        pattern = language.pattern;
    } else {
        return;
    }
    if (pattern) {
        [self replaceWithPattern:pattern];
    }
    _type = SKIncludeReferenceTypeResolved;
}

- (void)resolveExternalReferencesFromLanguage:(SKLanguage *)language inLanguages:(NSDictionary <NSString *, SKLanguage *> *)languages baseName:(NSString *)baseName {
    SKPattern *pattern = nil;
    if (_type == SKIncludeReferenceTypeToBase) {
        NSString *base = baseName;
        if (base && languages[base]) {
            pattern = languages[base].pattern;
        } else {
            pattern = nil;
        }
    } else if (_type == SKIncludeReferenceTypeToForeignRepository) {
        SKLanguage *lang = languages[self.languageRef];
        if (lang) {
            pattern = lang.repository[self.repositoryRef];
        }
    } else if (_type == SKIncludeReferenceTypeToForeign) {
        SKLanguage *lang = languages[self.languageRef];
        if (lang) {
            pattern = lang.pattern;
        }
    } else {
        return;
    }
    if (pattern) {
        [self replaceWithPattern:pattern];
    }
    _type = SKIncludeReferenceTypeResolved;
}

// MARK: - Private

- (void)replaceWithPattern:(SKPattern *)pattern {
    self.name = [pattern name];
    self.match = [pattern match];
    self.captures = [pattern captures];
    self.patternBegin = [pattern patternBegin];
    self.beginCaptures = [pattern beginCaptures];
    self.patternEnd = [pattern patternEnd];
    self.endCaptures = [pattern endCaptures];
    self.subpatterns = [pattern subpatterns];
}

@end
