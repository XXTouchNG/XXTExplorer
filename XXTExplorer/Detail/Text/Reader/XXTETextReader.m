//
//  XXTETextReader.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTETextReader.h"
#import "XXTETextViewController.h"
#import "XXTEEditorController.h"

@implementation XXTETextReader

@synthesize metaDictionary = _metaDictionary;
@synthesize entryPath = _entryPath;
@synthesize entryName = _entryName;
@synthesize entryDisplayName = _entryDisplayName;
@synthesize entryIconImage = _entryIconImage;
@synthesize metaKeys = _metaKeys;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;
@synthesize executable = _executable;
@synthesize editable = _editable;
@synthesize encryptionType = _encryptionType;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTETextViewController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Text"];
}

+ (Class)relatedEditor {
    return [XXTEEditorController class];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _executable = NO;
    _editable = YES;
    NSString *entryExtension = [path pathExtension];
    NSString *entryBaseExtension = [entryExtension lowercaseString];
    NSString *entryUpperedExtension = [entryExtension uppercaseString];
    UIImage *iconImage = [self.class defaultImage];
    {
        UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
        if (extensionIconImage) {
            iconImage = extensionIconImage;
        }
    }
    _entryIconImage = iconImage;
    if ([entryUpperedExtension isEqualToString:@"TXT"]) {
        _entryExtensionDescription = @"Plain Text";
    }
    _entryViewerDescription = [XXTETextViewController viewerName];
}

@end
