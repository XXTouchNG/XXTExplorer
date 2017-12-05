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

#import "LuaNSValue.h"

@interface XXTPickerSnippet ()
@property (nonatomic, strong) NSMutableArray *results;
@end

@implementation XXTPickerSnippet {
    lua_State *L;
}

+ (NSArray <Class> *)pickers {
	// Register Picker Here
	NSArray <Class> *availablePickers =
	@[
	  [XXTLocationPicker class],
      [XXTKeyEventPicker class],
      [XXTRectanglePicker class],
	  [XXTPositionPicker class],
      [XXTColorPicker class],
      [XXTPositionColorPicker class],
	  [XXTMultiplePositionColorPicker class],
#ifndef APPSTORE
      [XXTApplicationPicker class],
      [XXTMultipleApplicationPicker class],
#endif
	  ];
	return availablePickers;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupWithError:nil];
    }
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path Error:(NSError **)errorPtr {
	if (self = [super init]) {
		_path = path;
		_results = [[NSMutableArray alloc] init];
        if (![self setupWithError:errorPtr]) return nil;
	}
	return self;
}

- (BOOL)setupWithError:(NSError **)errorPtr {
    NSString *path = self.path;
    if (!path) return NO;
    
    @synchronized (self) {
        if (!L) {
            L = luaL_newstate();
            NSAssert(L, @"LuaVM: not enough memory.");
            
            lua_setMaxLine(L, LUA_MAX_LINE_C);
            luaL_openlibs(L);
            lua_openNSValueLibs(L);
            
            int luaResult = luaL_loadfile(L, [path UTF8String]);
            if (!lua_checkCode(L, luaResult, errorPtr))
                return NO;
            
            int callResult = lua_pcall(L, 0, 1, 0);
            if (!lua_checkCode(L, callResult, errorPtr))
                return NO;
            
            // get name
            if (lua_type(L, -1) == LUA_TTABLE) {
                NSString *snippet_name = nil;
                lua_getfield(L, -1, "name");
                if (lua_type(L, -1) == LUA_TSTRING) {
                    const char *name = lua_tostring(L, -1);
                    if (name)
                        snippet_name = [NSString stringWithUTF8String:name];
                }
                lua_pop(L, 1);
                if (!snippet_name)
                    snippet_name = [self.path lastPathComponent];
                _name = snippet_name;
            }
            
            // get arguments and transform it
            if (lua_type(L, -1) == LUA_TTABLE) {
                NSArray *args_array = nil;
                lua_getfield(L, -1, "arguments");
                if (lua_type(L, -1) == LUA_TTABLE) {
                    args_array = lua_toNSArray(L, -1);
                }
                lua_pop(L, 1);
                _flags = args_array;
            }
            
            // remain table in that stack
        }
    }
    
    return YES;
}

#pragma mark - Getters

- (id)generateWithError:(NSError **)error {
    if (!L) return nil;
    id snippet_body = nil;
    @synchronized (self) {
        NSArray *arguments = [self.results copy];
        lua_getfield(L, -1, "generator"); // push 1
        if (lua_type(L, -1) == LUA_TFUNCTION) { // judge type
            for (int i = 0; i < [arguments count]; ++i) {
                lua_pushNSValue(L, [arguments objectAtIndex:i]);
            }
            int argumentCount = (int)[arguments count];
            int generateResult = lua_pcall(L, argumentCount, 1, 0); // push 2
            if (lua_checkCode(L, generateResult, error))
            {
                snippet_body = lua_toNSValue(L, -1);
                lua_pop(L, 1); // pop 2
            }
        }
        lua_pop(L, 1); // pop 1
    }
	return snippet_body;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init]) {
		_path = [aDecoder decodeObjectForKey:@"path"];
		_name = [aDecoder decodeObjectForKey:@"name"];
		_flags = [aDecoder decodeObjectForKey:@"flags"];
		_results = [aDecoder decodeObjectForKey:@"results"];
        [self setupWithError:nil];
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

#pragma mark - Generator

- (void)addResult:(id)result {
	if (!result || self.results.count >= self.flags.count) return;
	[self.results addObject:result];
}

- (UIViewController <XXTBasePicker> *)nextPicker {
	NSUInteger nextFlagIndex = self.results.count;
	if (nextFlagIndex >= self.flags.count) return nil;
	
	NSDictionary *nextFlagDictionary = self.flags[nextFlagIndex];
    NSString *nextFlag = nextFlagDictionary[@"type"];
	
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
    
    UIViewController <XXTBasePicker> *picker = [[pickerClass alloc] init];
    picker.pickerMeta = nextFlagDictionary;
	
	return picker;
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

#pragma mark - Getters

- (NSArray *)getResults {
    return [self.results copy];
}

- (void)dealloc {
    if (L) {
        lua_pop(L, 1);
        lua_close(L);
        L = NULL;
    }
}

@end
