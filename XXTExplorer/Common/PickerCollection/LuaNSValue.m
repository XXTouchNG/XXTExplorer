
#include "LuaNSValue.h"
#include "xui32.h"

NSString * const kXXTELuaVModelErrorDomain = @"kXXTELuaVModelErrorDomain";

void lua_pushNSArrayx(lua_State *L, NSArray *arr, int level, int include_func)
{
    if (level > LUA_NSVALUE_MAX_DEPTH) {
        lua_pushnil(L);
        return;
    }
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
            if (n == (id)kCFBooleanFalse || n == (id)kCFBooleanTrue || [n class] == [@(NO) class]) {
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
            lua_pushNSDictionaryx(L, di, level + 1, include_func);
            lua_rawseti(L, -2, i + 1);
        } else if([[arr objectAtIndex:i] isKindOfClass:[NSArray class]]) {
            NSArray *ar = [arr objectAtIndex:i];
            lua_pushNSArrayx(L, ar, level + 1, include_func);
            lua_rawseti(L, -2, i + 1);
        } else if([[arr objectAtIndex:i] isKindOfClass:[NSNull class]]) {
            lua_pushlightuserdata(L, 0);
            lua_rawseti(L, -2, i + 1);
        } else if (include_func && [[arr objectAtIndex:i] isKindOfClass:[XXTLuaFunction class]]) {
            if ([[arr objectAtIndex:i] pushMeToLuaState:L]) {
                lua_rawseti(L, -2, i + 1);
            }
        }
    }
}

void lua_pushNSDictionaryx(lua_State *L, NSDictionary *dict, int level, int include_func)
{
    if (level > LUA_NSVALUE_MAX_DEPTH) {
        lua_pushnil(L);
        return;
    }
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
            if (n == (id)kCFBooleanFalse || n == (id)kCFBooleanTrue || [n class] == [@(NO) class]) {
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
            lua_pushNSDictionaryx(L, di, level + 1, include_func);
            lua_setfield(L, -2, [k UTF8String]);
        } else if([[dict valueForKey:k] isKindOfClass:[NSArray class]]) {
            NSArray *ar = [dict valueForKey:k];
            lua_pushNSArrayx(L, ar, level + 1, include_func);
            lua_setfield(L, -2, [k UTF8String]);
        } else if([[dict valueForKey:k] isKindOfClass:[NSNull class]]) {
            lua_pushlightuserdata(L, 0);
            lua_setfield(L, -2, [k UTF8String]);
        } else if(include_func && [[dict valueForKey:k] isKindOfClass:[XXTLuaFunction class]]) {
            if ([[dict valueForKey:k] pushMeToLuaState:L]) {
                lua_setfield(L, -2, [k UTF8String]);
            }
        }
    }
}

