
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

void lua_pushNSDictionary(lua_State *L, NSDictionary *dict);
void lua_pushNSArray(lua_State *L, NSArray *arr);
void lua_pushNSValue(lua_State *L, id value);

NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *result);
NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *result);
id lua_toNSValue(lua_State *L, int index);

int luaopen_json(lua_State *L);
int luaopen_plist(lua_State *L);
void lua_openNSValueLibs(lua_State *L);

#ifdef __cplusplus
	}
#endif

#define lua_toNSDictionary(L, IDX) lua_toNSDictionaryx((L), (IDX), nil)
#define lua_toNSArray(L, IDX) lua_toNSArrayx((L), (IDX), nil)

#endif
