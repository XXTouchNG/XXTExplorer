//
//  XXTPickerSnippet.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerSnippet.h"

#import "XXTLuaNSValue.h"
#import "xui32.h"


@interface XXTPickerSnippet ()

@end

@implementation XXTPickerSnippet {
    lua_State *L;
}


- (instancetype)initWithContentsOfFile:(NSString *)path Error:(NSError **)errorPtr
{
    return [self initWithContentsOfFile:path Adapter:nil Error:errorPtr];
}

- (instancetype)initWithContentsOfFile:(NSString *)path Adapter:(id <XUIAdapter>)adapter Error:(NSError **)errorPtr
{
	if (self = [super init]) {
		_path = path;
        _adapter = adapter;
        if (![self setupWithError:errorPtr]) return nil;
	}
	return self;
}

- (BOOL)setupWithError:(NSError **)errorPtr {
    NSString *path = self.path;
    if (!path) return NO;
    
    @synchronized (self) {
        if (!L) {
            
            // new lua state
            L = luaL_newstate();
            NSAssert(L, @"LuaVM: not enough memory.");
            
            // universal libraries
            lua_setMaxLine(L, LUA_MAX_LINE_C);
            luaL_openlibs(L);
            lua_openNSValueLibs(L);
            
            // create arg table
            lua_createArgTable(L, path.fileSystemRepresentation);
            
            // xui adapter
            id <XUIAdapter> adapter = self.adapter;
            if (adapter)
            {
                NSBundle *bundle = adapter.bundle;
                NSString *rootPath = XXTERootPath();
                NSBundle *mainBundle = [NSBundle mainBundle];
                if (!bundle || !rootPath || !mainBundle)
                    return NO;
                
                lua_openXPPLibs(L);
                lua_ocobject_set(L, "xpp.bundle", bundle);
                
                NSString *adapterPath = [mainBundle pathForResource:@"XUIAdapter_xui" ofType:@"xuic"];
                if (!adapterPath) return NO;
                
                // parse xui format
                xui_32 *xui = XUICreateWithContentsOfFile(adapterPath.fileSystemRepresentation);
                if (!xui) return NO;
                void *xuiBuffer = NULL; uint32_t xuiSize = 0;
                XUICopyRawData(xui, &xuiBuffer, &xuiSize);
                if (xui) XUIRelease(xui);
                if (!xuiBuffer) return NO;
                size_t xuiSizeT = xuiSize;
                int loadResult = luaL_loadbuffer(L, xuiBuffer, xuiSizeT, adapterPath.UTF8String);
                if (xuiBuffer) free(xuiBuffer);
                if (!lua_checkCode(L, loadResult, errorPtr)) return NO;
                
                // load adapter libraries
                NSDictionary *args = @{ @"bundlePath": [bundle bundlePath],
                                        @"XUIPath": path,
                                        @"rootPath": rootPath,
                                        @"appPath": [mainBundle bundlePath] };
                lua_pushNSValue(L, args);
                int entryResult = lua_pcall(L, 1, 1, 0);
                if (!lua_checkCode(L, entryResult, errorPtr)) return NO;
                
                // clear that function
                lua_pop(L, 1);
            }
            
            // load snippet
            int luaResult = luaL_loadfile(L, path.fileSystemRepresentation);
            if (!lua_checkCode(L, luaResult, errorPtr))
                return NO;
            
            // get root table
            int callResult = lua_pcall(L, 0, 1, 0);
            if (!lua_checkCode(L, callResult, errorPtr))
                return NO;
            
            // get name
            if (lua_type(L, -1) == LUA_TTABLE) {
                NSString *snippet_name = nil;
                lua_getfield(L, -1, "name");
                if (lua_type(L, -1) == LUA_TSTRING) {
                    const char *name = lua_tostring(L, -1);
                    if (name)
                        snippet_name = [NSString stringWithUTF8String:name];
                }
                lua_pop(L, 1);
                if (!snippet_name)
                    snippet_name = [self.path lastPathComponent];
                _name = snippet_name;
            }
            
            // get output
            if (lua_type(L, -1) == LUA_TTABLE) {
                NSString *snippet_output = nil;
                lua_getfield(L, -1, "output");
                if (lua_type(L, -1) == LUA_TSTRING) {
                    const char *output = lua_tostring(L, -1);
                    if (output)
                        snippet_output = [NSString stringWithUTF8String:output];
                }
                lua_pop(L, 1);
                if (!snippet_output)
                    snippet_output = @"";
                _output = snippet_output;
            }
            
            // get arguments and transform it
            if (lua_type(L, -1) == LUA_TTABLE) {
                NSArray *args_array = nil;
                lua_getfield(L, -1, "arguments");
                if (lua_type(L, -1) == LUA_TTABLE) {
                    args_array = lua_toNSArray(L, -1);
                }
                lua_pop(L, 1);
                _flags = args_array;
            }
            
            // copy and register that table
            lua_pushvalue(L, -1);
            lua_setfield(L, LUA_REGISTRYINDEX, NSStringFromClass([self class]).UTF8String);
            
            // clear
            lua_pop(L, 1);
        }
    }
    
    return YES;
}

- (id)generateWithResults:(NSArray *)results Error:(NSError **)error {
    if (!L) return nil;
    id snippet_body = nil;
    @synchronized (self) {
        NSArray *arguments = [results copy];
        lua_getfield(L, LUA_REGISTRYINDEX, NSStringFromClass([self class]).UTF8String);
        if (lua_type(L, -1) == LUA_TTABLE) {
            lua_getfield(L, -1, "generator");
            if (lua_type(L, -1) == LUA_TFUNCTION) {
                for (int i = 0; i < [arguments count]; ++i) {
                    lua_pushNSValue(L, [arguments objectAtIndex:i]);
                }
                int argumentCount = (int)[arguments count];
                int generateResult = lua_pcall(L, argumentCount, 1, 0);
                if (lua_checkCode(L, generateResult, error))
                {
                    snippet_body = lua_toNSValue(L, -1);
                    lua_pop(L, 1);
                }
            } else {
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
    }
    return snippet_body;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
    if (L) {
        lua_ocobject_free(L, "xpp.bundle");
        lua_close(L);
        L = NULL;
    }
}

@end
