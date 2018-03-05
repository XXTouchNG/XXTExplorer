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
#import "XXTLuaNSValue.h"

static NSString * const XXTETerminalHandlerOutput = @"TerminalOutput-%@.pipe";
static NSString * const XXTETerminalHandlerError = @"TerminalError-%@.pipe";
static NSString * const XXTETerminalHandlerInput = @"TerminalInput-%@.pipe";

static jmp_buf buf;
static BOOL _running = NO;

void lua_terminate(lua_State *L, lua_Debug *ar)
{
    if (!_running) {
        longjmp(buf, 1);
    }
}

@interface XXTELuaVModel ()

@end

@implementation XXTELuaVModel {
    lua_State *L;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    @synchronized (self) {
        if (!L) {
            L = luaL_newstate();
            NSAssert(L, @"LuaVM: not enough memory.");
            
            lua_sethook(L, &lua_terminate, LUA_MASKLINE, 1);
            
            luaL_openlibs(L);
            lua_openNSValueLibs(L);
            lua_setMaxLine(L, LUA_MAX_LINE_C);
        }
    }
}

- (void)setFakeIOEnabled:(BOOL)enabled {
    if (enabled) {
        NSString *stdoutHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:XXTETerminalHandlerOutput, [NSUUID UUID]]];
        unlink(stdoutHandlerPath.UTF8String);
        FILE *stdoutHandler = fopen(stdoutHandlerPath.UTF8String, "wb+");
        NSAssert(stdoutHandler, @"Cannot create stdout handler");
        self.stdoutHandler = stdoutHandler;
        
        NSString *stderrHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:XXTETerminalHandlerError, [NSUUID UUID]]];
        unlink(stderrHandlerPath.UTF8String);
        FILE *stderrHandler = fopen(stderrHandlerPath.UTF8String, "wb+");
        NSAssert(stderrHandler, @"Cannot create stderr handler");
        self.stderrHandler = stderrHandler;
        
        NSString *stdinHandlerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:XXTETerminalHandlerInput, [NSUUID UUID]]];
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
        
        lua_setStream(self.stdinReadHandler, self.stdoutHandler, self.stderrHandler);
    } else {
        lua_setStream(nil, nil, nil);
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
        char *emptyBuf = malloc(8192 * sizeof(char)); // malloc
        memset(emptyBuf, 0x0a, 8192);
        write(fileno(self.stdinWriteHandler), emptyBuf, 8192);
        free(emptyBuf); // free
    }
    if (_delegate && [_delegate respondsToSelector:@selector(virtualMachineDidChangedState:)])
    {
        [_delegate virtualMachineDidChangedState:self];
    }
}

#pragma mark - check code and error

- (void)setCurrentPath:(NSString *)dir {
    if (!dir) return;
    chdir(dir.fileSystemRepresentation);
    NSString *sp = [dir stringByAppendingPathComponent:@"?.lua"];
    NSString *cp = [dir stringByAppendingPathComponent:@"?.so"];
    @synchronized (self) {
        lua_setPath(L, "path", sp.fileSystemRepresentation);
        lua_setPath(L, "cpath", cp.fileSystemRepresentation);
    }
}

#pragma mark - load from file

- (BOOL)loadFileFromPath:(NSString *)path error:(NSError **)error
{
    [self setCurrentPath:[path stringByDeletingLastPathComponent]];
    const char *cString = path.fileSystemRepresentation;
    lua_createArgTable(L, cString);
    int load_stat = luaL_loadfile(L, cString);
    if (!lua_checkCode(L, load_stat, error)) {
        return NO;
    }
    return YES;
}

- (BOOL)loadBufferFromString:(NSString *)string
                       error:(NSError **)error
{
    const char *cString = [string UTF8String];
    int load_stat = luaL_loadbufferx(L, cString, strlen(cString), "", 0);
    if (!lua_checkCode(L, load_stat, error)) {
        return NO;
    }
    return YES;
}

#pragma mark - pcall

- (BOOL)pcallWithError:(NSError **)error {
    self.running = YES;
    int load_stat = 0;
    if (!setjmp(buf)) {
        load_stat = lua_pcall(L, 0, 0, 0);
        self.running = NO;
        if (!lua_checkCode(L, load_stat, error)) {
            return NO;
        }
        return YES;
    } else {
        if (error != nil) {
            *error = [NSError errorWithDomain:kXXTELuaVModelErrorDomain code:-1 userInfo:@{ NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Thread terminated.", nil) }];
        }
        return NO;
    }
}

#pragma mark - memory

- (void)dealloc {
    if (L) {
        lua_close(L);
        L = NULL;
    }
#ifdef DEBUG
    NSLog(@"- [XXTELuaVModel dealloc]");
#endif
}

@end
