//
//  XXTELuaVModel.m
//  XXTouchApp
//
//  Created by Zheng on 31/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <setjmp.h>

#import "XXTELuaVModel.h"
#import "XXTEAppDelegate.h"

static NSString * const kXXTerminalFakeHandlerStandardOutput = @"kXXTerminalFakeHandlerStandardOutput-%@.pipe";
static NSString * const kXXTerminalFakeHandlerStandardError = @"kXXTerminalFakeHandlerStandardError-%@.pipe";
static NSString * const kXXTerminalFakeHandlerStandardInput = @"kXXTerminalFakeHandlerStandardInput-%@.pipe";

static jmp_buf buf;
static BOOL _running = NO;

void luaL_setPath(lua_State* L, const char *key, const char *path)
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

void luaL_terminate(lua_State *L, lua_Debug *ar)
{
    if (!_running) {
        longjmp(buf, 1);
    }
}

@interface XXTELuaVModel ()

@end

@implementation XXTELuaVModel {
    lua_State *luaState;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    @synchronized (self) {
        NSString *stdoutHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:kXXTerminalFakeHandlerStandardOutput, [NSUUID UUID]]];
        unlink(stdoutHandlerPath.UTF8String);
        FILE *stdoutHandler = fopen(stdoutHandlerPath.UTF8String, "wb+");
        NSAssert(stdoutHandler, @"Cannot create stdout handler");
        self.stdoutHandler = stdoutHandler;
        
        NSString *stderrHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:kXXTerminalFakeHandlerStandardError, [NSUUID UUID]]];
        unlink(stderrHandlerPath.UTF8String);
        FILE *stderrHandler = fopen(stderrHandlerPath.UTF8String, "wb+");
        NSAssert(stderrHandler, @"Cannot create stderr handler");
        self.stderrHandler = stderrHandler;
        
        NSString *stdinHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:kXXTerminalFakeHandlerStandardInput, [NSUUID UUID]]];
        unlink(stdinHandlerPath.UTF8String);
        if (mkfifo(stdinHandlerPath.UTF8String, S_IRWXU) >= 0)
        {
            self.stdinReadHandler = stdin;
            FILE *stdinReadHandler = NULL;
            if ((stdinReadHandler = fopen(stdinHandlerPath.UTF8String, "rb+")) != NULL) {
                self.stdinReadHandler = stdinReadHandler;
            }
            
            self.stdinWriteHandler = stdin;
            FILE *stdinWriteHandler = NULL;
            if ((stdinWriteHandler = fopen(stdinHandlerPath.UTF8String, "wb+")) != NULL) {
                self.stdinWriteHandler = stdinWriteHandler;
            }
        }
        
        fakeio(self.stdinReadHandler, self.stdoutHandler, self.stderrHandler);
        
        if (!luaState) {
            luaState = luaL_newstate();
            NSAssert(luaState, @"not enough memory");
            lua_sethook(luaState, &luaL_terminate, LUA_MASKLINE, 1);
            luaL_openlibs(luaState);
        }
    }
}

#pragma mark - Setters

- (BOOL)running {
    return _running;
}

- (void)setRunning:(BOOL)running {
    _running = running;
    if (!running)
    {
        char *emptyBuf = malloc(8192 * sizeof(char));
        memset(emptyBuf, 0x0a, 8192);
        write(fileno(self.stdinWriteHandler), emptyBuf, 8192);
        free(emptyBuf);
    }
    if (_delegate && [_delegate respondsToSelector:@selector(virtualMachineDidChangedState:)])
    {
        [_delegate virtualMachineDidChangedState:self];
    }
}

#pragma mark - check code and error

- (void)setCurrentPath:(NSString *)dirPath {
    chdir([dirPath UTF8String]);
    NSString *sPath = [NSString stringWithFormat:@"%@", [dirPath stringByAppendingPathComponent:@"?.lua"]];
    NSString *cPath = [NSString stringWithFormat:@"%@", [dirPath stringByAppendingPathComponent:@"?.so"]];
    @synchronized (self) {
        luaL_setPath(luaState, "path", sPath.UTF8String);
        luaL_setPath(luaState, "cpath", cPath.UTF8String);
    }
}

#pragma mark - load from file

- (BOOL)loadFileFromPath:(NSString *)path error:(NSError **)error
{
    [self setCurrentPath:[path stringByDeletingLastPathComponent]];
    const char *cString = [path UTF8String];
    int load_stat = luaL_loadfile(luaState, cString);
    return checkCode(luaState, load_stat, error);
}

- (BOOL)loadBufferFromString:(NSString *)string
                       error:(NSError **)error
{
    const char *cString = [string UTF8String];
    int load_stat = luaL_loadbufferx(luaState, cString, strlen(cString), "", 0);
    return checkCode(luaState, load_stat, error);
}

#pragma mark - pcall

- (BOOL)pcallWithError:(NSError **)error {
    self.running = YES;
    int load_stat = 0;
    if (!setjmp(buf)) {
        load_stat = lua_pcall(luaState, 0, 0, 0);
        self.running = NO;
        BOOL loadResult = checkCode(luaState, load_stat, error);
        if (loadResult) {
            
        }
        return loadResult;
    } else {
        if (error != nil) {
            *error = [NSError errorWithDomain:kXXTELuaVModelErrorDomain code:-1 userInfo:@{ NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Thread terminated.", nil) }];
        }
        return NO;
    }
}

#pragma mark - memory

- (void)dealloc {
    if (luaState) {
        lua_close(luaState);
        luaState = NULL;
    }
    
    fakeio(stdin, stdout, stderr);
    chdir("/");
    
    if (self.stdoutHandler) {
        fclose(self.stdoutHandler);
        self.stdoutHandler = nil;
    }
    if (self.stderrHandler) {
        fclose(self.stderrHandler);
        self.stderrHandler = nil;
    }
    if (self.stdinReadHandler) {
        fclose(self.stdinReadHandler);
        self.stdinReadHandler = nil;
    }
    if (self.stdinWriteHandler) {
        fclose(self.stdinWriteHandler);
        self.stdinWriteHandler = nil;
    }
    
#ifdef DEBUG
    NSLog(@"- [XXTELuaVModel dealloc]");
#endif
}

@end
