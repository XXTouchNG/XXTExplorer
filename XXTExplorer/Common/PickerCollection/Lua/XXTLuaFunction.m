//
//  XXTLuaFunction.m
//  XXTExplorer
//
//  Created by Zheng on 03/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTLuaFunction.h"
#import "XXTLuaNSValue.h"

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
