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

@implementation XXTEEditorLanguage

- (instancetype)initWithExtension:(NSString *)extension {
    self = [super init];
    if (self)
    {
        NSString *baseExtension = [extension lowercaseString];
        
        NSString *languageMetasPath = [[NSBundle mainBundle] pathForResource:@"SKLanguage" ofType:@"plist"];
        assert(languageMetasPath);
        NSArray <NSDictionary *> *languageMetas = [[NSArray alloc] initWithContentsOfFile:languageMetasPath];
        assert([languageMetas isKindOfClass:[NSArray class]]);
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
        
        NSString *languageName = languageMeta[@"name"];
        assert(languageName);
        NSString *languagePath = [[NSBundle mainBundle] pathForResource:languageName ofType:@"tmLanguage"];
        assert(languagePath);
        
        NSDictionary *languageDictionary = [[NSDictionary alloc] initWithContentsOfFile:languagePath];
        assert([languageDictionary isKindOfClass:[NSDictionary class]]);
        
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
        SKLanguage *rawLanguage = [[SKLanguage alloc] initWithDictionary:languageDictionary manager:bundleManager];
        assert(rawLanguage);
        _rawLanguage = rawLanguage;
        
        _comments = languageMeta[@"comments"];
        _indent = languageMeta[@"indent"];
        _folding = languageMeta[@"folding"];
        
        _identifier = languageMeta[@"identifier"];
        _displayName = languageMeta[@"displayName"];
        _name = languageMeta[@"name"];
        _extensions = languageMeta[@"extensions"];
    }
    return self;
}

- (NSString *)pathForLanguageIdentifier:(NSString *)identifier {
    NSString *languageMetasPath = [[NSBundle mainBundle] pathForResource:@"SKLanguage" ofType:@"plist"];
    assert(languageMetasPath);
    NSArray <NSDictionary *> *languageMetas = [[NSArray alloc] initWithContentsOfFile:languageMetasPath];
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
    assert(languageName);
    NSString *languagePath = [[NSBundle mainBundle] pathForResource:languageName ofType:@"tmLanguage"];
    assert(languagePath);
    return languagePath;
}

@end
