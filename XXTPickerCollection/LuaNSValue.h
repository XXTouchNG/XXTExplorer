
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

        void lua_pushNSDictionaryx(lua_State *L, NSDictionary *dict, int level);
        void lua_pushNSArrayx(lua_State *L, NSArray *arr, int level);
        void lua_pushNSValuex(lua_State *L, id value, int level);

        NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *result, int level);
        NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *result, int level);
        id lua_toNSValuex(lua_State *L, int index, int level);

        int luaopen_json(lua_State *L);
        int luaopen_plist(lua_State *L);
        void lua_openNSValueLibs(lua_State *L);

        NSString * const kXXTELuaVModelErrorDomain;
        BOOL checkCode(lua_State *L, int code, NSError **error);

#ifdef __cplusplus
        }
#endif

#define lua_pushNSDictionary(L, V) lua_pushNSDictionaryx((L), (V), 0)
#define lua_pushNSArray(L, V) lua_pushNSArrayx((L), (V), 0)
#define lua_pushNSValue(L, V) lua_pushNSValuex((L), (V), 0)

#define lua_toNSDictionary(L, IDX) lua_toNSDictionaryx((L), (IDX), nil, 0)
#define lua_toNSArray(L, IDX) lua_toNSArrayx((L), (IDX), nil, 0)
#define lua_toNSValue(L, IDX) lua_toNSValuex((L), (IDX), 0)

#define LUA_NSVALUE_MAX_DEPTH 100

#endif
