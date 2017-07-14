//
//  XXTExplorerEntryCodeReader.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryCodeReader.h"
#import "XXTECodeViewerController.h"

@implementation XXTExplorerEntryCodeReader

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
    return [XXTECodeViewerController suggestedExtensions];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
//    NSString *entryUpperedExtension = [[path pathExtension] uppercaseString];
        _entryIconImage = [UIImage imageNamed:@"XXTEFileReaderType-Code"];
//    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Media", entryUpperedExtension];
    _entryViewerDescription = [XXTECodeViewerController viewerName];
}

@end
