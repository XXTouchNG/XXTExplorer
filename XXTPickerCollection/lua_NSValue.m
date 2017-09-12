
#include "lua_NSValue.h"

void lua_pushNSArray(lua_State *L, NSArray *arr)
{
	int arcount = (int)[arr count];
	lua_newtable(L);
	for (int i = 0; i < arcount; ++i) {
		if([[arr objectAtIndex:i] isKindOfClass:[NSData class]]) {
			NSData *d = [arr objectAtIndex:i];
			lua_pushlstring(L, (const char *)[d bytes], [d length]);
			lua_rawseti(L, -2, i + 1);
		} else if([[arr objectAtIndex:i] isKindOfClass:[NSString class]]) {
			NSString *s = [arr objectAtIndex:i];
			lua_pushstring(L, (const char *)[s UTF8String]);
			lua_rawseti(L, -2, i + 1);
		} else if([[arr objectAtIndex:i] isKindOfClass:[NSNumber class]]) {
			NSNumber *n = [arr objectAtIndex:i];
			if (strcmp([n objCType], @encode(BOOL)) == 0) {
				lua_pushboolean(L, [n boolValue]);
			} else if (strcmp([n objCType], @encode(int)) == 0) {
				lua_pushinteger(L, [n intValue]);
			} else if (strcmp([n objCType], @encode(long)) == 0 || strcmp([n objCType], @encode(unsigned long)) == 0) {
				lua_pushinteger(L, [n longValue]);
			} else if (strcmp([n objCType], @encode(long long)) == 0 || strcmp([n objCType], @encode(unsigned long long)) == 0) {
				lua_pushinteger(L, [n longLongValue]);
			} else {
				lua_pushnumber(L, [n doubleValue]);
			}
			lua_rawseti(L, -2, i + 1);
		} else if([[arr objectAtIndex:i] isKindOfClass:[NSDictionary class]]) {
			NSDictionary *di = [arr objectAtIndex:i];
			lua_pushNSDictionary(L, di);
			lua_rawseti(L, -2, i + 1);
		} else if([[arr objectAtIndex:i] isKindOfClass:[NSArray class]]) {
			NSArray *ar = [arr objectAtIndex:i];
			lua_pushNSArray(L, ar);
			lua_rawseti(L, -2, i + 1);
		} else if([[arr objectAtIndex:i] isKindOfClass:[NSNull class]]) {
			lua_pushlightuserdata(L, 0);
			lua_rawseti(L, -2, i + 1);
		}
	}
}

void lua_pushNSDictionary(lua_State *L, NSDictionary *dict)
{
	NSArray *keys = [dict allKeys];
	int kcount = (int)[keys count];
	lua_newtable(L);
	for (int i=0; i<kcount; ++i) {
		id k = [keys objectAtIndex:i];
		if ([[dict valueForKey:k] isKindOfClass:[NSData class]]) {
			NSData *d = [dict valueForKey:k];
			lua_pushlstring(L, (const char *)[d bytes], [d length]);
			lua_setfield(L, -2, [k UTF8String]);
		} else if([[dict valueForKey:k] isKindOfClass:[NSString class]]) {
			NSString *s = [dict valueForKey:k];
			lua_pushstring(L, (const char *)[s UTF8String]);
			lua_setfield(L, -2, [k UTF8String]);
		} else if([[dict valueForKey:k] isKindOfClass:[NSNumber class]]) {
			NSNumber *n = [dict valueForKey:k];
			if (strcmp([n objCType], @encode(BOOL)) == 0) {
				lua_pushboolean(L, [n boolValue]);
			} else if (strcmp([n objCType], @encode(int)) == 0) {
				lua_pushinteger(L, [n intValue]);
			} else if (strcmp([n objCType], @encode(long)) == 0 || strcmp([n objCType], @encode(unsigned long)) == 0) {
				lua_pushinteger(L, [n longValue]);
			} else if (strcmp([n objCType], @encode(long long)) == 0 || strcmp([n objCType], @encode(unsigned long long)) == 0) {
				lua_pushinteger(L, [n longLongValue]);
			} else {
				lua_pushnumber(L, [n doubleValue]);
			}
			lua_setfield(L, -2, [k UTF8String]);
		} else if([[dict valueForKey:k] isKindOfClass:[NSDictionary class]]) {
			NSDictionary *di = [dict valueForKey:k];
			lua_pushNSDictionary(L, di);
			lua_setfield(L, -2, [k UTF8String]);
		} else if([[dict valueForKey:k] isKindOfClass:[NSArray class]]) {
			NSArray *ar = [dict valueForKey:k];
			lua_pushNSArray(L, ar);
			lua_setfield(L, -2, [k UTF8String]);
		} else if([[dict valueForKey:k] isKindOfClass:[NSNull class]]) {
			lua_pushlightuserdata(L, 0);
			lua_setfield(L, -2, [k UTF8String]);
		}
	}
}

