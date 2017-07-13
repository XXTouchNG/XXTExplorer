//
//  XXTExplorerEntryMediaReader.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryMediaReader.h"
#import "XXTEMediaPlayerController.h"

@implementation XXTExplorerEntryMediaReader

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
    return [XXTEMediaPlayerController suggestedExtensions];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _displayMetaKeys = @[ ];
    NSString *entryUpperedExtension = [[path pathExtension] uppercaseString];
    _entryIconImage = [UIImage imageNamed:@"XXTEFileReaderType-Media"];
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Media", entryUpperedExtension];
    _entryViewerDescription = [XXTEMediaPlayerController viewerName];
}

@end
