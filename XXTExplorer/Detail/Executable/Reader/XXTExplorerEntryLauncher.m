//
//  XXTExplorerEntryLauncher.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryLauncher.h"
#import "XXTEExecutableViewer.h"
#import "XXTEEditorController.h"

@implementation XXTExplorerEntryLauncher

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
    return [XXTEExecutableViewer suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Launcher"];
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
    _executable = YES;
    _editable = ([entryExtension isEqualToString:@"lua"]);
    if (self.editable) {
        _encryptionType = XXTExplorerEntryReaderEncryptionTypeRemote;
        _encryptionExtension = @"xxt";
    } else {
        _encryptionType = XXTExplorerEntryReaderEncryptionTypeNone;
    }
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
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Script", entryUpperedExtension];
    _entryViewerDescription = [XXTEExecutableViewer viewerName];
}

@end