void lua_pushNSValue(lua_State *L, id value)
{
	if ([value isKindOfClass:[NSString class]]) {
		lua_pushstring(L, [value UTF8String]);
	} else if ([value isKindOfClass:[NSData class]]) {
		lua_pushlstring(L, (const char *)[value bytes], [value length]);
	} else if ([value isKindOfClass:[NSNumber class]]) {
		if (strcmp([value objCType], @encode(BOOL)) == 0) {
			lua_pushboolean(L, [value boolValue]);
		} else if (strcmp([value objCType], @encode(int)) == 0) {
			lua_pushinteger(L, [value intValue]);
		} else if (strcmp([value objCType], @encode(long)) == 0 || strcmp([value objCType], @encode(unsigned long)) == 0) {
			lua_pushinteger(L, [value longValue]);
		} else if (strcmp([value objCType], @encode(long long)) == 0 || strcmp([value objCType], @encode(unsigned long long)) == 0) {
			lua_pushinteger(L, [value longLongValue]);
		} else {
			lua_pushnumber(L, [value doubleValue]);
		}
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		lua_pushNSDictionary(L, value);
	} else if ([value isKindOfClass:[NSArray class]]) {
		lua_pushNSArray(L, value);
	} else if([value isKindOfClass:[NSNull class]]) {
		lua_pushlightuserdata(L, 0);
	} else {
		lua_pushnil(L);
	}
}

int lua_table_is_array(lua_State *L, int index)
{
	double k;
	int max;
	int items;

	max = 0;
	items = 0;

	lua_pushvalue(L, index);
/* -------------------------------------- */
	lua_getfield(L, -1, "isArray");
	int is_array_flag = !lua_isnoneornil(L, -1);
	if (is_array_flag) {
		lua_pop(L, 2);
		return 1;
	} else {
		lua_pop(L, 1);
	}
/* -------------------------------------- */
	lua_pushnil(L);
	int ret = 1;

	/* table, startkey */
	while (lua_next(L, -2) != 0) {
		/* table, key, value */
		if (lua_type(L, -2) == LUA_TNUMBER &&
			(k = lua_tonumber(L, -2))) {
			/* Integer >= 1 ? */
			if (floor(k) == k && k >= 1) {
				if (k > max)
					max = k;
				items++;
				lua_pop(L, 1);
				continue;
			}
		}

		/* Must not be an array (non integer key) */
		lua_pop(L, 3);
		return 0;
	}

	lua_pop(L, 1);

	if (0 >= items) {
		ret = 0;
	}
	return ret;
}

NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *resultarray)
{
	if (lua_type(L, index) != LUA_TTABLE) {
		return nil;
	}
	if (resultarray == nil) {
		resultarray = [[NSMutableArray alloc] init];
#if !__has_feature(objc_arc)
		[resultarray autorelease];
#endif
	}
	lua_pushvalue(L, index);
    long long n = luaL_len(L, -1);
	for (int i = 1; i <= n; ++i) {
		lua_rawgeti(L, -1, i);
		[resultarray addObject:lua_toNSValue(L, -1)];
		lua_pop(L, 1);
	}
	lua_pop(L, 1);
	return resultarray;
}

NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *resultdict)
{
	if (lua_type(L, index) != LUA_TTABLE) {
		return nil;
	}
	if (resultdict == nil) {
		resultdict = [[NSMutableDictionary alloc] init];
#if !__has_feature(objc_arc)
		[resultdict autorelease];
#endif
	}
	lua_pushvalue(L, index);
	lua_pushnil(L);  /* first key */
	while (lua_next(L, -2) != 0) {
		id key = lua_toNSValue(L, -2);
		if (key != nil) {
			resultdict[key] = lua_toNSValue(L, -1);
		}
		lua_pop(L, 1);
	}
	lua_pop(L, 1);
	return resultdict;
}

