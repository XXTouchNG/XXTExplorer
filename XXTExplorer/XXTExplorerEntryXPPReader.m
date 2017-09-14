//
//  XXTExplorerEntryXPPReader.m
//  XXTExplorer
//
//  Created by Zheng on 12/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryXPPReader.h"
#import "XXTExplorerEntryXPPMeta.h"
#import "XXTEExecutableViewer.h"

@interface NSBundle (FlushCaches)

- (BOOL)flushCaches;

@end

// First, we declare the function. Making it weak-linked
// ensures the preference pane won't crash if the function
// is removed from in a future version of Mac OS X.
extern void _CFBundleFlushBundleCaches(CFBundleRef bundle)
__attribute__((weak_import));

@implementation NSBundle (FlushCaches)

- (BOOL)flushCaches {
    if (_CFBundleFlushBundleCaches != NULL) {
        CFBundleRef cfBundle =
        CFBundleCreate(nil, (CFURLRef)self.bundleURL);
        _CFBundleFlushBundleCaches(cfBundle);
        CFRelease(cfBundle);
        return YES; // Success
    }
    return NO; // Not available
}

@end

@interface XXTExplorerEntryXPPReader ()

@end

@implementation XXTExplorerEntryXPPReader

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
@synthesize configurable = _configurable;
@synthesize configurationName = _configurationName;

+ (NSArray <NSString *> *)supportedExtensions {
    return @[ @"xpp" ];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileType-xpp"];
}

//+ (Class)configurationViewer {
//    return NSClassFromString(@"XUIListViewController");
//}

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        [self setupWithPath:filePath];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _executable = YES;
    _editable = NO;
    _configurable = YES;
    NSBundle *pathBundle = [NSBundle bundleWithPath:path];
    if (!pathBundle) {
        return;
    } else {
        [pathBundle flushCaches];
    }
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
    NSBundle *localizationBundle = pathBundle ? pathBundle : [NSBundle mainBundle];
    _entryName = metaInfo[kXXTEBundleName];
    _entryDescription = [NSString stringWithFormat:[localizationBundle localizedStringForKey:(@"Version %@") value:@"" table:(@"Meta")], metaInfo[kXXTEBundleVersion]];
    if (metaInfo[kXXTEBundleDisplayName] &&
        [metaInfo[kXXTEBundleDisplayName] isKindOfClass:[NSString class]]) {
        _entryDisplayName = metaInfo[kXXTEBundleDisplayName];
    }
    if (metaInfo[kXXTEBundleIconFile] &&
        [metaInfo[kXXTEBundleIconFile] isKindOfClass:[NSString class]])
    {
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_8) {
            _entryIconImage = [UIImage imageNamed:metaInfo[kXXTEBundleIconFile]
                                         inBundle:pathBundle
                    compatibleWithTraitCollection:nil];
        } else {
            NSString *iconImagePath = [pathBundle pathForResource:metaInfo[kXXTEBundleIconFile] ofType:nil];
            _entryIconImage = [UIImage imageWithContentsOfFile:iconImagePath];
        }
        XXTE_END_IGNORE_PARTIAL
    } else {
        _entryIconImage = [self.class defaultImage];
    }
    _entryExtensionDescription = @"XXTouch Bundle";
    _entryViewerDescription = [XXTEExecutableViewer viewerName];
    NSString *interfaceFile = metaInfo[kXXTEMainInterfaceFile];
    if (interfaceFile) {
        NSString *configurationName = [localizationBundle pathForResource:interfaceFile ofType:nil];
        _configurationName = configurationName;
    }
    _metaKeys = @[ kXXTEBundleDisplayName, kXXTEBundleName, kXXTEBundleIdentifier,
                   kXXTEBundleVersion, kXXTEMinimumSystemVersion, kXXTEMaximumSystemVersion,
                   kXXTEMinimumXXTVersion, kXXTESupportedResolutions, kXXTESupportedDeviceTypes,
                   kXXTEExecutable, kXXTEMainInterfaceFile, kXXTEPackageControl ];
    _metaDictionary = metaInfo;
}

@end
