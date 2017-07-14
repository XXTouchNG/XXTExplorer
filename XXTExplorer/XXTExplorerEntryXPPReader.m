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
@synthesize entryDescription = _entryDescription;
@synthesize entryExtensionDescription = _entryExtensionDescription;
@synthesize entryViewerDescription = _entryViewerDescription;

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
    NSBundle *pathBundle = [NSBundle bundleWithPath:path];
//    NSLog(@"%@", [NSBundle preferredLocalizationsFromArray:[[NSBundle bundleWithPath:path] localizations] forPreferences:[NSLocale preferredLanguages]]);
    NSString *existsMetaPath = [pathBundle pathForResource:@"Info" ofType:@"plist"];
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
        ![metaInfo[kXXTEBundleIdentifier] isKindOfClass:[NSString class]] ||
        !metaInfo[kXXTEBundleName] ||
        ![metaInfo[kXXTEBundleName] isKindOfClass:[NSString class]] ||
        !metaInfo[kXXTEExecutable] ||
        ![metaInfo[kXXTEExecutable] isKindOfClass:[NSString class]] ||
        !metaInfo[kXXTEBundleVersion] ||
        ![metaInfo[kXXTEBundleVersion] isKindOfClass:[NSString class]] ||
        !metaInfo[kXXTEBundleInfoDictionaryVersion] ||
        ![metaInfo[kXXTEBundleInfoDictionaryVersion] isKindOfClass:[NSString class]]
        ) {
        return;
    }
    _entryName = metaInfo[kXXTEBundleName];
    _entryDescription = [NSString stringWithFormat:[pathBundle localizedStringForKey:(@"Version %@") value:@"" table:(@"Meta")], metaInfo[kXXTEBundleVersion]];
    if (metaInfo[kXXTEBundleDisplayName] &&
        [metaInfo[kXXTEBundleDisplayName] isKindOfClass:[NSString class]]) {
        _entryDisplayName = metaInfo[kXXTEBundleDisplayName];
    }
    if (metaInfo[kXXTEBundleIconFile] &&
        [metaInfo[kXXTEBundleIconFile] isKindOfClass:[NSString class]])
    {
        _entryIconImage = [UIImage imageNamed:metaInfo[kXXTEBundleIconFile]
                                     inBundle:pathBundle
                compatibleWithTraitCollection:nil];
    }
    _entryExtensionDescription = @"XXTouch Bundle";
    _entryViewerDescription = @"Launcher";
    _metaDictionary = metaInfo;
}

@end
