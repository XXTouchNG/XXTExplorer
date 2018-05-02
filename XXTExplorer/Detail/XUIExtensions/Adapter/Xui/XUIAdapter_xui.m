//
//  XUIAdapter_xui.m
//  XXTExplorer
//
//  Created by Zheng on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIAdapter_xui.h"

#import "XUIBaseCell.h"
#import "XXTLuaNSValue.h"

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
            if (!adapterPath) {
                return NO; // NSAssert(adapterPath, @"LuaVM: XUIAdapter not found.");
            }
            
            lua_createArgTable(L, adapterPath.fileSystemRepresentation);
            xui_32 *xui = XUICreateWithContentsOfFile(adapterPath.fileSystemRepresentation);
            
            if (!xui) {
                return NO; // NSAssert(xui, @"LuaVM: Cannot decode XUIAdapter.");
            }
            void *xuiBuffer = NULL; uint32_t xuiSize = 0;
            XUICopyRawData(xui, &xuiBuffer, &xuiSize);
            if (xui) XUIRelease(xui);
            if (!xuiBuffer) {
                return NO; // NSAssert(xuiBuffer, @"LuaVM: Cannot decode XUIAdapter.");
            }
            
            size_t xuiSizeT = xuiSize;
            int loadResult = luaL_loadbuffer(L, xuiBuffer, xuiSizeT, adapterPath.UTF8String);
            if (xuiBuffer) free(xuiBuffer);
            
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
    assert([specKey isKindOfClass:[NSString class]] && specKey.length > 0);
    id specValue = cell.xui_value;
    [self setObject:specValue forKey:specKey Defaults:specComponent];
    
    {
        NSMutableDictionary <NSString *, id> *configurationPair = [[NSMutableDictionary alloc] init];
        if (cell.xui_value) configurationPair[@"value"] = cell.xui_value;
        if (cell.xui_key) configurationPair[@"key"] = cell.xui_key;
        if (cell.xui_defaults) configurationPair[@"defaults"] = cell.xui_defaults;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:XUINotificationEventValueChanged object:cell userInfo:[configurationPair copy]];
        
        NSString *customNotificationName = cell.xui_postNotification;
        if (customNotificationName.length)
        {
//            [[NSNotificationCenter defaultCenter] postNotificationName:customNotificationName object:cell userInfo:[configurationPair copy]];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), ((__bridge CFStringRef)customNotificationName), /* aNotification.object */ NULL, /* aNotification.userInfo */ NULL, true);
        }
    }
}

- (NSDictionary *)rootEntryWithError:(NSError *__autoreleasing *)error {
    NSString *path = self.path;
    NSBundle *bundle = self.bundle;
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *rootPath = XXTERootPath();
    
    if (!path || !bundle || !rootPath || !mainBundle) return nil;
    id value = nil;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter_xui");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            id args = @{ @"event": @"load",
                         @"bundlePath": [bundle bundlePath],
                         @"XUIPath": path,
                         @"rootPath": rootPath,
                         @"appPath": [mainBundle bundlePath] };
            lua_pushNSValue(L, args);
            int entryResult = lua_pcall(L, 1, 1, 0);
            if (lua_checkCode(L, entryResult, error)) {
                value = lua_toNSValue(L, -1);
                lua_pop(L, 1);
            }
        } else {
            lua_pop(L, 1);
        }
    }
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString *stringsTable = value[@"stringsTable"];
        if ([stringsTable isKindOfClass:[NSString class]]) {
            _stringsTable = stringsTable;
        }
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
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *rootPath = XXTERootPath();
    
    if (!path || !bundle || !rootPath || !mainBundle) return;
    
    @synchronized (self) {
        lua_getfield(L, LUA_REGISTRYINDEX, "XUIAdapter_xui");
        if (lua_type(L, -1) == LUA_TFUNCTION) {
            id args = @{ @"event": @"save",
                         @"defaultsId": identifier,
                         @"key": key,
                         @"value": saveObj,
                         @"bundlePath": [bundle bundlePath],
                         @"XUIPath": path,
                         @"rootPath": rootPath,
                         @"appPath": [mainBundle bundlePath] };
            lua_pushNSValue(L, args);
            int entryResult = lua_pcall(L, 1, 0, 0);
            NSError *saveError = nil;
            if (lua_checkCode(L, entryResult, &saveError))
            {
                
            }
            if (saveError) {
#ifdef DEBUG
                NSLog(@"%@", [saveError localizedDescription]);
#endif
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
