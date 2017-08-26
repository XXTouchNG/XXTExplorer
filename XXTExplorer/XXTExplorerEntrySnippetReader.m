//
//  XXTExplorerEntrySnippetReader.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntrySnippetReader.h"
#import "XXTESnippetViewerController.h"
#import "XXTEEditorController.h"

#import "XXTPickerSnippet.h"

@interface XXTExplorerEntrySnippetReader ()

@property (nonatomic, strong) XXTPickerSnippet *snippet;

@end

@implementation XXTExplorerEntrySnippetReader

@synthesize metaDictionary = _metaDictionary;
@synthesize entryPath = _entryPath;
@synthesize entryName = _entryName;
@synthesize entryDisplayName = _entryDisplayName;
@synthesize entryIconImage = _entryIconImage;
@synthesize displayMetaKeys = _displayMetaKeys;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;
@synthesize executable = _executable;
@synthesize editable = _editable;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTESnippetViewerController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Snippet"];
}

+ (Class)relatedEditor {
    return [XXTEEditorController class];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        _snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:filePath];
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _executable = NO;
    _editable = YES;
    NSString *entryExtension = [path pathExtension];
    NSString *entryBaseExtension = [entryExtension lowercaseString];
    UIImage *iconImage = [self.class defaultImage];
    {
        UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
        if (extensionIconImage) {
            iconImage = extensionIconImage;
        }
    }
    _entryDisplayName = self.snippet.name;
    _entryIconImage = iconImage;
    _entryViewerDescription = [XXTECodeViewerController viewerName];
}

@end
