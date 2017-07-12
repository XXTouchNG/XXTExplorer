//
//  XXTExplorerEntryXPPReader.m
//  XXTExplorer
//
//  Created by Zheng on 12/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryXPPReader.h"
#import "XXTExplorerEntryXPPMeta.h"

@interface XXTExplorerEntryXPPReader ()

@end

@implementation XXTExplorerEntryXPPReader

@synthesize metaDictionary = _metaDictionary;
@synthesize entryPath = _entryPath;
@synthesize entryName = _entryName;
@synthesize entryDisplayName = _entryDisplayName;
@synthesize entryIconImage = _entryIconImage;
@synthesize displayMetaKeys = _displayMetaKeys;

+ (NSArray <NSString *> *)supportedExtensions {
    return @[ @"xpp" ];
}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _displayMetaKeys = @[ kXXTEBundleDisplayName, kXXTEBundleName, kXXTEBundleIdentifier,
                          kXXTEBundleVersion, kXXTEMinimumSystemVersion, kXXTEMaximumSystemVersion,
                          kXXTEMinimumXXTVersion, kXXTESupportedResolutions, kXXTESupportedDeviceTypes,
                          kXXTEExecutable, kXXTEMainInterfaceFile, kXXTEPackageControl ];
    NSFileManager *previewFileManager = [[NSFileManager alloc] init];
    NSString *entryPath = path;
    NSString *metaName = @"Info.plist";
    NSString *languageRegion = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    NSString *languageRegionName = [NSString stringWithFormat:@"%@.lproj", languageRegion];
    NSString *entryLocalizedPath = [entryPath stringByAppendingPathComponent:languageRegionName];
    NSString *entryLocalizedMetaPath = [entryLocalizedPath stringByAppendingPathComponent:metaName];
    NSString *entryMetaPath = [entryPath stringByAppendingPathComponent:metaName];
    NSArray <NSString *> *metaPaths = @[ entryLocalizedMetaPath, entryMetaPath ];
    NSString *existsMetaPath = nil;
    for (NSString *metaPath in metaPaths) {
        BOOL isDirectory = NO;
        BOOL isMetaExists = [previewFileManager fileExistsAtPath:metaPath isDirectory:&isDirectory];
        if (isMetaExists && !isDirectory) {
            existsMetaPath = metaPath;
            break;
        }
    }
    if (!existsMetaPath)
    {
        return;
    }
    NSDictionary *metaInfo = [[NSDictionary alloc] initWithContentsOfFile:existsMetaPath];
    if (!metaInfo)
    {
        return;
    }
    if (!metaInfo[kXXTEBundleIdentifier] ||
        !metaInfo[kXXTEBundleName] ||
        !metaInfo[kXXTEExecutable] ||
        !metaInfo[kXXTEBundleVersion] ||
        !metaInfo[kXXTEBundleInfoDictionaryVersion]
        ) {
        return;
    }
    _entryName = metaInfo[kXXTEBundleName];
    _entryDisplayName = metaInfo[kXXTEBundleDisplayName];
    if (metaInfo[kXXTEBundleIconFile]) {
        NSString *iconFileName = metaInfo[kXXTEBundleIconFile];
        if (iconFileName) {
            NSString *iconFileExtension = [iconFileName pathExtension];
            if (iconFileExtension.length <= 0) {
                iconFileName = [iconFileName stringByAppendingPathExtension:@"png"];
            }
            NSString *iconFilePath = [entryPath stringByAppendingPathComponent:iconFileName];
            if ([previewFileManager fileExistsAtPath:iconFilePath]) {
                UIImage *iconImage = [[UIImage alloc] initWithContentsOfFile:iconFilePath];
                if (iconImage) {
                    _entryIconImage = iconImage;
                }
            }
        }
    }
    _metaDictionary = metaInfo;
}

@end
