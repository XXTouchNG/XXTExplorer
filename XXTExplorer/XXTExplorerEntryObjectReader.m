//
//  XXTExplorerEntryObjectReader.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryObjectReader.h"
#import "XXTEObjectViewController.h"
#import "XXTEEditorController.h"

@implementation XXTExplorerEntryObjectReader

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

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEObjectViewController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Object"];
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
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Document", entryUpperedExtension];
    _entryViewerDescription = [XXTEObjectViewController viewerName];
}

@end
