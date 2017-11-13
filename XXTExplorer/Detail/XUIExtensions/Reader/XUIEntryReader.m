//
// Created by Zheng on 27/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XUIEntryReader.h"
#import "XXTEUIViewController.h"
#import "XXTEEditorController.h"

@implementation XUIEntryReader

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
@synthesize encryptionExtension = _encryptionExtension;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEUIViewController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-XUI"];
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
    NSString *entryExtension = [path pathExtension];
    NSString *entryUpperedExtension = [entryExtension uppercaseString];
    NSString *entryBaseExtension = [entryExtension lowercaseString];
    _editable = (NO == [entryBaseExtension isEqualToString:@"xuic"]);
    _executable = NO;
    if (self.editable) {
        _encryptionType = XXTExplorerEntryReaderEncryptionTypeLocal;
    } else {
        _encryptionType = XXTExplorerEntryReaderEncryptionTypeNone;
    }
    _encryptionExtension = @"xuic";
    UIImage *iconImage = [self.class defaultImage];
    {
        UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
        if (extensionIconImage) {
            iconImage = extensionIconImage;
        }
    }
    _entryIconImage = iconImage;
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Document", entryUpperedExtension];
    _entryViewerDescription = [XXTEUIViewController viewerName];

    // No Meta
}

@end
