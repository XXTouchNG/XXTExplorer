//
//  XXTExplorerEntryXPAPackageReader.m
//  XXTExplorer
//
//  Created by Zheng on 19/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryXPAPackageReader.h"
#import "XXTEInstallerViewController.h"

@implementation XXTExplorerEntryXPAPackageReader

@synthesize entryPath = _entryPath;
@synthesize executable = _executable;
@synthesize editable = _editable;
@synthesize entryIconImage = _entryIconImage;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTEInstallerViewController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-XPAPackage"];
}

+ (Class)relatedEditor {
    return nil;
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
    _editable = NO;
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
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Package", entryUpperedExtension];
    _entryViewerDescription = [XXTEInstallerViewController viewerName];
}

@end
