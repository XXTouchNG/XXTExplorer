//
//  XXTExplorerEntrySnippetReader.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntrySnippetReader.h"
#import "XXTESnippetViewerController.h"
#import "XXTEEditorController.h"

#import "LuaNSValue.h"

@interface XXTExplorerEntrySnippetReader ()

@end

@implementation XXTExplorerEntrySnippetReader

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

+ (NSArray <NSString *> *)supportedExtensions {
    return [XXTESnippetViewerController suggestedExtensions];
}

+ (UIImage *)defaultImage {
    return [UIImage imageNamed:@"XXTEFileReaderType-Snippet"];
}

+ (Class)relatedEditor {
    return [XXTEEditorController class];
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
    _editable = YES;
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
    _entryDisplayName = [self nameForEntry:path];
    _entryIconImage = iconImage;
    _entryExtensionDescription = [NSString stringWithFormat:@"%@ Document", entryUpperedExtension];
    _entryViewerDescription = [XXTESnippetViewerController viewerName];
}

- (NSString *)nameForEntry:(NSString *)path {
    NSString *snippet_name = nil;
    lua_State *L = luaL_newstate(); // only for grammar parsing, no bullshit
    if (!L) {
        NSAssert(L, @"LuaVM: not enough memory.");
        return nil;
    }
    luaL_openlibs(L);
    lua_openNSValueLibs(L); // performance?
    int luaResult = luaL_loadfile(L, [path UTF8String]);
    if (checkCode(L, luaResult, nil))
    {
        int callResult = lua_pcall(L, 0, 1, 0);
        if (checkCode(L, callResult, nil))
        {
            if (lua_type(L, -1) == LUA_TTABLE) {
                int fieldType = lua_getfield(L, -1, "name");
                if (fieldType == LUA_TSTRING) {
                    const char *name = lua_tostring(L, -1);
                    if (name)
                        snippet_name = [NSString stringWithUTF8String:name];
                }
                lua_pop(L, 1);
                if (!snippet_name)
                    snippet_name = [path lastPathComponent];
            }
            lua_pop(L, 1);
        }
    }
    lua_close(L);
    L = NULL;
    return snippet_name;
}

@end