id lua_toNSValue(lua_State *L, int index)
{
	int value_type = lua_type(L, index);
	if (value_type == LUA_TSTRING) {
		size_t l;
		const unsigned char *value = (const unsigned char *)luaL_checklstring(L, index, &l);
		NSData *value_data = [NSData dataWithBytes:value length:l];
		NSString *value_string = [NSString alloc];
#if !__has_feature(objc_arc)
		[value_string autorelease];
#endif
		value_string = [value_string initWithData:value_data encoding:NSUTF8StringEncoding];
		if (!value_string) {
			return value_data;
		} else {
			return value_string;
		}
	} else if (value_type == LUA_TNUMBER) {
		if (lua_isinteger(L, index)) {
			return @(luaL_checkinteger(L, index));
		} else {
			int isnum;
			lua_Integer ivalue = lua_tointegerx(L, index, &isnum);
			if (isnum) {
				return @(ivalue);
			} else {
				return @(luaL_checknumber(L, index));
			}
		}
	} else if (value_type == LUA_TBOOLEAN) {
		return @((BOOL)lua_toboolean(L, index));
	} else if (value_type == LUA_TTABLE) {
		if (lua_table_is_array(L, index)) {
			return lua_toNSArrayx(L, index, nil);
		} else {
			return lua_toNSDictionaryx(L, index, nil);
		}
	} else if (value_type == LUA_TLIGHTUSERDATA && lua_touserdata(L, index) == NULL) {
		return [NSNull null];
	}
	return nil;
}

void lua_pushJSONObject(lua_State *L, NSData *jsonData)
{
	NSError *error = nil;
	id value = [NSJSONSerialization JSONObjectWithData:jsonData
		options:NSJSONReadingAllowFragments
		error:&error];
	lua_pushNSValue(L, value);
}

NSData *lua_toJSONData(lua_State *L, int index)
{
	id value = lua_toNSValue(L, index);
	if (value != nil) {
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value
		options:NSJSONWritingPrettyPrinted
		error:&error];
		if (jsonData != nil) {
			return jsonData;
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

int l_fromJSON(lua_State *L)
{
	size_t l;
	const char *json_cstr = luaL_checklstring(L, 1, &l);
	@autoreleasepool {
		NSData *jsonData = [NSData dataWithBytes:json_cstr length:l];
		lua_pushJSONObject(L, jsonData);
	}
	return 1;
}

int l_toJSON(lua_State *L)
{
	@autoreleasepool {
		NSData *jsonData = lua_toJSONData(L, 1);
		if (jsonData != nil) {
			lua_pushlstring(L, (const char *)[jsonData bytes], [jsonData length]);
		} else {
			lua_pushnil(L);
		}
	}
	return 1;
}

int luaopen_json(lua_State *L)
{
	lua_createtable(L, 0, 2);
	lua_pushcfunction(L, l_fromJSON);
	lua_setfield(L, -2, "decode");
	lua_pushcfunction(L, l_toJSON);
	lua_setfield(L, -2, "encode");
	lua_pushlightuserdata(L, (void *)NULL);
	lua_setfield(L, -2, "null");
	lua_pushliteral(L, "0.1");
	lua_setfield(L, -2, "_VERSION");
	return 1;
}

int l_fromPlist(lua_State *L)
{
	const char *filename_cstr = luaL_checkstring(L, 1);
	@autoreleasepool {
		NSString *filename = [NSString stringWithUTF8String:filename_cstr];
		if (filename) {
			NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filename];
			if (dict) {
				lua_pushNSDictionary(L, dict);
			} else {
				lua_pushnil(L);
			}
		} else {
			lua_pushnil(L);
		}
	}
	return 1;
}

int l_toPlist(lua_State *L)
{
	const char *filename_cstr = luaL_checkstring(L, 1);
	luaL_checktype(L, 2, LUA_TTABLE);
	@autoreleasepool {
		NSDictionary *dict = lua_toNSDictionary(L, 2);
		NSString *filename = [NSString stringWithUTF8String:filename_cstr];
		if (dict != nil && filename != nil) {
			lua_pushboolean(L, [dict writeToFile:filename atomically:YES]);
		} else {
			lua_pushboolean(L, NO);
		}
	}
	return 1;
}

int luaopen_plist(lua_State *L)
{
	lua_createtable(L, 0, 2);
	lua_pushcfunction(L, l_fromPlist);
	lua_setfield(L, -2, "read");
	lua_pushcfunction(L, l_toPlist);
	lua_setfield(L, -2, "write");
	lua_pushliteral(L, "0.1");
	lua_setfield(L, -2, "_VERSION");
	return 1;
}

void lua_openNSValueLibs(lua_State *L)
{
	luaL_requiref(L, "json", luaopen_json, YES);
	lua_pop(L, 1);
	luaL_requiref(L, "plist", luaopen_plist, YES);
	lua_pop(L, 1);
}


