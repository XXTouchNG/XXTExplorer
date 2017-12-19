//
//  SKBundleManager.h
//  SyntaxKit
//
//  Used to get access to SyntaxKit representations of TextMate bundle files.
//  This class is used as a gateway for both internal and external use.
//  Alternatively a global instace can be used for convenience. It is
//  initialized with a callback that tells the bundle manager where to find the
//  files.
//
// Created by Zheng on 17/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SKLanguage;
@class SKTheme;


typedef enum : NSUInteger {
    SKTextMateFileTypeLanguage = 0,
    SKTextMateFileTypeTheme
} SKTextMateFileType;

@interface SKBundleManager : NSObject

// MARK: - Types

/// Given an identifier of a grammar file and the format returns a url to
/// the resource.
///
/// - parameter identifier: The identifier of the file. Used to map it to
///                         the name of the file.
/// - parameter kind:       The kind of file requested
/// - returns:  A URL pointing to the resource, if found
typedef NSURL * (^SKBundleLocationCallback)(NSString *, SKTextMateFileType);

// MARK: - Properties

/// You probably want to leave the languageCaching property set to true.
///
/// - note: Setting it to false will not invalidate or purge the cache. This
///         has to be done separately using clearLanguageCache.
@property (nonatomic, assign) BOOL languageCaching;

// MARK: - Initializers

/// Used to initialize the default manager. Unless this is called the
/// defaultManager property will be set to nil.
///
/// - parameter callback:   The callback used to find the location of the
///                         textmate files.
+ (SKBundleManager *)defaultManager;
+ (void)initializeDefaultManagerWithCallback:(SKBundleLocationCallback)callback;

- (instancetype)initWithCallback:(SKBundleLocationCallback)callback;

// MARK: - Public
- (SKLanguage *)languageWithIdentifier:(NSString *)identifier;
- (SKTheme *)themeWithIdentifier:(NSString *)identifier baseFonts:(NSArray <UIFont *> *)baseFonts;

/// Clears the language cache. Use if low on memory.
- (void)clearLanguageCache;

// MARK: - Internal Interface

/// - parameter identifier: The identifier of the requested language.
/// - returns:  The Language with unresolved extenal references, if found
- (SKLanguage *)loadRawLanguageWithIdentifier:(NSString *)identifier;

@end
