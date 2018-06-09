//
//  XXTExplorerEntryMobileConfigReader.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryMobileConfigReader.h"
#import "XXTEMobileConfigViewerController.h"


@interface XXTExplorerEntryMobileConfigReader ()

@end

@implementation XXTExplorerEntryMobileConfigReader

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
    return [XXTEMobileConfigViewerController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-MobileConfig"];
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
    _editable = NO;
    _executable = NO;
    NSString *entryExtension = [path pathExtension];
    NSString *entryBaseExtension = [entryExtension lowercaseString];
    UIImage *iconImage = [self.class defaultImage];
    {
        UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
        if (extensionIconImage) {
            iconImage = extensionIconImage;
        }
    }
    _entryIconImage = iconImage;
    _entryExtensionDescription = @"Configuration Profile";
    _entryViewerDescription = [XXTEMobileConfigViewerController viewerName];
    
    // No Meta
}

@end
