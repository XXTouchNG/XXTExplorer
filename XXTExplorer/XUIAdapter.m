//
//  XUIAdapter.m
//  XXTExplorer
//
//  Created by Zheng on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIAdapter.h"
#import "XXTEAppDelegate.h"

#import "XUIBaseCell.h"
#import "LuaNSValue.h"

@implementation XUIAdapter {
    lua_State *L;
}

- (instancetype)initWithXUIPath:(NSString *)path Bundle:(NSBundle *)bundle {
    self = [super init];
    if (self) {
        _path = path;
        _bundle = bundle ? bundle : [NSBundle mainBundle];
        [self setup];
    }
    return self;
}

- (void)setup {
    @synchronized (self) {
        if (!L) {
            L = luaL_newstate();
            NSAssert(L, @"not enough memory");
            luaL_openlibs(L);
            lua_openNSValueLibs(L);
            NSString *adapterPath = [[NSBundle mainBundle] pathForResource:@"XUIAdapter" ofType:@"lua"];
            if (luaL_loadfile(L, adapterPath.UTF8String) == LUA_OK) {
                lua_pushvalue(L, -1);
                lua_setfield(L, LUA_REGISTRYINDEX, "XUIAdapter");
                lua_pop(L, 1);
            }
        }
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
    if (!specValue) return;
    [self setObject:specValue forKey:specKey Defaults:specComponent];
}

- (NSDictionary *)rootEntryWithError:(NSError *__autoreleasing *)error {
    NSString *path = self.path;
    NSBundle *bundle = self.bundle;
    NSString *rootPath = [XXTEAppDelegate sharedRootPath];
    
    if (!path || !bundle || !rootPath) return nil;
    id value = nil;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            lua_pushNSValue(L, @{ @"event": @"load", @"bundlePath": [bundle bundlePath], @"XUIPath": path, @"rootPath": rootPath });
            int entryResult = lua_pcall(L, 1, 1, 0);
            if (checkCode(L, entryResult, error)) {
                value = lua_toNSValue(L, -1);
                lua_pop(L, 1);
            }
        }
    }
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

- (id)objectForKey:(NSString *)key Defaults:(NSString *)identifier {
    return nil;
}

- (void)setObject:(id)obj forKey:(NSString *)key Defaults:(NSString *)identifier {
    if (!obj || !key || !identifier) return;
    
    NSString *path = self.path;
    NSBundle *bundle = self.bundle;
    NSString *rootPath = [XXTEAppDelegate sharedRootPath];
    
    if (!path || !bundle || !rootPath) return;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            lua_pushNSValue(L, @{ @"event": @"save", @"defaultsId": identifier, @"key": key, @"value": obj, @"bundlePath": [bundle bundlePath], @"XUIPath": path, @"rootPath": rootPath });
            int entryResult = lua_pcall(L, 1, 1, 0);
            NSError *saveError = nil;
            if (checkCode(L, entryResult, &saveError)) {
                
            }
        }
    }
    
}

- (void)dealloc {
    if (L) {
        lua_close(L);
        L = NULL;
    }
}

@end
