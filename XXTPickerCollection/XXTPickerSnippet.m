//
//  XXTPickerSnippet.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTPickerSnippet.h"

#import "XXTLocationPicker.h"
#import "XXTKeyEventPicker.h"
#import "XXTRectanglePicker.h"
#import "XXTPositionPicker.h"
#import "XXTColorPicker.h"
#import "XXTPositionColorPicker.h"
#import "XXTMultiplePositionColorPicker.h"
#import "XXTApplicationPicker.h"
#import "XXTMultipleApplicationPicker.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static NSString * const kXXTELuaVModelErrorDomain = @"kXXTELuaVModelErrorDomain";

void lua_pushNSDictionary(lua_State *L, NSDictionary *dict);
void lua_pushNSArray(lua_State *L, NSArray *dict);
BOOL checkCode(lua_State *L, int code, NSError **error);

void lua_pushNSArray(lua_State *L, NSArray *arr)
{
    int arcount = (int)[arr count];
    lua_newtable(L);
    for (int i=0; i<arcount; ++i) {
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
        NSString *k = [keys objectAtIndex:i];
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

void lua_pushNSObject(lua_State *L, id value)
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

NSString *get_snippet_name(NSString *filename)
{
    static lua_State *L = NULL;
    if (L == NULL) {
        L = luaL_newstate();
        luaL_openlibs(L);
    }
    if (luaL_loadfile(L, [filename UTF8String]) == LUA_OK) {
        if (lua_pcall(L, 0, 1, 0) == LUA_OK && lua_type(L, -1) == LUA_TTABLE) {
            NSString *snippet_name = nil;
            lua_getfield(L, -1, "name");
            if (lua_type(L, -1) == LUA_TSTRING) {
                snippet_name = [NSString stringWithUTF8String:lua_tostring(L, -1)];
            }
            lua_pop(L, 1);
            lua_pop(L, 1);
            return snippet_name;
        }
    }
    return nil;
}

NSArray *get_snippet_arguments(NSString *filename)
{
    static lua_State *L = NULL;
    if (L == NULL) {
        L = luaL_newstate();
        luaL_openlibs(L);
    }
    if (luaL_loadfile(L, [filename UTF8String]) == LUA_OK) {
        if (lua_pcall(L, 0, 1, 0) == LUA_OK && lua_type(L, -1) == LUA_TTABLE) {
            NSMutableArray *args_array = [[NSMutableArray alloc] init];
            lua_getfield(L, -1, "arguments");
            if (lua_type(L, -1) == LUA_TTABLE) {
                int argc = (int)lua_rawlen(L, -1);
                for (int i = 1; i <= argc; ++i) {
                    lua_rawgeti(L, -1, i);
                    if (lua_type(L, -1) == LUA_TSTRING) {
                        [args_array addObject:[NSString stringWithUTF8String:lua_tostring(L, -1)]];
                    }
                    lua_pop(L, 1);
                }
            }
            lua_pop(L, 1);
            lua_pop(L, 1);
            return args_array;
        }
    }
    return nil;
}

NSString *gen_snippet(NSString *filename, NSArray *arguments, NSError **error)
{
    static lua_State *L = NULL;
    if (L == NULL) {
        L = luaL_newstate();
        luaL_openlibs(L);
    }
    if (luaL_loadfile(L, [filename UTF8String]) == LUA_OK) {
        if (lua_pcall(L, 0, 1, 0) == LUA_OK && lua_type(L, -1) == LUA_TTABLE) {
            lua_getfield(L, -1, "generator");
            if (lua_type(L, -1) == LUA_TFUNCTION) {
                NSString *snippet_body = nil;
                for (int i = 0; i < [arguments count]; ++i) {
                    lua_pushNSObject(L, [arguments objectAtIndex:i]);
                }
                int result = lua_pcall(L, (int)[arguments count], 1, 0);
                if (checkCode(L, result, error)) {
                    if (lua_type(L, -1) == LUA_TSTRING) {
                        snippet_body = [NSString stringWithUTF8String:lua_tostring(L, -1)];
                    }
                }
                lua_pop(L, 1);
                return snippet_body;
            }
            lua_pop(L, 1);
            lua_pop(L, 1);
        }
    }
    return nil;
}

BOOL checkCode(lua_State *L, int code, NSError **error) {
    if (LUA_OK != code) {
        const char *cErrString = lua_tostring(L, -1);
        NSString *errString = [NSString stringWithUTF8String:cErrString];
        NSDictionary *errDictionary = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Error", nil),
                                         NSLocalizedFailureReasonErrorKey: errString
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

@interface XXTPickerSnippet ()

@property (nonatomic, strong) NSMutableArray *results;

@end

@implementation XXTPickerSnippet

+ (NSArray <Class> *)pickers {
    // Register Picker Here
    NSArray <Class> *availablePickers =
    @[
      [XXTLocationPicker class], [XXTKeyEventPicker class], [XXTRectanglePicker class],
      [XXTPositionPicker class], [XXTColorPicker class], [XXTPositionColorPicker class],
      [XXTMultiplePositionColorPicker class], [XXTApplicationPicker class], [XXTMultipleApplicationPicker class]
      ];
    for (Class cls in availablePickers) {
        NSString *errorMessage = [NSString stringWithFormat:@"Class %@ type mismatch!", NSStringFromClass(cls)];
        NSAssert([cls isSubclassOfClass:[UIViewController class]], errorMessage);
    }
    return availablePickers;
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    if (self = [super init]) {
        _path = path;
        [self name];
        [self flags];
        _results = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)name {
    if (!_name) {
        NSString *name = get_snippet_name(self.path);
        if (!name) {
            name = [self.path lastPathComponent];
        }
        _name = name;
    }
    return _name;
}

- (NSArray <NSString *> *)flags {
    if (!_flags) {
        _flags = get_snippet_arguments(self.path);
    }
    return _flags;
}

- (NSString *)generateWithError:(NSError **)error {
    return gen_snippet(self.path, [self.results copy], error);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _path = [aDecoder decodeObjectForKey:@"path"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _flags = [aDecoder decodeObjectForKey:@"flags"];
        _results = [aDecoder decodeObjectForKey:@"results"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.flags forKey:@"flags"];
    [aCoder encodeObject:self.results forKey:@"results"];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    XXTPickerSnippet *copy = (XXTPickerSnippet *) [[[self class] allocWithZone:zone] init];
    copy.path = [self.path copyWithZone:zone];
    copy.name = [self.name copyWithZone:zone];
    copy.flags = [self.flags copyWithZone:zone];
    copy.results = [self.results copyWithZone:zone];
    return copy;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    XXTPickerSnippet *copy = (XXTPickerSnippet *) [[[self class] allocWithZone:zone] init];
    copy.path = [self.path mutableCopyWithZone:zone];
    copy.name = [self.name mutableCopyWithZone:zone];
    copy.flags = [self.flags mutableCopyWithZone:zone];
    copy.results = [self.results mutableCopyWithZone:zone];
    return copy;
}

#pragma mark - Generator

- (void)addResult:(id)result {
    if (!result || self.results.count >= self.flags.count) return;
    [self.results addObject:result];
}

- (Class)nextStepClass {
    NSUInteger nextFlagIndex = self.results.count;
    if (nextFlagIndex >= self.flags.count) return nil;
    
    NSString *nextFlag = self.flags[nextFlagIndex];
    
    Class pickerClass;
    for (Class cls in self.class.pickers) {
        NSString *keyword = nil;
        if ([cls respondsToSelector:@selector(pickerKeyword)]) {
            keyword = [cls performSelector:@selector(pickerKeyword)];
        }
        if ([keyword isEqualToString:nextFlag]) {
            pickerClass = cls;
        }
    }
    
    return pickerClass;
}

- (BOOL)taskFinished {
    return (self.results.count >= self.flags.count - 1);
}

- (float)currentProgress {
    return (float)self.results.count / self.flags.count;
}

- (NSUInteger)currentStep {
    return self.results.count + 1;
}

- (NSUInteger)totalStep {
    return self.flags.count;
}

- (void)dealloc {
//#ifdef DEBUG
//    NSLog(@"- [XXTPickerSnippet dealloc]");
//#endif
}

@end
