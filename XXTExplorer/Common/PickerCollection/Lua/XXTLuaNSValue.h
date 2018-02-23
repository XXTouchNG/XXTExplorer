//
//  XXTLuaNSValue.h
//  XXTExplorer
//
//  Created by Zheng on 03/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#ifndef LUA_NSVALUE_H
#define LUA_NSVALUE_H

#import <Foundation/Foundation.h>

#ifdef __cplusplus

        #import "lua.hpp"

#else

        #import "lua.h"
        #import "lualib.h"
        #import "lauxlib.h"

#endif

#ifdef __cplusplus
        extern "C" {
#endif

        int lua_table_is_array(lua_State *L, int index);

        void lua_pushNSDictionaryx(lua_State *L, NSDictionary *dict, int level, int include_func);
        void lua_pushNSArrayx(lua_State *L, NSArray *arr, int level, int include_func);
        void lua_pushNSValuex(lua_State *L, id value, int level, int include_func);

        NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *result, int level, int include_func);
        NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *result, int level, int include_func);
        id lua_toNSValuex(lua_State *L, int index, int level, int include_func);

        int luaopen_json(lua_State *L);
        int luaopen_plist(lua_State *L);
        void lua_openNSValueLibs(lua_State *L);
        void lua_createArgTable(lua_State *L, const char *path);
        void lua_setPath(lua_State* L, const char *key, const char *path);

        extern NSString * const kXXTELuaVModelErrorDomain;
        BOOL lua_checkCode(lua_State *L, int code, NSError **error);
        void lua_setMaxLine(lua_State *L, lua_Integer maxline);
        
        int xxt_system(const char *ctx);
        
#ifdef __cplusplus
        }
#endif

#define lua_pushNSDictionary(L, V) lua_pushNSDictionaryx((L), (V), 0, 1)
#define lua_pushNSArray(L, V) lua_pushNSArrayx((L), (V), 0, 1)
#define lua_pushNSValue(L, V) lua_pushNSValuex((L), (V), 0, 1)

#define lua_toNSDictionary(L, IDX) lua_toNSDictionaryx((L), (IDX), nil, 0, 1)
#define lua_toNSArray(L, IDX) lua_toNSArrayx((L), (IDX), nil, 0, 1)
#define lua_toNSValue(L, IDX) lua_toNSValuex((L), (IDX), 0, 1)

#define LUA_NSVALUE_MAX_DEPTH 50

#define LUA_MAX_LINE 10000
#define LUA_MAX_LINE_B 100000
#define LUA_MAX_LINE_C 1000000

#endif
