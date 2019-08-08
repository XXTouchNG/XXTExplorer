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
@property (nonatomic, strong) NSArray <NSDictionary *> *languageMetas;

@end

@implementation XXTEEditorLanguage

- (instancetype)initWithExtension:(NSString *)extension {
    self = [super init];
    if (self)
    {
        NSString *languageMetasPath = [[NSBundle mainBundle] pathForResource:@"SKLanguage" ofType:@"plist"];
        assert(languageMetasPath);
        NSArray <NSDictionary *> *languageMetas = [[NSArray alloc] initWithContentsOfFile:languageMetasPath];
        assert([languageMetas isKindOfClass:[NSArray class]]);
        _languageMetas = languageMetas;
        
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
        if (!languageMeta) {
            return nil;
        }
        assert([languageMeta isKindOfClass:[NSDictionary class]]);
        
        NSString *languageIdentifier = languageMeta[@"identifier"];
        assert([languageIdentifier isKindOfClass:[NSString class]]);
        
        @weakify(self);
        SKBundleManager *bundleManager = [[SKBundleManager alloc] initWithCallback:^NSURL *(NSString *identifier, SKTextMateFileType fileType) {
            @strongify(self);
            if (fileType == SKTextMateFileTypeLanguage) {
                NSString *filePath = [self pathForLanguageIdentifier:identifier];
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
        
        if ([languageMeta[@"comments"] isKindOfClass:[NSDictionary class]])
            _comments = languageMeta[@"comments"];
        if ([languageMeta[@"indent"] isKindOfClass:[NSDictionary class]])
            _indent = languageMeta[@"indent"];
        if ([languageMeta[@"folding"] isKindOfClass:[NSDictionary class]])
            _folding = languageMeta[@"folding"];
        if ([languageMeta[@"identifier"] isKindOfClass:[NSString class]])
            _identifier = languageMeta[@"identifier"];
        if ([languageMeta[@"displayName"] isKindOfClass:[NSString class]])
            _displayName = languageMeta[@"displayName"];
        if ([languageMeta[@"name"] isKindOfClass:[NSString class]])
            _name = languageMeta[@"name"];
        if ([languageMeta[@"extensions"] isKindOfClass:[NSArray class]])
            _extensions = languageMeta[@"extensions"];
        if ([languageMeta[@"hasSymbol"] isKindOfClass:[NSNumber class]])
            _hasSymbol = [languageMeta[@"hasSymbol"] boolValue];
    }
    return self;
}

- (NSString *)pathForLanguageIdentifier:(NSString *)identifier {
    NSArray <NSDictionary *> *languageMetas = self.languageMetas;
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
    if (!languageMeta) {
        return nil;
    }
    assert([languageMeta isKindOfClass:[NSDictionary class]]);
    NSString *languageName = languageMeta[@"name"];
    assert([languageName isKindOfClass:[NSString class]]);
    NSString *languagePath = [[NSBundle mainBundle] pathForResource:languageName ofType:@"tmLanguage"];
    // TODO: Onigmo Support
    // assert([languagePath isKindOfClass:[NSString class]]);
    return languagePath;
}

@end
