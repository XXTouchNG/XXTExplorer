//
//  XXTEEditorLanguage.m
//  XXTExplorer
//
//  Created by Zheng on 07/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorLanguage.h"

#import "SKLanguage.h"
#import "SKBundleManager.h"

NSString * const kTextMateCommentStart = @"TM_COMMENT_START";
NSString * const kTextMateCommentMultilineStart = @"TM_COMMENT_START_2";
NSString * const kTextMateCommentMultilineEnd = @"TM_COMMENT_END_2";

@interface XXTEEditorLanguage ()

@end

@implementation XXTEEditorLanguage

+ (NSArray <NSDictionary *> *)languageMetas {
    static NSArray <NSDictionary *> *metas = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *languageMetasPath = [[NSBundle mainBundle] pathForResource:@"SKLanguage" ofType:@"plist"];
        assert(languageMetasPath);
        NSArray <NSDictionary *> *languageMetas = [[NSArray alloc] initWithContentsOfFile:languageMetasPath];
        assert([languageMetas isKindOfClass:[NSArray class]]);
        metas = languageMetas;
    });
    return metas;
}

+ (NSDictionary *)languageMetaForExtension:(NSString *)extension {
    NSArray <NSDictionary *> *languageMetas = [[self class] languageMetas];
    NSString *baseExtension = [extension lowercaseString];
    NSDictionary *languageMeta = nil;
    for (NSDictionary *tLanguageMeta in languageMetas) {
        if ([tLanguageMeta isKindOfClass:[NSDictionary class]]) {
            NSArray <NSString *> *checkExtensions = tLanguageMeta[@"extensions"];
            if ([checkExtensions isKindOfClass:[NSArray class]]) {
                if ([checkExtensions containsObject:baseExtension]) {
                    languageMeta = tLanguageMeta;
                    break;
                }
            }
        }
    }
    return languageMeta;
}

+ (NSDictionary *)languageMetaForIdentifier:(NSString *)identifier {
    NSArray <NSDictionary *> *languageMetas = [[self class] languageMetas];
    assert([languageMetas isKindOfClass:[NSArray class]]);
    NSDictionary *languageMeta = nil;
    for (NSDictionary *tLanguageMeta in languageMetas) {
        if ([tLanguageMeta isKindOfClass:[NSDictionary class]]) {
            NSString *checkIdentifier = tLanguageMeta[@"identifier"];
            if ([checkIdentifier isEqualToString:identifier]) {
                languageMeta = tLanguageMeta;
                break;
            }
        }
    }
    return languageMeta;
}

+ (NSString *)pathForLanguageIdentifier:(NSString *)identifier {
    NSDictionary *languageMeta = [[self class] languageMetaForIdentifier:identifier];
    assert([languageMeta isKindOfClass:[NSDictionary class]]);
    NSString *languageName = languageMeta[@"name"];
    assert([languageName isKindOfClass:[NSString class]]);
    NSString *languagePath = [[NSBundle mainBundle] pathForResource:languageName ofType:@"tmLanguage"];
    return languagePath;
}

- (instancetype)initWithExtension:(NSString *)extension {
    self = [super init];
    if (self)
    {
        NSDictionary *languageMeta = [[self class] languageMetaForExtension:extension];
        assert([languageMeta isKindOfClass:[NSDictionary class]]);
        
        NSString *languageIdentifier = languageMeta[@"identifier"];
        assert([languageIdentifier isKindOfClass:[NSString class]]);
        
        @weakify(self);
        SKBundleManager *bundleManager = [[SKBundleManager alloc] initWithCallback:^NSURL *(NSString *identifier, SKTextMateFileType fileType) {
            @strongify(self);
            if (fileType == SKTextMateFileTypeLanguage) {
                NSString *filePath = [[self class] pathForLanguageIdentifier:identifier];
                if (!filePath)
                    return nil;
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                return fileURL;
            }
            return nil;
        }];
        
        SKLanguage *rawLanguage = [bundleManager languageWithIdentifier:languageIdentifier];
        if (!rawLanguage) return nil;
        _skLanguage = rawLanguage;
        
        if ([languageMeta[kXXTEEditorLanguageKeyComments] isKindOfClass:[NSDictionary class]])
            _comments = languageMeta[kXXTEEditorLanguageKeyComments];
        if ([languageMeta[kXXTEEditorLanguageKeyIndent] isKindOfClass:[NSDictionary class]])
            _indent = languageMeta[kXXTEEditorLanguageKeyIndent];
        if ([languageMeta[kXXTEEditorLanguageKeyFolding] isKindOfClass:[NSDictionary class]])
            _folding = languageMeta[kXXTEEditorLanguageKeyFolding];
        if (!XXTE_IS_IPAD) {
            if ([languageMeta[kXXTEEditorLanguageKeyKeymap] isKindOfClass:[NSString class]])
                _keymap = languageMeta[kXXTEEditorLanguageKeyKeymap];
        } else {
            if ([languageMeta[kXXTEEditorLanguageKeyKeymapiPad] isKindOfClass:[NSString class]])
                _keymap = languageMeta[kXXTEEditorLanguageKeyKeymapiPad];
        }
        
        if ([languageMeta[kXXTEEditorLanguageKeyIdentifier] isKindOfClass:[NSString class]])
            _identifier = languageMeta[kXXTEEditorLanguageKeyIdentifier];
        if ([languageMeta[kXXTEEditorLanguageKeyDisplayName] isKindOfClass:[NSString class]])
            _displayName = languageMeta[kXXTEEditorLanguageKeyDisplayName];
        if ([languageMeta[kXXTEEditorLanguageKeyName] isKindOfClass:[NSString class]])
            _name = languageMeta[kXXTEEditorLanguageKeyName];
        if ([languageMeta[kXXTEEditorLanguageKeyExtensions] isKindOfClass:[NSArray class]])
            _extensions = languageMeta[kXXTEEditorLanguageKeyExtensions];
        if ([languageMeta[kXXTEEditorLanguageKeyHasSymbol] isKindOfClass:[NSNumber class]])
            _hasSymbol = [languageMeta[kXXTEEditorLanguageKeyHasSymbol] boolValue];
    }
    return self;
}

@end
