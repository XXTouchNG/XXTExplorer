//
//  XXTExplorerEntryArchiver.m
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryArchiver.h"

@implementation XXTExplorerEntryArchiver

@synthesize metaDictionary = _metaDictionary;
@synthesize entryPath = _entryPath;
@synthesize entryName = _entryName;
@synthesize entryDisplayName = _entryDisplayName;
@synthesize entryIconImage = _entryIconImage;
@synthesize displayMetaKeys = _displayMetaKeys;
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;

+ (NSArray <NSString *> *)supportedExtensions {
    return @[ @"zip" ];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Archiver"];
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
    _entryIconImage = [UIImage imageNamed:[NSString stringWithFormat:@"XXTEFileType-%@", [entryExtension lowercaseString]]];
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Archive", [entryExtension uppercaseString]];
    _entryViewerDescription = @"Archiver";
}

@end
