//
//  XXTLuaFunction.h
//  XXTExplorer
//
//  Created by Zheng on 03/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "lua.h"
#import "lualib.h"
#import "lauxlib.h"

@interface XXTLuaFunction : NSObject <NSCopying>

- (instancetype)init;

+ (instancetype)bindFunction:(int)idx inLuaState:(lua_State *)L;
- (BOOL)bindFunction:(int)idx inLuaState:(lua_State *)L;
- (BOOL)pushMeToLuaState:(lua_State *)L;

- (NSArray *)callWithArguments:(NSArray *)args error:(NSError **)error;

@end
