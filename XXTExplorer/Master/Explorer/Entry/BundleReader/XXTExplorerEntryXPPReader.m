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

#import "XXTLuaNSValue.h"
#import <dlfcn.h>

@interface NSBundle (FlushCaches)

- (BOOL)flushCaches;

@end

// First, we declare the function. Making it weak-linked
// ensures the preference pane won't crash if the function
// is removed from in a future version of Mac OS X.
// extern void _CFBundleFlushBundleCaches(CFBundleRef bundle)
// __attribute__((weak_import));

@implementation NSBundle (FlushCaches)

- (BOOL)flushCaches
{
    static void (*flush)(CFBundleRef) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *handle = dlopen(NULL, RTLD_NOW);
        if (handle) {
            flush = dlsym(handle, [NSString stringWithFormat:@"_CF%@Caches", @"BundleFlushBundle"].UTF8String);
        }
    });
    if (flush) {
        CFBundleRef cfBundle =
        CFBundleCreate(nil, (__bridge CFURLRef)[self bundleURL]);
        (*flush)(cfBundle);
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

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        _entryPath = filePath;
        BOOL setupResult = [self setupWithPath:filePath];
        if (!setupResult) return nil;
    }
    return self;
}

- (BOOL)setupWithPath:(NSString *)path {
    _executable = YES;
    _editable = NO;
    _configurable = YES;
    
    // fetch bundle
    NSBundle *pathBundle = [self clearedBundleForPath:path];
    if (!pathBundle)
        return NO;
    
    // fetch meta
    NSString *metaPath = nil;
    if (!metaPath)
        metaPath = [pathBundle pathForResource:@"Info" ofType:@"lua"];
    if (!metaPath)
        metaPath = [pathBundle pathForResource:@"Info" ofType:@"plist"];
    if (!metaPath)
        metaPath = [pathBundle pathForResource:@"Info" ofType:@"json"];
    if (!metaPath)
        return NO;
    NSDictionary *metaInfo = [self metaInfoForEntry:metaPath];
    if (!metaInfo)
        return NO;
    
    // check required metas
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
        return NO;
    }
    
    // fetch localization
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *localizationBundle = pathBundle ? pathBundle : mainBundle;
    
    _entryName = metaInfo[kXXTEBundleName];
    NSString *localizedDescription = [mainBundle localizedStringForKey:(@"Version %@") value:nil table:(@"Meta")];
    if (!localizedDescription)
        localizedDescription = [localizationBundle localizedStringForKey:(@"Version %@") value:nil table:(@"Meta")];
    _entryDescription = [NSString stringWithFormat:localizedDescription, metaInfo[kXXTEBundleVersion]];
    if (metaInfo[kXXTEBundleDisplayName] &&
        [metaInfo[kXXTEBundleDisplayName] isKindOfClass:[NSString class]]) {
        _entryDisplayName = metaInfo[kXXTEBundleDisplayName];
    }
    if (metaInfo[kXXTEBundleIconFile] &&
        [metaInfo[kXXTEBundleIconFile] isKindOfClass:[NSString class]])
    {
        NSString *iconImagePath = [pathBundle pathForResource:metaInfo[kXXTEBundleIconFile] ofType:nil];
        _entryIconImage = [UIImage imageWithContentsOfFile:iconImagePath];
    } else {
        _entryIconImage = [self.class defaultImage];
    }
    _entryExtensionDescription = @"XXTouch Bundle";
    _entryViewerDescription = [XXTEExecutableViewer viewerName];
    NSString *interfaceFile = metaInfo[kXXTEMainInterfaceFile];
    if (interfaceFile)
    {
        _configurationName = interfaceFile;
    } else {
        _configurationName = nil;
    }
    
    _metaKeys = @[ kXXTEBundleDisplayName, kXXTEBundleName, kXXTEBundleIdentifier,
                   kXXTEBundleVersion, kXXTEMinimumSystemVersion, kXXTEMaximumSystemVersion,
                   kXXTEMinimumXXTVersion, kXXTESupportedResolutions, kXXTESupportedDeviceTypes,
                   kXXTEExecutable, kXXTEMainInterfaceFile, kXXTEPackageControl ];
    _metaDictionary = metaInfo;
    return YES;
}

- (NSDictionary *)metaInfoForEntry:(NSString *)path {
    NSDictionary *metaInfo = nil;

    NSString *entryBaseExtension = [[path pathExtension] lowercaseString];
    if ([entryBaseExtension isEqualToString:@"lua"]) {
        lua_State *L = luaL_newstate(); // only for grammar parsing, no bullshit
        NSAssert(L, @"LuaVM: not enough memory.");

        lua_setMaxLine(L, LUA_MAX_LINE);
        luaL_openlibs(L);
        lua_openNSValueLibs(L); // performance?

        int luaResult = luaL_loadfile(L, [path UTF8String]);
        if (lua_checkCode(L, luaResult, nil))
        {
            int callResult = lua_pcall(L, 0, 1, 0);
            if (lua_checkCode(L, callResult, nil))
            {
                if (lua_type(L, -1) == LUA_TTABLE) {
                    metaInfo = lua_toNSDictionary(L, -1);
                }
                lua_pop(L, 1);
            }
        }
        lua_close(L);
        L = NULL;
    } else if ([entryBaseExtension isEqualToString:@"plist"]) {
        metaInfo = [[NSDictionary alloc] initWithContentsOfFile:path];
    } else if ([entryBaseExtension isEqualToString:@"json"]) {
        NSData *metaData = [[NSData alloc] initWithContentsOfFile:path];
        if (metaData) {
            metaInfo = [NSJSONSerialization JSONObjectWithData:metaData options:0 error:nil];
        }
    }

    return metaInfo;
}

- (NSBundle *)clearedBundleForPath:(NSString *)path {
    NSBundle *pathBundle = [NSBundle bundleWithPath:path];
    if (!pathBundle) {
        return nil;
    }
    [pathBundle flushCaches];
    return pathBundle;
}

@end
