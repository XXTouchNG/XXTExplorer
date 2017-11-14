//
//  XUIAdapter_xui.m
//  XXTExplorer
//
//  Created by Zheng on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIAdapter_xui.h"
#import "XXTEAppDelegate.h"

#import "XUIBaseCell.h"
#import "LuaNSValue.h"

#import "XUI.h"
#import "xui32.h"

@implementation XUIAdapter_xui {
    lua_State *L;
}

@synthesize path = _path, bundle = _bundle, stringsTable = _stringsTable;

- (instancetype)initWithXUIPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
        _bundle = [NSBundle mainBundle];
        BOOL setupResult = [self setupWithError:nil];
        if (!setupResult) return nil;
    }
    return self;
}

- (instancetype)initWithXUIPath:(NSString *)path Bundle:(NSBundle *)bundle {
    self = [super init];
    if (self) {
        _path = path;
        _bundle = bundle ? bundle : [NSBundle mainBundle];
        BOOL setupResult = [self setupWithError:nil];
        if (!setupResult) return nil;
    }
    return self;
}

- (BOOL)setupWithError:(NSError **)error {
    @synchronized (self) {
        if (!L) {
            
            L = luaL_newstate();
            NSAssert(L, @"LuaVM: not enough memory.");

            lua_setMaxLine(L, LUA_MAX_LINE_B);
            luaL_openlibs(L);
            lua_openNSValueLibs(L);
            
            NSString *adapterPath = [[NSBundle mainBundle] pathForResource:@"XUIAdapter_xui" ofType:@"xuic"];
            NSAssert(adapterPath, @"LuaVM: XUIAdapter not found.");
            xui_32 *xui = XUICreateWithContentsOfFile(adapterPath.UTF8String);
            
            NSAssert(xui, @"LuaVM: Cannot decode XUIAdapter.");
            void *xuiBuffer = NULL; uint32_t xuiSize = 0;
            XUICopyRawData(xui, &xuiBuffer, &xuiSize);
            if (xui) free(xui);
            
            NSAssert(xuiBuffer, @"LuaVM: Cannot decode XUIAdapter.");
            size_t xuiSizeT = xuiSize;
            int loadResult = luaL_loadbuffer(L, xuiBuffer, xuiSizeT, adapterPath.UTF8String);
            if (xuiBuffer) free(xuiBuffer);
            
//            int loadResult = luaL_loadfile(L, adapterPath.UTF8String);
            if (!lua_checkCode(L, loadResult, error)) {
                return NO;
            }
            lua_pushvalue(L, -1);
            lua_setfield(L, LUA_REGISTRYINDEX, "XUIAdapter_xui");
            lua_pop(L, 1);
            
            return YES;
        }
        return NO;
    }
}

- (void)saveDefaultsFromCell:(XUIBaseCell *)cell {
    NSString *specComponent = nil;
    if (!specComponent) specComponent = cell.xui_defaults;
    if (!specComponent) return;
    assert([specComponent isKindOfClass:[NSString class]] && specComponent.length > 0);
    NSString *specKey = cell.xui_key;
    if (!specKey) return;
    assert ([specKey isKindOfClass:[NSString class]] && specKey.length > 0);
    id specValue = cell.xui_value;
    [self setObject:specValue forKey:specKey Defaults:specComponent];
    [[NSNotificationCenter defaultCenter] postNotificationName:XUINotificationEventValueChanged object:cell userInfo:@{}];
}

- (NSDictionary *)rootEntryWithError:(NSError *__autoreleasing *)error {
    NSString *path = self.path;
    NSBundle *bundle = self.bundle;
    NSString *rootPath = [XXTEAppDelegate sharedRootPath];
    
    if (!path || !bundle || !rootPath) return nil;
    id value = nil;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter_xui");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            id args = @{ @"event": @"load", @"bundlePath": [bundle bundlePath], @"XUIPath": path, @"rootPath": rootPath };
            lua_pushNSValue(L, args);
            int entryResult = lua_pcall(L, 1, 1, 0);
            if (lua_checkCode(L, entryResult, error)) {
                value = lua_toNSValue(L, -1);
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
    }
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString *stringsTable = value[@"stringsTable"];
        if ([stringsTable isKindOfClass:[NSString class]]) {
            _stringsTable = stringsTable;
        }
#ifdef DEBUG
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:error];
        [jsonData writeToFile:[self.path stringByAppendingPathExtension:@"json"] atomically:YES];
        [value writeToFile:[self.path stringByAppendingPathExtension:@"plist"] atomically:YES];
#endif
        return value;
    }
    return nil;
}

- (id)objectForKey:(NSString *)key Defaults:(NSString *)identifier {
    return nil;
}

- (void)setObject:(id)obj forKey:(NSString *)key Defaults:(NSString *)identifier {
    if (!key || !identifier) return;
    id saveObj = obj ? obj : [[NSObject alloc] init];
    
    NSString *path = self.path;
    NSBundle *bundle = self.bundle;
    NSString *rootPath = [XXTEAppDelegate sharedRootPath];
    
    if (!path || !bundle || !rootPath) return;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter_xui");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            id args = @{ @"event": @"save", @"defaultsId": identifier, @"key": key, @"value": saveObj, @"bundlePath": [bundle bundlePath], @"XUIPath": path, @"rootPath": rootPath };
            lua_pushNSValue(L, args);
            int entryResult = lua_pcall(L, 1, 0, 0);
            NSError *saveError = nil;
            if (lua_checkCode(L, entryResult, &saveError))
            {
                
            }
        }
        lua_pop(L, -1);
    }
}

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSString *localized = [self.bundle localizedStringForKey:key value:value table:self.stringsTable];
    return localized ? localized : value;
}

- (void)dealloc {
    if (L) {
        lua_close(L);
        L = NULL;
    }
}

@end
