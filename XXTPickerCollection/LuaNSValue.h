
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
        extern int lua_table_is_array(lua_State *L, int index);

        extern void lua_pushNSDictionary(lua_State *L, NSDictionary *dict);
        extern void lua_pushNSArray(lua_State *L, NSArray *arr);
        extern void lua_pushNSValue(lua_State *L, id value);

        extern NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *result);
        extern NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *result);
        extern id lua_toNSValue(lua_State *L, int index);

        extern int luaopen_json(lua_State *L);
        extern int luaopen_plist(lua_State *L);
        extern void lua_openNSValueLibs(lua_State *L);

        extern NSString * const kXXTELuaVModelErrorDomain;
        extern BOOL checkCode(lua_State *L, int code, NSError **error);
#ifdef __cplusplus
	}
#endif

#define lua_toNSDictionary(L, IDX) lua_toNSDictionaryx((L), (IDX), nil)
#define lua_toNSArray(L, IDX) lua_toNSArrayx((L), (IDX), nil)

#endif
