//
//  XXLuaInterpreter.h
//  LuaTest
//
//  Created by François-Xavier Thomas on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Basic LUA argument types, for smooth interaction with ObjC types.
 */
typedef enum {
    XXLuaArgumentTypeNone,
    XXLuaArgumentTypeString,
    XXLuaArgumentTypeNumber,
    XXLuaArgumentTypeObject,
    XXLuaArgumentTypeBoolean,
    XXLuaArgumentTypeMultiple,
    XXLuaArgumentTypeTable,
    XXLuaArgumentTypeLightObject
} XXLuaArgumentType;

/**
 * Lua Interpreter class. Holds the LUA state and releases it when deallocated.
 */
@interface XXLuaInterpreter : NSObject

@property (nonatomic, retain) NSMutableArray *retainedObjects;

/**
 * Loads a LUA source/binary file in memory, specified by `filepath`, without running it.
 */
- (BOOL) load:(NSString*)filepath;

/**
 * Runs the previously loaded LUA file.
 */
- (BOOL) run;

/**
 * Runs a LUA function
 */
- (id) call:(NSString*)fname withArguments:(id)args, ... NS_REQUIRES_NIL_TERMINATION;
- (id) call:(NSString*)fname expectedReturnCount:(int)count withArguments:(id)args, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Register a selector under a global name, for use inside the LUA program.
 */
- (void) registerSelector:(SEL)selector target:(id)target name:(NSString*)name returnType:(XXLuaArgumentType)returnType argumentTypes:(int)count, ...;
- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name argumentTypes:(int)count, ...;
- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(XXLuaArgumentType)returnType;
- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name;

/**
 * Gets a global value
 */
- (id) global:(NSString*)name;

@end