void lua_pushNSValuex(lua_State *L, id value, int level, int include_func)
{
    if ([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [value UTF8String]);
    } else if ([value isKindOfClass:[NSData class]]) {
        lua_pushlstring(L, (const char *)[value bytes], [value length]);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (value == (id)kCFBooleanFalse || value == (id)kCFBooleanTrue || [value class] == [@(NO) class]) {
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
        lua_pushNSDictionaryx(L, value, level + 1, include_func);
    } else if ([value isKindOfClass:[NSArray class]]) {
        lua_pushNSArrayx(L, value, level + 1, include_func);
    } else if([value isKindOfClass:[NSNull class]]) {
        lua_pushlightuserdata(L, 0);
    } else if(include_func && [value isKindOfClass:[XXTLuaFunction class]]) {
        if (![value pushMeToLuaState:L]) {
            lua_pushnil(L);
        }
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

NSArray *lua_toNSArrayx(lua_State *L, int index, NSMutableArray *resultarray, int level, int include_func)
{
    if (level > LUA_NSVALUE_MAX_DEPTH) {
        return nil;
    }
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
        id value = lua_toNSValuex(L, -1, level, include_func);
        if (value != nil) {
            [resultarray addObject:value];
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    return resultarray;
}

NSDictionary *lua_toNSDictionaryx(lua_State *L, int index, NSMutableDictionary *resultdict, int level, int include_func)
{
    if (level > LUA_NSVALUE_MAX_DEPTH) {
        return nil;
    }
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
        id key = lua_toNSValuex(L, -2, level, include_func);
        if (key != nil) {
            id value = lua_toNSValuex(L, -1, level, include_func);
            if (value != nil) {
                resultdict[key] = value;
            }
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    return resultdict;
}

id lua_toNSValuex(lua_State *L, int index, int level, int include_func)
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
            return lua_toNSArrayx(L, index, nil, level + 1, include_func);
        } else {
            return lua_toNSDictionaryx(L, index, nil, level + 1, include_func);
        }
    } else if (value_type == LUA_TLIGHTUSERDATA && lua_touserdata(L, index) == NULL) {
        return [NSNull null];
    } else if (include_func && value_type == LUA_TFUNCTION) {
        XXTLuaFunction *value_func = [[XXTLuaFunction alloc] init];
#if !__has_feature(objc_arc)
        [value_func autorelease];
#endif
        if ([value_func bindFunction:index inLuaState:L]) {
            return value_func;
        } else {
            return nil;
        }
    }
    return nil;
}

void lua_pushJSONObject(lua_State *L, NSData *jsonData)
{
    NSError *error = nil;
    id value = [NSJSONSerialization JSONObjectWithData:jsonData
        options:NSJSONReadingAllowFragments
        error:&error];
    lua_pushNSValuex(L, value, 0, NO);
}

NSData *lua_toJSONData(lua_State *L, int index)
{
    id value = lua_toNSValuex(L, index, 0, NO);
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
    lua_pushliteral(L, "0.3");
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
                lua_pushNSDictionaryx(L, dict, 0, NO);
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
        NSDictionary *dict = lua_toNSDictionaryx(L, 2, nil, 0, NO);
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
    lua_pushliteral(L, "0.3");
    lua_setfield(L, -2, "_VERSION");
    return 1;
}

int l_decodeXUI(lua_State *L)
{
    size_t l;
    const char *xui_cstr = luaL_checklstring(L, 1, &l);
    xui_32 *xui = XUICreateWithData(xui_cstr, (uint32_t)l);
    uint32_t len = 0;
    void *raw = NULL;
    XUICopyRawData(xui, &raw, &len);
    if (raw != nil) {
        size_t rawLen = 0;
        rawLen += len;
        lua_pushlstring(L, raw, rawLen);
    } else {
        lua_pushnil(L);
    }
    free(raw);
    XUIRelease(xui);
    return 1;
}

int luaopen_xui(lua_State *L)
{
    lua_createtable(L, 0, 2);
    lua_pushcfunction(L, l_decodeXUI);
    lua_setfield(L, -2, "decode");
    lua_pushliteral(L, "0.2");
    lua_setfield(L, -2, "_VERSION");
    return 1;
}

void lua_openNSValueLibs(lua_State *L)
{
    luaL_requiref(L, "json", luaopen_json, YES);
    lua_pop(L, 1);
    luaL_requiref(L, "plist", luaopen_plist, YES);
    lua_pop(L, 1);
    luaL_requiref(L, "xui", luaopen_xui, YES);
    lua_pop(L, 1);
}

void lua_setPath(lua_State* L, const char *key, const char *path)
{
    lua_getglobal(L, "package");
    lua_getfield(L, -1, key); // get field "path" from table at top of stack (-1)
    const char *origPath = lua_tostring(L, -1); // grab path string from top of stack
    NSString *strPath = [[NSString alloc] initWithUTF8String:path];
    NSString *strOrigPath = [[NSString alloc] initWithUTF8String:origPath];
    strOrigPath = [strOrigPath stringByAppendingString:@";"];
    strOrigPath = [strOrigPath stringByAppendingString:strPath];
    strOrigPath = [strOrigPath stringByAppendingString:@";"];
    lua_pop(L, 1); // get rid of the string on the stack we just pushed on line 5
    lua_pushstring(L, [strOrigPath UTF8String]); // push the new one
    lua_setfield(L, -2, key); // set the field "path" in table at -2 with value at top of stack
    lua_pop(L, 1); // get rid of package table from top of stack
}

BOOL lua_checkCode(lua_State *L, int code, NSError **error) {
    if (LUA_OK != code) {
        const char *cErrString = lua_tostring(L, -1);
        NSString *errString = [NSString stringWithUTF8String:cErrString];
        NSDictionary *errDictionary = @{ NSLocalizedDescriptionKey: errString,
                                         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error", nil),
                                         };
        lua_pop(L, 1);
        if (error != nil)
            *error = [NSError errorWithDomain:kXXTELuaVModelErrorDomain
                                         code:code
                                     userInfo:errDictionary];
        return NO;
    }
    return YES;
}

static void ____lua_setmaxline_hook(lua_State *L, lua_Debug *ar)
{
    lua_getfield(L, LUA_REGISTRYINDEX, "lua_setmaxline_line_count");
    lua_Integer *line_count_ptr = (lua_Integer *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    *line_count_ptr = *line_count_ptr - 1;
    if (*line_count_ptr < 0) {
        luaL_error(L, "line overflow");
    }
}

void lua_setMaxLine(lua_State *L, lua_Integer maxline)
{
    lua_Integer *line_count_ptr = (lua_Integer *)lua_newuserdata(L, sizeof(lua_Integer));
    lua_setfield(L, LUA_REGISTRYINDEX, "lua_setmaxline_line_count");
    *line_count_ptr = maxline;
    lua_sethook(L, ____lua_setmaxline_hook, LUA_MASKLINE, 0);
}

@implementation XXTLuaFunction
{
@private
    lua_State *m_L;
    int m_refIndex;
}

-(id)init
{
    self = [super init];
    m_L = NULL;
    m_refIndex = 0;
    return self;
}

-(void)dealloc
{
    if (m_L != NULL) {
        luaL_unref(m_L, LUA_REGISTRYINDEX, m_refIndex);
    }
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

-(id)copyWithZone:(NSZone *)zone
{
    XXTLuaFunction *func = [[[self class] allocWithZone:zone] init];
    if (m_L != NULL) {
        lua_rawgeti(m_L, LUA_REGISTRYINDEX, m_refIndex);
        [func bindFunction:-1 inLuaState:m_L];
        lua_pop(m_L, 1);
    }
    return func;
}

-(BOOL)bindFunction:(int)idx inLuaState:(lua_State *)L
{
    if (L != NULL && lua_type(L, idx) == LUA_TFUNCTION) {
        m_L = L;
        lua_pushvalue(m_L, idx);
        m_refIndex = luaL_ref(m_L, LUA_REGISTRYINDEX);
        return YES;
    } else {
        return NO;
    }
}

+(id)bindFunction:(int)idx inLuaState:(lua_State *)L
{
    XXTLuaFunction *func = [[self alloc] init];
    if ([func bindFunction:idx inLuaState:L]) {
#if !__has_feature(objc_arc)
        [func autorelease];
#endif
        return func;
    } else {
#if !__has_feature(objc_arc)
        [func release];
#endif
        return nil;
    }
}

-(BOOL)pushMeToLuaState:(lua_State *)L
{
    if (m_L != NULL && L == m_L) {
        int type = lua_rawgeti(m_L, LUA_REGISTRYINDEX, m_refIndex);
        if (type == LUA_TFUNCTION) {
            return YES;
        } else {
            lua_pop(m_L, 1);
            return NO;
        }
    } else {
        return NO;
    }
}

-(NSArray *)callWithArguments:(NSArray *)args error:(NSError **)error
{
    if (m_L != NULL) {
        int last_top = lua_gettop(m_L);
        int type = lua_rawgeti(m_L, LUA_REGISTRYINDEX, m_refIndex);
        if (type == LUA_TFUNCTION) {
            if (args == nil) {
                args = @[];
            }
            for (id arg in args) {
                lua_pushNSValuex(m_L, arg, 0, YES);
            }
            int ret_stat = lua_pcall(m_L, (int)[args count], 1, 0);
            int nresults = lua_gettop(m_L) - last_top;
            if (!lua_checkCode(m_L, ret_stat, error)) {
                return nil;
            } else {
                NSMutableArray *results = [NSMutableArray array];
                for (int i = 0; i < nresults; ++i) {
                    id value = lua_toNSValuex(m_L, i + 1, 0, YES);
                    if (value != nil) {
                        [results addObject:value];
                    } else {
                        [results addObject:[NSNull null]];
                    }
                }
                lua_pop(m_L, nresults);
                return results;
            }
        } else {
            if (error != nil) {
                *error = [NSError errorWithDomain:kXXTELuaVModelErrorDomain code:1001 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"expected function got %s", lua_typename(m_L, type)]}];
            }
            return nil;
        }
    } else {
        if (error != nil) {
            *error = [NSError errorWithDomain:kXXTELuaVModelErrorDomain code:1000 userInfo:@{NSLocalizedFailureReasonErrorKey: @"not initialized"}];
        }
        return nil;
    }
}

@end
