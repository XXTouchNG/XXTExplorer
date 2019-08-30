//
//  XXTEEditorLanguage.h
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kTextMateCommentStart;
extern NSString * const kTextMateCommentMultilineStart;
extern NSString * const kTextMateCommentMultilineEnd;

static NSString * const kXXTEEditorLanguageKeyComments = @"comments";
static NSString * const kXXTEEditorLanguageKeyIndent = @"indent";
static NSString * const kXXTEEditorLanguageKeyFolding = @"folding";
static NSString * const kXXTEEditorLanguageKeyKeymap = @"keymap";
static NSString * const kXXTEEditorLanguageKeyKeymapiPad = @"keymap~ipad";
static NSString * const kXXTEEditorLanguageKeyIdentifier = @"identifier";
static NSString * const kXXTEEditorLanguageKeyDisplayName = @"displayName";
static NSString * const kXXTEEditorLanguageKeyName = @"name";
static NSString * const kXXTEEditorLanguageKeyExtensions = @"extensions";
static NSString * const kXXTEEditorLanguageKeyHasSymbol = @"hasSymbol";

@class SKLanguage;

@interface XXTEEditorLanguage : NSObject

@property (nonatomic, strong, readonly) SKLanguage *skLanguage;

@property (nonatomic, strong, readonly) NSDictionary *comments;
@property (nonatomic, strong, readonly) NSDictionary *indent;
@property (nonatomic, strong, readonly) NSDictionary *folding;
@property (nonatomic, strong, readonly) NSString *keymap;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *displayName;
@property (nonatomic, strong, readonly) NSArray <NSString *> *extensions;
@property (nonatomic, strong, readonly) NSString *name;

@property (nonatomic, assign, readonly) BOOL hasSymbol;

- (instancetype)initWithExtension:(NSString *)extension;

+ (NSArray <NSDictionary *> *)languageMetas;
+ (NSDictionary *)languageMetaForExtension:(NSString *)extension;
+ (NSDictionary *)languageMetaForIdentifier:(NSString *)identifier;
+ (NSString *)pathForLanguageIdentifier:(NSString *)identifier;

@end
