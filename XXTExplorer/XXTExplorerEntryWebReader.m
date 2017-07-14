//
//  XXTExplorerEntryWebReader.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryWebReader.h"
#import "XXTEWebViewerController.h"

@implementation XXTExplorerEntryWebReader

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
    return [XXTEWebViewerController suggestedExtensions];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    NSString *entryUpperedExtension = [[path pathExtension] uppercaseString];
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Document", entryUpperedExtension];
    _entryViewerDescription = [XXTEWebViewerController viewerName];
    
    // No Meta
}

@end
