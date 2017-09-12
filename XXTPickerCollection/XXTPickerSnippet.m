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

#import "lua_NSValue.h"

static NSString * const kXXTELuaVModelErrorDomain = @"kXXTELuaVModelErrorDomain";

BOOL checkCode(lua_State *L, int code, NSError **error);

NSString *lua_get_name(NSString *filename)
{
	static lua_State *L = NULL;
	if (L == NULL) {
		L = luaL_newstate();
		luaL_openlibs(L);
		lua_openNSValueLibs(L);
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

NSArray *lua_get_arguments(NSString *filename)
{
	static lua_State *L = NULL;
	if (L == NULL) {
		L = luaL_newstate();
		luaL_openlibs(L);
		lua_openNSValueLibs(L);
	}
	if (luaL_loadfile(L, [filename UTF8String]) == LUA_OK) {
		if (lua_pcall(L, 0, 1, 0) == LUA_OK && lua_type(L, -1) == LUA_TTABLE) {
			NSArray *args_array = nil;
				lua_getfield(L, -1, "arguments");
					if (lua_type(L, -1) == LUA_TTABLE) {
						args_array = lua_toNSArray(L, -1);
					}
				lua_pop(L, 1);
			lua_pop(L, 1);
			return args_array;
		}
	}
	return nil;
}

id lua_generator(NSString *filename, NSArray *arguments, NSError **error)
{
	static lua_State *L = NULL;
	if (L == NULL) {
		L = luaL_newstate();
		luaL_openlibs(L);
		lua_openNSValueLibs(L);
	}
    int result = LUA_OK;
    result = luaL_loadfile(L, [filename UTF8String]);
	if (checkCode(L, result, error)) {
        result = lua_pcall(L, 0, 1, 0);
		if (checkCode(L, result, error) && lua_type(L, -1) == LUA_TTABLE) {
			lua_getfield(L, -1, "generator");
			if (lua_type(L, -1) == LUA_TFUNCTION) {
				id snippet_body = nil;
				for (int i = 0; i < [arguments count]; ++i) {
					lua_pushNSValue(L, [arguments objectAtIndex:i]);
				}
				result = lua_pcall(L, (int)[arguments count], 1, 0);
				if (checkCode(L, result, error)) {
					snippet_body = lua_toNSValue(L, -1);
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
		NSString *name = lua_get_name(self.path);
		if (!name) {
			name = [self.path lastPathComponent];
		}
		_name = name;
	}
	return _name;
}

- (NSArray <NSDictionary *> *)flags {
	if (!_flags) {
		_flags = lua_get_arguments(self.path);
	}
	return _flags;
}

- (id)generateWithError:(NSError **)error {
	return lua_generator(self.path, [self.results copy], error);
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

- (void)dealloc {
//#ifdef DEBUG
//    NSLog(@"- [XXTPickerSnippet dealloc]");
//#endif
}

@end
