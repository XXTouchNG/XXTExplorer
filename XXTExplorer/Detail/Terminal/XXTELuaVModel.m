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
        _stdinReadHandler = nil;
        _stdinWriteHandler = nil;
        _stdoutHandler = nil;
        _stderrHandler = nil;
        
        _inputPipe = [NSPipe pipe];
        _outputPipe = [NSPipe pipe];
        _errorPipe = [NSPipe pipe];
        
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
        
        FILE *stdoutHandler = fdopen(self.outputPipe.fileHandleForWriting.fileDescriptor, "w");
        NSAssert(stdoutHandler, @"Cannot create stdout handler");
        setbuf(stdoutHandler, NULL);
        self.stdoutHandler = stdoutHandler;
        
        FILE *stderrHandler = fdopen(self.errorPipe.fileHandleForWriting.fileDescriptor, "w");
        NSAssert(stderrHandler, @"Cannot create stderr handler");
        setbuf(stderrHandler, NULL);
        self.stderrHandler = stderrHandler;
        
        FILE *stdinReadHandler = NULL;
        if ((stdinReadHandler = fdopen(self.inputPipe.fileHandleForReading.fileDescriptor, "r")) != NULL) {
            self.stdinReadHandler = stdinReadHandler;
        }
        
        FILE *stdinWriteHandler = NULL;
        if ((stdinWriteHandler = fdopen(self.inputPipe.fileHandleForWriting.fileDescriptor, "w")) != NULL) {
            self.stdinWriteHandler = stdinWriteHandler;
        }
        
        lua_setStream(self.stdinReadHandler, self.stdoutHandler, self.stderrHandler);
        
    } else {
        
        lua_setStream(nil, nil, nil);
        chdir("/");
        
        if (self.stdoutHandler)
        {
            fclose(self.stdoutHandler);
            self.stdoutHandler = nil;
        }
        if (self.stderrHandler)
        {
            fclose(self.stderrHandler);
            self.stderrHandler = nil;
        }
        if (self.stdinReadHandler)
        {
            fclose(self.stdinReadHandler);
            self.stdinReadHandler = nil;
        }
        if (self.stdinWriteHandler)
        {
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
    if (running != _running) {
        _running = running;
        if (!running)
        {
            char *emptyBuf = (char *)malloc(8192 * sizeof(char)); // malloc
            memset(emptyBuf, 0x0a, 8192);
            [self.inputPipe.fileHandleForWriting writeData:[NSData dataWithBytes:emptyBuf length:8192]];
            free(emptyBuf);
        }
        if (_delegate && [_delegate respondsToSelector:@selector(virtualMachineDidChangedState:)])
        {
            [_delegate virtualMachineDidChangedState:self];
        }
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
    [self setRunning:YES];
    int load_stat = 0;
    if (setjmp(buf) == 0) {
        load_stat = lua_pcall(L, 0, 0, 0);
        [self setRunning:NO];
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
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
