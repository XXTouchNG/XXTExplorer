//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKBundleManager.h"
#import "SKLanguage.h"
#import "SKTheme.h"

static SKBundleManager *defaultManager = nil;

@interface SKBundleManager ()

// MARK: - Properties

@property (nonatomic, copy) SKBundleLocationCallback bundleCallback;
@property (nonatomic, strong) NSMutableArray <SKLanguage *> *dependencies;
@property (nonatomic, strong) NSMutableDictionary <NSString *, SKLanguage *> *cachedLanguages;
@property (nonatomic, strong) NSMutableDictionary <NSString *, SKTheme *> *cachedThemes;

@end

@implementation SKBundleManager {

}

+ (SKBundleManager *)defaultManager {
    return defaultManager;
}

// MARK: - Initializers

/// Used to initialize the default manager. Unless this is called the
/// defaultManager property will be set to nil.
///
/// - parameter callback:   The callback used to find the location of the
///                         textmate files.
+ (void)initializeDefaultManagerWithCallback:(SKBundleLocationCallback)callback {
    if (!defaultManager) {
        defaultManager = [[SKBundleManager alloc] initWithCallback:callback];
    } else {
        defaultManager.bundleCallback = callback;
    }
}

- (instancetype)initWithCallback:(SKBundleLocationCallback)callback {
    self = [super init];
    if (self) {
        _bundleCallback = callback;
        _dependencies = [[NSMutableArray alloc] init];
        _cachedLanguages = [[NSMutableDictionary alloc] init];
        _cachedThemes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

// MARK: - Public

- (SKLanguage *)languageWithIdentifier:(NSString *)identifier {
    SKLanguage *language = self.cachedLanguages[identifier];
    if (language) return language;
    [self.dependencies removeAllObjects];
    SKLanguage *rawLanguage = [self loadRawLanguageWithIdentifier:identifier];
    [rawLanguage validateWithHelperLanguages:self.dependencies];
    if (self.languageCaching && rawLanguage) {
        self.cachedLanguages[identifier] = rawLanguage;
    }
    [self.dependencies removeAllObjects];
    return rawLanguage;
}

- (SKTheme *)themeWithIdentifier:(NSString *)identifier baseFonts:(NSArray <UIFont *> *)baseFonts {
    SKTheme *theme = self.cachedThemes[identifier];
    if (theme) return theme;
    NSURL *dictURL = self.bundleCallback(identifier, SKTextMateFileTypeTheme);
    if ([dictURL isKindOfClass:[NSURL class]]) {
        NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfURL:dictURL];
        if ([plist isKindOfClass:[NSDictionary class]]) {
            SKTheme *newTheme = [[SKTheme alloc] initWithDictionary:plist baseFonts:baseFonts];
            if (newTheme) {
                self.cachedThemes[identifier] = newTheme;
                return newTheme;
            } else return nil;
        } else return nil;
    } else return nil;
    return nil;
}

/// Clears the language cache. Use if low on memory.
- (void)clearLanguageCache {
    [self.cachedLanguages removeAllObjects];
}

// MARK: - Internal Interface

/// - parameter identifier: The identifier of the requested language.
/// - returns:  The Language with unresolved extenal references, if found
- (SKLanguage *)loadRawLanguageWithIdentifier:(NSString *)identifier {
    SKLanguage *storedLanguage = nil;
    for (SKLanguage *lang in self.dependencies) {
        if ([lang.scopeName isEqualToString:identifier]) {
            storedLanguage = lang;
        }
    }
    if (storedLanguage) {
        return storedLanguage;
    } else {
        NSURL *dictURL = self.bundleCallback(identifier, SKTextMateFileTypeLanguage);
        if ([dictURL isKindOfClass:[NSURL class]]) {
            NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfURL:dictURL];
            if ([plist isKindOfClass:[NSDictionary class]]) {
                SKLanguage *newLanguage = [[SKLanguage alloc] initWithDictionary:plist manager:self];
                if (newLanguage) {
                    [self.dependencies addObject:newLanguage];
                    return newLanguage;
                } else return nil;
            } else return nil;
        } else return nil;
    }
    return nil;
}


@end
